local Path = require "plenary.path"
local utils = {}
local random = math.random

function utils.get_display_string(task)
  return task.priority .. " " .. task.title or task.description or "(no title, no description)"
end

function utils.to_ordinal(task)
  local display_string = utils.get_display_string(task)
  return "--priority: "
    .. task.priority
    .. " --due: "
    .. task.due
    .. " "
    .. display_string
    .. " "
    .. task.description
    .. " "
    .. task.id
end

function utils.get_due_date_from_ordinal(ordinal)
  local date = string.match(ordinal, "--due:%s([%w%-]+)")
  if date == nil then
    return nil
  end
  local year = tonumber(date:sub(1, 4)) or nil
  local month = tonumber(date:sub(6, 7)) or nil
  local day = tonumber(date:sub(9, 10)) or nil
  if year == nil or month == nil or day == nil then
    return date
  end
  return os.time {
    year = year,
    month = month,
    day = day,
  }
end

function utils.get_priority_from_ordinal(ordinal)
  return tonumber(ordinal:match "--priority:%s(%d+)") or 4
end

function utils.calculate_time_difference(target_date, from_date)
  if type(target_date) == "string" then
    --TODO: Dynamically calculate the differences based on supported Todoist strings
    return {
      days = 100,
      hours = 0,
      minutes = 0,
      total_seconds = 0,
    }
  end
  -- Calculate the difference in seconds
  local difference_in_seconds = target_date - from_date

  -- Convert the difference to days, hours, and minutes
  local days = math.floor(difference_in_seconds / (24 * 60 * 60))
  local hours = math.floor((difference_in_seconds % (24 * 60 * 60)) / (60 * 60))
  local minutes = math.floor((difference_in_seconds % (60 * 60)) / 60)

  return {
    days = days,
    hours = hours,
    minutes = minutes,
    total_seconds = difference_in_seconds,
  }
end

function utils.split_by_newline(str)
  local result = {}
  for line in str:gmatch "([^\n]*)\n?" do
    table.insert(result, line)
  end
  return result
end

function utils.uuid()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
    return string.format("%x", v)
  end)
end

function utils.get_buf_by_pattern(pattern)
  local open_buffers = vim.api.nvim_list_bufs()
  local buf = nil
  for _, buf_nr in ipairs(open_buffers) do
    if vim.api.nvim_buf_is_loaded(buf_nr) then
      local buf_name = vim.api.nvim_buf_get_name(buf_nr)
      if string.find(buf_name, pattern) then
        buf = buf_nr
        break
      end
    end
  end
  return buf
end

function utils.line_number_of(buf, pattern)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for line_number, line in ipairs(lines) do
    if string.find(line, pattern) then
      return line_number
    end
  end
  return nil
end

function utils.replace_line(buf, line_number, new_line)
  if line_number == nil then
    line_number = -1
  end
  vim.api.nvim_buf_call(buf, function()
    if line_number > 0 then
      vim.api.nvim_win_set_cursor(0, { line_number, 0 })
      vim.api.nvim_del_current_line()
      if line_number > 1 then
        vim.api.nvim_win_set_cursor(0, { line_number - 1, 0 })
      end
    end
    vim.api.nvim_put({ new_line }, "l", true, false)
  end)
end

function utils.get_or_create_tasko_directory()
  -- `~/.local/share/nvim` on unix
  local data_dir = vim.fn.stdpath "data"
  if type(data_dir) == "table" then
    data_dir = data_dir[1]
  end
  local tasko_dir = vim.fs.joinpath(data_dir, "tasko.nvim")
  local tasko_dir_path = Path:new(tasko_dir)
  if not tasko_dir_path:exists() then
    tasko_dir_path:mkdir()
  end
  return tasko_dir
end

return utils
