local Task = require "tasko.task"
local utils = require "tasko.utils"

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
      .. '-- due: "2025-01-03"\n'
      .. "-- is_completed: true\n"
      .. "-- edited_time: 2025-01-03T23:00:00\n"
    local task = Task:from_lines(task_lines)
    assert(task.id == "1", "wrong id: " .. task.id)
    assert(task.provider_id == "123", "wrong provider_id")
    assert(task.title == "title for this test", "wrong title")
    assert(task.description:gsub("\n", "") == "A task description example", "wrong description: " .. task.description)
    assert(task.priority == "3", "wrong priority")
    assert(task.due == "2025-01-03", "due not found")
    assert(task.is_completed == "true", "wrong is_completed")
    assert(
      task.edited_time == "2025-01-03T23:00:00",
      "edited wrong: " .. (task.edited_time and task.edited_time or "nil")
    )
  end)

  it("parses the due date", function()
    local task_lines = "# title for this test\n"
      .. "\n"
      .. "A task description example\n"
      .. "---------------------\n"
      .. "-- id: 1\n"
      .. "-- provider_id: 123\n"
      .. "-- priority: 3\n"
      .. '-- due: "2025-01-03"\n'
      .. "-- is_completed: true\n"

    local delimiter_regex = '--%s*(%w+):%s*"?([%w%-]+)"?'
    local result = nil
    for _, line in ipairs(utils.split_by_newline(task_lines)) do
      local key, value = string.match(line, delimiter_regex)
      if key and value then
        if key == "due" then
          result = value
        end
      end
    end
    assert(result == "2025-01-03", "did't parse the due date from task_lines")
  end)

  it("reads the ordinal due date", function()
    local wawa = string.match("--priority: 4 --due: 2025-01-03 jsdflwkejfwe", "--due:%s([%w%-]+)")
    assert(wawa == "2025-01-03", "due date from ordinal")
  end)
end)
