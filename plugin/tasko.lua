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
    local task_file_content = Path:new(vim.fs.joinpath(base_dir, task_file)):read()
    local task = require('tasko').Task:from_file(task_file_content)
    local escaped_task_id = string.gsub(task.id, "%-", "%%-")
    if (not utils.does_buf_contain_pattern(buf, escaped_task_id)) then
      local task_line = string.format("[%s](%s/%s.md)", task.title, base_dir, task.id)
      vim.api.nvim_buf_call(buf, function()
        vim.api.nvim_put({ task_line }, 'l', false, false)
      end)
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
