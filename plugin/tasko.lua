local Task = require "tasko.task"
local Store = require "tasko.store"
local utils = require "tasko.utils"
local telescope_sorters = require "telescope.sorters"

local generic_fuzzy_sorter = telescope_sorters.get_generic_fuzzy_sorter()
local custom_sorter = telescope_sorters.Sorter:new {
  scoring_function = function(entry, prompt, ordinal)
    local entry_prio = utils.get_priority_from_ordinal(ordinal)
    local penalty = tonumber(entry_prio)
    local due_date = utils.get_due_date_from_ordinal(ordinal)
    if due_date == nil then
      penalty = penalty + 1
    else
      local today = os.time()
      local difference_in_days = utils.calculate_time_difference(due_date, today).days
      if difference_in_days > 0 then
        penalty = penalty + difference_in_days
      end
    end

    if prompt ~= nil and type(prompt) == "string" then
      local prompt_prio_raw = string.match(prompt, "^(%d+)") or 0
      local prompt_prio = tonumber(prompt_prio_raw)
      if entry_prio and prompt_prio and entry_prio > prompt_prio then
        penalty = penalty + 1
      end
    end

    local score = generic_fuzzy_sorter.scoring_function(entry, prompt, ordinal)

    if prompt ~= nil and score < 0 then
      return math.huge
    end
    return score * 100 + penalty
  end,
}

local default_entry_maker = function(task_file)
  local files_dir = utils.get_or_create_tasko_directory()
  local path_to_task = vim.fs.joinpath(files_dir, task_file)
  local task = Store:get_task_from_path(path_to_task)
  if task ~= nil and tostring(task.is_completed) ~= "true" then
    local display_string = utils.get_display_string(task)
    local ordinal = utils.to_ordinal(task)
    return {
      value = path_to_task,
      display = display_string,
      ordinal = ordinal,
    }
  end
end

local today_entry_maker = function(task_file)
  local files_dir = utils.get_or_create_tasko_directory()
  local path_to_task = vim.fs.joinpath(files_dir, task_file)
  local task = Store:get_task_from_path(path_to_task)
  local today = utils.get_today()
  if task ~= nil and task.is_completed ~= "true" and task.due ~= "" and task.due <= today then
    local display_string = utils.get_display_string(task)
    local ordinal = utils.to_ordinal(task)
    return {
      value = path_to_task,
      display = display_string,
      ordinal = ordinal,
    }
  end
end

vim.api.nvim_create_user_command("TaskoList", function(opts)
  local entry_maker = default_entry_maker
  if (opts.args == "today") then
    entry_maker = today_entry_maker
  end

  local files_dir = utils.get_or_create_tasko_directory()
  require("telescope.builtin").find_files {
    cwd = files_dir,
    hidden = opts.hidden or false,
    no_ignore = opts.no_ignore or true,
    sorter = custom_sorter,
    entry_maker = entry_maker }
end, {
  nargs = "?", --0 or 1 arguments are allowed
})

local function get_provider()
  local config = require("tasko").config
  if config and config.provider then
    local provider = require("tasko.providers." .. config.provider)
    if provider ~= nil then
      return provider
    end
    print("Provider not found: " .. config.provider)
  end
  return require "tasko.providers.default"
end

vim.api.nvim_create_user_command("TaskoPush", function()
  local current_buffer = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(current_buffer)
  local task = Task:from_current_buffer()
  task.edited_time = os.date "!%Y-%m-%dT%H:%M:%SZ"

  assert(task ~= nil, filename .. " cannot be interpreted as task")
  local provider = get_provider()
  local config = require("tasko").config
  local updated_task = nil
  if (config and config.provider) and (task.provider_id == nil or task.provider_id == "") then
    updated_task = provider:new_task(task)
  else
    updated_task = provider:update(task)
  end
  updated_task.updated_time = os.date "!%Y-%m-%dT%H:%M:%SZ"
  updated_task.to_buffer(current_buffer)
  vim.cmd "write"
  print("Pushed task to provider: " .. updated_task.title .. " with id: " .. updated_task.provider_id)
end, {})

