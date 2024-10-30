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

M.TaskoStore = {}
function M.TaskoStore:write()
  local title = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
  local body = vim.api.nvim_buf_get_lines(0, 2, -1, false)
  local task = M.Task:new(title, body)

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
  local target_file = vim.fs.joinpath(tasko_dir, task.id .. ".md")
  Path:new(target_file):write(task:__to_string(), "w")
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
