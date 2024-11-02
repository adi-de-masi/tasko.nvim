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

  it('reads all tasks from the tasko directory', function()
    vim.fn.execute('edit lua/spec/tasko/test_task.md', false)
    local file_name_regex = '.*%/(.*%.md)$'
    local file_path_1 = Store:write()
    local _, _, file_name_1 = string.find(file_path_1, file_name_regex)
    local file_path_2 = Store:write()
    local _, _, file_name_2 = string.find(file_path_2, file_name_regex)
    local file_path_3 = Store:write()
    local _, _, file_name_3 = string.find(file_path_3, file_name_regex)
    local found = {}
    found[1] = false
    found[2] = false
    found[3] = false

    local dir_content = Store:read_all()
    for _, file_path in ipairs(dir_content) do
      if (file_name_1 == file_path) then
        found[1] = true
      elseif (file_name_2 == file_path) then
        found[2] = true
      elseif (file_name_3 == file_path) then
        found[3] = true
      end
    end
    assert(found[1] and found[2] and found[3], 'Not all files were found')
    Path:new(file_path_1):rm()
    Path:new(file_path_2):rm()
    Path:new(file_path_3):rm()
  end)
end)
