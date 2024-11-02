local Path = require 'plenary.path'
local Task = require('tasko').Task
local Store = require('tasko').Store
describe('text to task', function()
  it('Creates a task', function()
    local task = Task:new(nil, "This is my test Task", "This is the body of my test task")
    assert(task.title == "This is my test Task", "Title couldn't be parsed.")
    assert.is_not_nil(task.id)
  end)

  it('converts a markdown file to a task', function()
    -- loads test file into buffer 1
    vim.fn.execute('edit lua/spec/tasko/test_task.md', false)
    local task = Task:from_file()
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

  it('writes a markdown file to a task', function()
    vim.fn.execute('edit lua/spec/tasko/test_task.md', false)
    local file_name = Store:write()
    local file = Path:new(file_name)
    assert(file:exists())
    file:rm()
  end)
end)

describe('listing tasks', function()
  it('reads all tasks from the tasko directory', function()
    vim.fn.execute('edit lua/spec/tasko/test_task.md', false)
    vim.api.nvim_buf_set_lines(0, 14, 15, false, { '1234-1' })
    Store:write()
    vim.api.nvim_buf_set_lines(0, 14, 15, false, { '1234-2' })
    Store:write()
    vim.api.nvim_buf_set_lines(0, 14, 15, false, { '1234-3' })
    Store:write()
    local found = {}
    found[1] = false
    found[2] = false
    found[3] = false

    for _, file_path in ipairs(Store:read_all()) do
      if ('1234-1.md' == file_path) then
        found[1] = true
      elseif ('1234-2.md' == file_path) then
        found[2] = true
      elseif ('1234-3.md' == file_path) then
        found[3] = true
      end
    end
    assert(found[1] and found[2] and found[3], 'Not all files were found')
    Store:delete('1234-1')
    Store:delete('1234-2')
    Store:delete('1234-3')
  end)
end)
