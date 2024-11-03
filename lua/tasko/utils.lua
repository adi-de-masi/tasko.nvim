local utils = {}
local random = math.random

function utils.uuid()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function(c)
    local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
    return string.format('%x', v)
  end)
end

function utils.get_buf_by_pattern(pattern)
  local open_buffers = vim.api.nvim_list_bufs();
  local buf = nil
  for _, buf_nr in ipairs(open_buffers) do
    if (vim.api.nvim_buf_is_loaded(buf_nr)) then
      local buf_name = vim.api.nvim_buf_get_name(buf_nr);
      if (string.find(buf_name, pattern)) then
        buf = buf_nr
        break
      end
    end
  end
  return buf
end

function utils.does_buf_contain_pattern(buf, pattern)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for _, line in ipairs(lines) do
    if (string.find(line, pattern)) then
      return true
    end
  end
  return false
end

return utils
