local Store = require('tasko').Store
local Path = require('plenary.path')

vim.api.nvim_create_user_command("TaskoList", function()
  local open_buffers = vim.api.nvim_list_bufs();
  local buf
  for _, buf_nr in ipairs(open_buffers) do
    if (vim.api.nvim_buf_is_loaded(buf_nr)) then
      local buf_name = vim.api.nvim_buf_get_name(buf_nr);
      if (string.find(buf_name, ".*%*tasks%*.*")) then
        buf = buf_nr
        break
      end
    end
  end
  if (not buf) then
    buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, "*tasks*")
    vim.api.nvim_set_option_value("filetype", "md", { buf = buf })
  end
  local task_files = require('tasko').Store:read_all()
  local base_dir = Store:get_or_create_tasko_directory()
  for _, task_file in ipairs(task_files) do
    local temp_buf = Path:new(vim.fs.joinpath(base_dir, task_file)):read()
    local task = require('tasko').Task:from_file(temp_buf)
    local task_line = { '[' .. task.title .. '](' .. base_dir .. '/' .. task.id .. '.md)' }
    vim.api.nvim_buf_call(buf, function()
      vim.api.nvim_put(task_line, 'l', false, false)
    end)
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
  print(new_task_file)
  vim.api.nvim_buf_set_name(buf, new_task_file)
  local template = { '[//]: # (title)', '# Title', '[//]: # (body)', '# Body', '[//]: # (id)', task.id }
  vim.api.nvim_buf_call(buf, function()
    vim.api.nvim_put(template, 'l', false, false)
  end)
  vim.api.nvim_set_current_buf(buf)
  vim.fn.execute('set ft=markdown')
end, {})
