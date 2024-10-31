local M = {}
local utils = require '../tasko/utils'
local Path = require 'plenary.path'

M.Task = {}
function M.Task:new(title, body)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.id = utils.uuid()
  o.title = title
  o.body = body
  o.__to_string = function()
    return utils.dump(o)
  end
  return o
end

function M.Task:from_file()
  --[[
    Our delimiter is a markdown comment like so
    `[//]: # (title)`
    --]]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local delimiter_regex = '^%s*(%[//%]: #)%s*%((.*)%)'
  local task = M.Task:new()
  local readingBody = false
  for i, line in ipairs(lines) do
    local _, _, delimiter, column = string.find(line, delimiter_regex)
    if delimiter then
      if (column == 'title') then
        local title = lines[i + 1]
        if (title == nil or title == '') then
          print('Title cannot be empty')
          return
        else
          task.title = string.gsub(title, '^#%s*', '')
        end
      elseif (column == 'body') then
        readingBody = true
        task.body = ''
      end
      -- print('field: ' .. column)
    end
    if readingBody then
      task.body = task.body .. line .. '\n'
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
  Path:new(target_file):write(task:__to_string(), "w")
  return target_file
end

function M.setup(opts)
  opts = opts or {}

  -- TODO: Remove thish
  vim.keymap.set("n", "<Leader>T", function()
    if opts.name then
      print("hello, " .. opts.name)
    else
      print("hello")
    end
  end)
end

return M
