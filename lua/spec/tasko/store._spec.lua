local Store = require "tasko.store"
local Path = require "plenary.path"
local Task = require "tasko.task"

describe("Store", function()
  local function delete_test_file(file)
    Path:new(file):rm()
  end

  it("Write returns the filename", function()
    local file = Store:write(Task:new(1, "title", "my description", 4, false))
    assert(file, "no filename returned")
    assert(string.find(file, "/tasko.nvim/1%.md$") ~= nil, "wrong filename returned: " .. file)
    delete_test_file(file)
  end)

  it("Considers description updates", function()
    local task = Task:new(1, "title", "my description", 4, "2025-01-03", false)
    local file = Store:write(task)
    task.description = "new description"
    Store:write(task)
    local loaded_task = Store:get_task_from_path(file)
    assert(loaded_task.description == "\nnew description\n", "description! " .. vim.inspect(loaded_task))
    delete_test_file(file)
  end)

  it("loads a task from path", function()
    local task = Task:new(1, "title", "my description", 4, "2025-01-03", false)
    local file = Store:write(task)
    local loaded_task = Store:get_task_from_path(file)
    assert(loaded_task ~= nil, "didn't load the task")
    assert(loaded_task.id == "1", "id could not be read")
    assert(loaded_task.title == "title", "title could not be read: " .. loaded_task.title)
    assert(loaded_task.description == "\nmy description\n", "description! " .. vim.inspect(loaded_task))
    assert(loaded_task.priority == "4", "priority could not be read")
    assert(loaded_task.due == "2025-01-03", "due date could not be read")
    assert(loaded_task.is_completed == "false", "is_completed could not be read")
    delete_test_file(file)
  end)
end)
