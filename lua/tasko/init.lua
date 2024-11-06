local utils = require '../tasko/utils'
local M = {}
local Path = require 'plenary.path'
local task_list_filename = "*tasks*.md"
local function get_or_create_tasko_directory()
  -- `~/.config/share/nvim` on unix
  local data_dir = vim.fn.stdpath("data")
  if (type(data_dir) == "table") then
    data_dir = data_dir[1]
  end
  local tasko_dir = vim.fs.joinpath(data_dir, "tasko")
  local tasko_dir_path = Path:new(tasko_dir)
  if (not tasko_dir_path:exists()) then
    tasko_dir_path:mkdir()
  end
  return tasko_dir
end
local base_dir = get_or_create_tasko_directory()


M.Task = {}
function M.Task:new(id, title, body)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.id = id or utils.uuid()
  o.title = title or ''
  o.body = body or ''
  o.to_task_list_line = function()
    if (o.done ~= nil) then
      return string.format("DONE: [%s](%s/%s.md)", o.title, base_dir, o.id)
    else
      return string.format("[%s](%s/%s.md)", o.title, base_dir, o.id)
    end
  end
  return o
end

function M.Task:from_current_buffer()
  return M.Task:from_buffer(vim.api.nvim_get_current_buf())
end

function M.Task:from_buffer(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return M.Task:from_lines(lines)
end

function M.Task:from_lines(lines)
  --[[
  Our delimiter is a markdown comment like so
  `[//]: # (title)`
  --]]
  local delimiter_regex = '^%s*(%[//%]: #)%s*%((.*)%)'
  local task = M.Task:new()
  local current_column = nil
  for _, line in ipairs(lines) do
    local _, _, delimiter, column = string.find(line, delimiter_regex)
    if delimiter then
      current_column = column
    elseif (current_column ~= nil) then
      local empty_captures = not string.match(line, '^%s*$')
      local value = string.gsub(line, '^#%s*', '')
      if (current_column == 'body') then
        -- the only place where we accept blank lines
        local existing_body = (task['body'] ~= nil and task['body'] or '')
        task['body'] = existing_body .. value .. "\n"
      elseif (value ~= '' and empty_captures ~= nil) then
        task[current_column] = value
      end
    end
  end
  return task
end

M.Store = {}

function M.Store:get_task_list_file()
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
  return buf
end

function M.Store:write_task()
  local task = M.Task:from_current_buffer()
  if (not task) then
    print('nothing written, no task identified')
    return
  end
  local tasko_dir = get_or_create_tasko_directory()
  local target_file = vim.fs.joinpath(tasko_dir, task.id .. ".md")
  local content = table.concat(
    vim.api.nvim_buf_get_lines(
      vim.api.nvim_get_current_buf(), 0, -1, false),
    '\n')
  Path:new(target_file):write(content, "w")
  return target_file
end

function M.Store:delete(task_id)
  local file_path = vim.fs.joinpath(base_dir, task_id .. ".md")
  return Path:new(file_path):rm()
end

function M.Store:read(file_name)
  local tasko_dir = get_or_create_tasko_directory()
  local target_file = vim.fs.joinpath(tasko_dir, file_name)
  local file_content = Path:new(target_file):read()
  return M.Task:from_lines(vim.split(file_content, "\n"))
end

function M.Store:list_tasks(override_task_list_filename)
  local tasko_dir = get_or_create_tasko_directory()
  local task_list_file_to_exclude
  if (override_task_list_filename) then
    task_list_file_to_exclude = override_task_list_filename
  else
    task_list_file_to_exclude = task_list_filename
  end
  local result = {}
  local i = 1
  for dir in io.popen("ls -pa " .. tasko_dir .. "  | grep -v / | grep -v \"" .. string.gsub(task_list_file_to_exclude, "*", "\\*") .. "\""):lines()
  do
    result[i] = dir
    i = i + 1
  end
  return result
end

M.Utils = utils
return M
