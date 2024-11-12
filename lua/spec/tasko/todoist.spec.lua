local Todoist = require('todoist')
local curl = require("plenary.curl")

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

describe('todoist api', function()
  it('plenary.curl basic learning test', function()
    local query2 = { name = "john Doe", key = "123456" }
    local res = curl.get("https://postman-echo.com/get", {
      query = query2,
    })
    assert(res.status == 200, "gopferdeli")
  end)

  it('lists all tasks', function()
    local token = os.getenv("TODOIST_API_KEY")
    local res = nil
    local done = false
    local job = curl.get("https://api.todoist.com/rest/v2/tasks", {
      query = {},
      headers = {
        ["Authorization "] = "Bearer " .. token,
        ["accept"] = "application/json"
      },
      callback = function(out)
        done = true
        res = out
      end
    })
    job:wait()
    print(dump(res))
  end)
end)
