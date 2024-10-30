local utils = {}
local random = math.random

function utils.uuid()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function(c)
    local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
    return string.format('%x', v)
  end)
end

function utils.dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. utils.dump(v) .. ','
    end
    return s .. '} '
  elseif type(o) == 'string' then
    return ("%q"):format(o)
  else
    return tostring(o)
  end
end

return utils
