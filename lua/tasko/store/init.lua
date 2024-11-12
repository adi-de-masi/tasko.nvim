local Path = require('plenary.path')
local Task = require('tasko.task')
local utils = require('tasko.utils')
local tasko_base_dir = utils.get_or_create_tasko_directory()
local Store = {}
Store.TASK_LIST_FILENAME = "*tasks*.md"

function Store:get_task_list_file()
  -- Task List is already open
  local buf = utils.get_buf_by_pattern("%*tasks%*.md")
  if (not buf) then
    -- Task List is stored in a file
    local task_list_file = Path:new(
      vim.fs.joinpath(tasko_base_dir, Store.TASK_LIST_FILENAME))
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
  return buf
end

function Store:write_task_to_tasko_base_dir(task)
  local buf = task:to_buffer()
  local target_file = vim.fs.joinpath(tasko_base_dir, task.id .. ".md")
  local content = table.concat(
    vim.api.nvim_buf_get_lines(
      buf, 0, -1, false),
    '\n')
  Path:new(target_file):write(content, "w")
end

function Store:write_buffer_to_tasko_base_dir()
  local task = Task:from_current_buffer()
  if (not task) then
    print('nothing written, no task identified')
    return
  end
  local target_file = vim.fs.joinpath(tasko_base_dir, task.id .. ".md")
  local content = table.concat(
    vim.api.nvim_buf_get_lines(
      vim.api.nvim_get_current_buf(), 0, -1, false),
    '\n')
  Path:new(target_file):write(content, "w")
  return target_file
end

function Store:delete(task_id)
  local file_path = vim.fs.joinpath(tasko_base_dir, task_id .. ".md")
  return Path:new(file_path):rm()
end

function Store:get_task_from_file(file_name)
  local target_file = vim.fs.joinpath(tasko_base_dir, file_name)
  local file_content = Path:new(target_file):read()
  return Task:from_lines(vim.split(file_content, "\n"))
end

function Store:list_tasks(override_task_list_filename)
  local task_list_file_to_exclude
  if (override_task_list_filename) then
    task_list_file_to_exclude = override_task_list_filename
  else
    task_list_file_to_exclude = Store.TASK_LIST_FILENAME
  end
  local result = {}
  local i = 1
  for dir in io.popen("ls -pa " .. tasko_base_dir .. "  | grep -v / | grep -v \"" .. string.gsub(task_list_file_to_exclude, "*", "\\*") .. "\""):lines()
  do
    result[i] = dir
    i = i + 1
  end
  return result
end

return Store
