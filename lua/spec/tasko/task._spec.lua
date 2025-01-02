local Task = require "tasko.task"

describe("text to task", function()
  it("Creates a task", function()
    local task = Task:new(nil, "This is my test Task", "This is the body of my test task")
    assert(task.title == "This is my test Task", "Title couldn't be parsed.")
    assert.is_not_nil(task.id)
  end)

  it("creates a task from lines", function()
    local task_lines = "# title for this test\n"
      .. "\n"
      .. "A task description example\n"
      .. "---------------------\n"
      .. "-- id: 1\n"
      .. "-- provider_id: 123\n"
      .. "-- priority: 3\n"
      .. "-- is_completed: true\n"
    local task = Task:from_lines(task_lines)
    assert(task.id == "1", "wrong id: " .. task.id)
    assert(task.provider_id == "123", "wrong provider_id")
    assert(task.title == "title for this test", "wrong title")
    assert(task.description:gsub("\n", "") == "A task description example", "wrong description: " .. task.description)
    assert(task.priority == "3", "wrong priority")
    assert(task.is_completed == "true", "wrong is_completed")
  end)
end)
