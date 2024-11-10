local Store = require('tasko.store')
local Task = require('tasko.task')
local utils = require('tasko.utils')

vim.api.nvim_create_user_command("TaskoList", function()
  local buf = Store:get_task_list_file()
  local task_list = Store:list_tasks()
  for _, task_file in ipairs(task_list) do
    local task = Store:get_task_from_file(task_file)
    local escaped_task_id = string.gsub(task.id, "%-", "%%-")
    local line_number_in_task_list = utils.line_number_of(buf, escaped_task_id)
    utils.replace_line(buf, line_number_in_task_list, task.to_task_list_line())
  end
  vim.api.nvim_set_current_buf(buf)
  vim.fn.execute('set ft=markdown')
  return buf
end, {})

vim.api.nvim_create_user_command("TaskoNew", function()
  local task = Task:new()
  local buf = task:to_buffer()
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