vim.api.nvim_create_user_command("TaskoFetch", function()
  local filename = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())

  local task = Store:get_task_from_path(filename)
  assert(task ~= nil, filename .. " cannot be interpreted as task")
  local config = require("tasko").config
  local provider = get_provider()
  if task.provider_id ~= nil and config and config.provider then
    local updated_task = provider:get_task_by_id(task.provider_id)
    local buf = vim.api.nvim_get_current_buf()
    updated_task.to_buffer(buf)
    vim.cmd "write"
    print "updated task from provider"
  end
end, {})

vim.api.nvim_create_user_command("TaskoSyncAll", function()
  -- Get all tasks
  local provider = get_provider()
  local active_tasks_from_provider = provider:query_all_tasks()
  local local_tasks = Store:all_local_tasks_table()
  local fetched = 0
  local updated = 0
  local created = 0

  for _, task_from_provider in ipairs(active_tasks_from_provider) do
    local local_task = local_tasks[task_from_provider.provider_id]
    if local_task == nil then
      Store:write(task_from_provider)
      fetched = fetched + 1
    elseif local_task.edited_time == nil then
      Store:write(task_from_provider)
      fetched = fetched + 1
      table.remove(local_tasks, local_task.provider_id)
    elseif local_task.edited_time ~= nil then
      provider:update(task_from_provider)
      local_task.updated_time = os.date "!%Y-%m-%dT%H:%M:%SZ"
      local_task.edited_time = nil
      local_task.provider_id = task_from_provider.provider_id
      Store:write(local_task)
      updated = updated + 1
      table.remove(local_tasks, local_task.provider_id)
    end
  end

  for _, local_task in pairs(local_tasks) do
    if local_task.provider_id == nil then
      local new_task = provider:new_task(local_task)
      Store:write(new_task)
      Store:delete(local_task.id)
      created = created + 1
    else
      local updated_task = provider:get_task_by_id(local_task.provider_id)
      Store:write(updated_task)
      fetched = fetched + 1
    end
  end

  print("Fetched " .. fetched .. ", created " .. created .. " and updated " .. updated .. " tasks")
end, {})

vim.api.nvim_create_user_command("TaskoNew", function()
  vim.ui.input({ prompt = "Task Title: " }, function(input)
    local task = Task:new()
    task.title = input
    local file = Store:write(task)
    vim.cmd("edit " .. file)
    local buf = vim.api.nvim_get_current_buf()
    task.to_buffer(buf)
  end)
end, {})

vim.api.nvim_create_user_command("TaskoDone", function()
  local task = Task:from_current_buffer()
  if task ~= nil then
    local provider = get_provider()
    provider:complete(task.provider_id)
    task.is_completed = true
    local buf = vim.api.nvim_get_current_buf()
    task.updated_time = os.date "!%Y-%m-%dT%H:%M:%SZ"
    task.to_buffer(buf)
    vim.cmd "write"
  end
end, {})

vim.api.nvim_create_user_command("TaskoReopen", function()
  local task = Task:from_current_buffer()
  if task ~= nil then
    local provider = get_provider()
    provider:reopen(task.provider_id)
    task.is_completed = false
    local buf = vim.api.nvim_get_current_buf()
    task.updated_time = os.date "!%Y-%m-%dT%H:%M:%SZ"
    task.to_buffer(buf)
    vim.cmd "write"
  else
    print "Task is not completed"
  end
end, {})

vim.api.nvim_create_user_command("TaskoFetchAll", function()
  local provider = get_provider()
  local tasks = provider:query_all_tasks()
  print("Fetched " .. #tasks .. " tasks")
  for _, task in ipairs(tasks) do
    Store:write(task)
  end
end, {})
