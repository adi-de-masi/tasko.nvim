local M = {}
local utils = require '../tasko/utils'
local Path = require 'plenary.path'

M.Task = {}
function M.Task:new(id, title, body)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.id = id or utils.uuid()
  o.title = title or ''
  o.body = body or ''
  return o
end

function M.Task:from_file(buf_or_string)
  local lines;
  if (buf_or_string ~= nil
        and type(buf_or_string == 'string')
        and buf_or_string ~= '') then
    lines = vim.split(buf_or_string, '\n')
  else
    local buffer = buf_or_string or vim.api.nvim_get_current_buf()
    lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  end

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
      if (value ~= ''
            and (current_column == 'title' or current_column == 'id')
            and empty_captures ~= nil) then
        task[current_column] = value
      elseif (current_column ~= 'title' and current_column ~= 'id') then
        task[current_column] = task[current_column] .. value .. '\n'
      end
    end
  end
  return task
end

M.Store = {}

function M.Store:get_or_create_tasko_directory()
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

function M.Store:write()
  local task = M.Task:from_file()
  if (not task) then
    print('nothing written, no task identified')
    return
  end
  local tasko_dir = self:get_or_create_tasko_directory()
  local target_file = vim.fs.joinpath(tasko_dir, task.id .. ".md")
  local content = table.concat(
    vim.api.nvim_buf_get_lines(
      vim.api.nvim_get_current_buf(), 0, -1, false),
    '\n')
  Path:new(target_file):write(content, "w")
  return target_file
end

function M.Store:delete(task_id)
  local base_dir = self:get_or_create_tasko_directory()
  local file_path = vim.fs.joinpath(base_dir, task_id .. ".md")
  return Path:new(file_path):rm()
end

function M.Store:read(file_name)
  local tasko_dir = self:get_or_create_tasko_directory()
  local target_file = vim.fs.joinpath(tasko_dir, file_name)
  local file = Path:new(target_file):read()
  return M.Task:from_file(file)
end

function M.Store:read_all()
  local tasko_dir = self:get_or_create_tasko_directory()
  local result = {}
  local i = 1
  for dir in io.popen("ls -pa " .. tasko_dir .. "  | grep -v /"):lines()
  do
    result[i] = dir
    i = i + 1
  end
  return result
end

return M
