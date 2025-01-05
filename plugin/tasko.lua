local Store = require "tasko.store"
local utils = require "tasko.utils"
local telescope_sorters = require "telescope.sorters"

local generic_fuzzy_sorter = telescope_sorters.get_generic_fuzzy_sorter()
local custom_sorter = telescope_sorters.Sorter:new {
  scoring_function = function(prompt, ordinal, entry)
    local entry_prio = tonumber(entry:match "^(%d+)") or 4
    local boost = 1
    if prompt ~= nil and type(prompt) == "string" then
      local prompt_prio_raw = string.match(prompt, "^(%d+)") or 0
      local prompt_prio = tonumber(prompt_prio_raw)
      if entry_prio and prompt_prio and entry_prio > prompt_prio then
        boost = 10
      end
    end
    local score = generic_fuzzy_sorter.scoring_function(prompt, ordinal, entry)
    if prompt ~= nil and score < 0 then
      return math.huge
    end
    return score * boost
  end,
}

vim.api.nvim_create_user_command("TaskoList", function()
  local opts = {}

  local files_dir = utils.get_or_create_tasko_directory()
  require("telescope.builtin").find_files {
    cwd = files_dir,
    hidden = opts.hidden or false,
    no_ignore = opts.no_ignore or true,
    sorter = custom_sorter,
    entry_maker = function(task_file)
      local path_to_task = vim.fs.joinpath(files_dir, task_file)
      local task = Store:get_task_from_path(path_to_task)
      if task ~= nil and tostring(task.is_completed) ~= "true" then
        local display_string = task.title or task.description or "(no title, no description)"
        return {
          value = path_to_task,
          display = task.priority .. " " .. display_string,
          ordinal = task.priority .. " " .. display_string .. " " .. task.description .. " " .. task.id,
        }
      end
    end,
  }
end, {})

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
  local filename = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())

  local task = Store:get_task_from_path(filename)
  assert(task ~= nil, filename .. " cannot be interpreted as task")
  local provider = get_provider()
  local config = require("tasko").config
  if (config and config.provider) and (task.provider_id == nil or task.provider_id == "") then
    local updated_task = provider:new_task(task)
    local buf = vim.api.nvim_get_current_buf()
    updated_task.to_buffer(buf)
    vim.cmd "write"
  else
    provider:update(task)
  end
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
    task.to_buffer(buf)
    vim.cmd "write"
  end
end, {})

vim.api.nvim_create_user_command("TaskoFetchAll", function()
  local provider = get_provider()
  local tasks = provider:query_all "tasks"
  for _, value in ipairs(tasks) do
    local task = provider:to_task(value)
    Store:write(task)
  end
end, {})
