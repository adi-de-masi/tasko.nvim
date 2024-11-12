local Todoist = require('todoist')
local Task = require('tasko.task')
local curl = require("plenary.curl")

describe('todoist api', function()
  it('plenary.curl basic learning test', function()
    local query2 = { name = "john Doe", key = "123456" }
    local res = curl.get("https://postman-echo.com/get", {
      query = query2,
    })
    assert(res.status == 200, "gopferdeli")
  end)

  it('lists all tasks', function()
    local T = Todoist:new()
    local tasks = T:query_all('tasks')
    for key, value in ipairs(tasks) do
      local task = Task:new(value["id"], value["content"], value["description"])
      tasks[key] = task
    end
    assert.is_string(tasks[1].title,
      'The first task has no title. This could mean, Adi has no tasks currently or we have an issue')
  end)
end)
