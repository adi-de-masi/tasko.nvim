local Store = require('tasko').Store
local utils = require('tasko').Utils

vim.api.nvim_create_user_command("TaskoList", function()
  local buf = Store:get_task_list_file()
  local task_list = Store:list_tasks()
  for _, task_file in ipairs(task_list) do
    local task = Store:read(task_file)
    local escaped_task_id = string.gsub(task.id, "%-", "%%-")
    local line_number_in_task_list = utils.line_number_of(buf, escaped_task_id)
    utils.replace_line(buf, line_number_in_task_list, task.to_task_list_line())
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
