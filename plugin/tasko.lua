local Store = require('tasko.store')
local Task = require('tasko.task')
local utils = require('tasko.utils')
local Todoist = require('todoist')

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

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

vim.api.nvim_create_user_command("TaskoFetchTasks", function()
  local job = T:query_all("tasks", function(out)
    local T = Todoist:new()
    if out.status == 200 then
      local res_json = vim.json.decode(out.body)
      for _, t in pairs(res_json) do
        local title = t.content
        local body = t.description
        local id = t.id
        local task = Task:new(id, title, body)
        Store:write_task_to_tasko_base_dir(task)
      end
    else
      print("gopferdeli")
    end
  end)
  job:wait(15000)
end, {})
