local Task = require('tasko.task')

describe('text to task', function()
  it('Creates a task', function()
    local task = Task:new(nil, "This is my test Task", "This is the body of my test task")
    assert(task.title == "This is my test Task", "Title couldn't be parsed.")
    assert.is_not_nil(task.id)
  end)

  it('converts an open markdown file to a task', function()
    -- loads test file into buffer 1
    vim.fn.execute('edit lua/spec/tasko/test_task.md', false)
    local task = Task:from_current_buffer()
    local expected_title = "This is my test Task"

    assert(task.title == expected_title, "Title couldn't be parsed. '" .. task.title .. "'")
    local expected_body = [[


It has a simple body.
That even may consist of multiple lines.

As many as you wish, actually.

]]
    assert(task.body == expected_body, "Body couldn't be parsed.")
    assert(task.id == '12345', "Id couldn't be parsed.")
  end)

  it('converts a markdown file with the done comment to a task', function()
    vim.fn.execute('edit lua/spec/tasko/test_done_task.md', false)
    local task = Task:from_current_buffer()
    assert(task.done ~= nil, "Task not marked as done")
  end)
end)
