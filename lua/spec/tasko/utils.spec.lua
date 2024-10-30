local Task = require('tasko').Task
describe('text to task', function()
  it('Creates a task', function()
    local task = Task:new("This is my test Task", "This is the body of my test task")
    assert(task.title == "This is my test Task", "Title couldn't be parsed.")
  end)

  it('converts a markdown file to a task', function()
    vim.fn.execute('edit lua/spec/tasko/test_task.md', false) -- loads test file into buffer 1
    local task = Task:from_file()
    assert(task.title == "This is my test Task", "Title couldn't be parsed." .. task.title)
  end)
end)
