local Path = require 'plenary.path'
local Task = require('tasko').Task
local Store = require('tasko').Store
local utils = require('tasko').Utils

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
    -- and a file we don't want to see in list_tasks: The tasklist itself
    -- we give it a different name to make sure it doesn't accidentally
    -- overwrite a real task list
    local excluded_filename = '*integration-test-tasks*.md'
    local task_list_file = string.format("%s/tasko/%s", vim.fn.stdpath('data'), excluded_filename)
    vim.fn.execute('edit ' .. task_list_file, false)
    vim.fn.execute('write')

    local found = {}
    found[1] = false
    found[2] = false
    found[3] = false

    for _, file_path in ipairs(Store:list_tasks(excluded_filename)) do
      if ('1234-1.md' == file_path) then
        found[1] = true
      elseif ('1234-2.md' == file_path) then
        found[2] = true
      elseif ('1234-3.md' == file_path) then
        found[3] = true
      elseif (excluded_filename == file_path) then
        assert(false, 'Excluded file listed! ' .. file_path)
      end
    end
    assert(found[1] and found[2] and found[3], 'Not all files were found')
    Store:delete('1234-1')
    Store:delete('1234-2')
    Store:delete('1234-3')
    Path:new(task_list_file):rm()
  end)
end)

describe('get_buf_by_pattern', function()
  it('finds the tasks file', function()
    vim.fn.execute('edit schnarf.md')
    vim.fn.execute('edit schnirf.md')
    vim.fn.execute('edit *tasks*.md')
    local buf = utils.get_buf_by_pattern("%*tasks%*.md")
    assert.is_number(buf, "Could not identify the open tasks buffer.")
  end)
end)

describe("line_number_of", function()
  it('finds first line of pattern in a buffer', function()
    local buf = vim.api.nvim_create_buf(true, false)
    local md_comment = "[Pimmelpammel](/home/dmad/.local/share/nvim/tasko/a88454fe-5d50-4586-9173-161af7a3dc7e.md)"
    local escaped = "a88454fe%-5d50%-4586%-9173%-161af7a3dc7e"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "Birnenbaum",
      "Apfelbaum",
      "Kastanienbaum",
      md_comment
    })
    assert.is_equal(2, utils.line_number_of(buf, "Apfelbaum"))
    assert.is_equal(4, utils.line_number_of(buf, escaped))
    assert.is_nil(utils.line_number_of(buf, "Eiche"))
  end)
end)
