local Store = require('tasko').Store
local Path = require('plenary.path')
local base_dir = Store:get_or_create_tasko_directory()
local task_list_filename = "*tasks*.md"
local utils = require('tasko').Utils

vim.api.nvim_create_user_command("TaskoList", function()
  -- Task List is already open
  local buf = utils.get_buf_by_pattern("%*tasks%*.md")
  if (not buf) then
    -- Task List is stored in a file
    local task_list_file = Path:new(
      vim.fs.joinpath(base_dir, task_list_filename))
    if (task_list_file:exists()) then
      -- try to load from file
      vim.fn.execute(string.format('edit %s', task_list_file:absolute()))
      buf = vim.api.nvim_get_current_buf()
    else
      -- We create a new Task List
      buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(buf, task_list_file:absolute())
      vim.api.nvim_set_option_value("ft", "md", { buf = buf })
    end
  end

  local task_list = require('tasko').Store:list_tasks(task_list_filename)
  for _, task_file in ipairs(task_list) do
    local task_lines = Path:new(vim.fs.joinpath(base_dir, task_file)):read()
    local task = require('tasko').Task:from_lines(task_lines)
    local escaped_task_id = string.gsub(task.id, "%-", "%%-")
    local line_number_in_task_list = utils.line_number_of(buf, escaped_task_id)
    local task_line = task.to_task_list_line()
    if (line_number_in_task_list ~= nil) then
      utils.replace_line(buf, line_number_in_task_list, task_line)
    else
      utils.replace_line(buf, -1, task_line)
    end
  end
  vim.api.nvim_set_current_buf(buf)
  vim.fn.execute('set ft=markdown')
  return buf
end, {})

vim.api.nvim_create_user_command("TaskoNew", function()
  local buf = vim.api.nvim_create_buf(true, false)
  local task = require('tasko').Task:new()
  local tasko_dir = require('tasko').Store:get_or_create_tasko_directory()
  local new_task_file = vim.fs.joinpath(tasko_dir, task.id .. '.md');
  vim.api.nvim_buf_set_name(buf, new_task_file)
  local template = { '[//]: # (title)', '# Title', '[//]: # (body)', '# Body', '[//]: # (id)', task.id }
  vim.api.nvim_buf_call(buf, function()
    vim.api.nvim_put(template, 'l', false, false)
  end)
  vim.api.nvim_set_current_buf(buf)
  vim.fn.execute('set ft=markdown')
end, {})


vim.api.nvim_create_user_command("TaskoDone", function()
  local current_buf = vim.api.nvim_get_current_buf()
  local now = os.date("!%Y-%m-%dT%TZ")
  if (type(now) == "string") then
    print('now is ' .. now)
    vim.api.nvim_buf_call(current_buf, function()
      vim.api.nvim_buf_set_lines(current_buf, -1, -1, true, { '[//]: # (done)', now })
    end)
  end
end, {})
