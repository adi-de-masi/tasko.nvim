local Store = require 'tasko.store'
local Path = require 'plenary.path'
local Task = require 'tasko.task'

describe('Store', function()
  describe('Store:write_buffer_to_tasko_base_dir()', function()
    it('writes a markdown file to a task', function()
      vim.fn.execute('edit lua/spec/tasko/test_task.md', false)
      local file_name = Store:write_buffer_to_tasko_base_dir()
      local file = Path:new(file_name)
      assert(file:exists())
      file:rm()
    end)
  end)

  describe('Store:list_tasks', function()
    it('reads all tasks from the tasko directory', function()
      vim.fn.execute('edit lua/spec/tasko/test_task.md', false)
      vim.api.nvim_buf_set_lines(0, 14, 15, false, { '1234-1' })
      Store:write_buffer_to_tasko_base_dir()
      vim.api.nvim_buf_set_lines(0, 14, 15, false, { '1234-2' })
      Store:write_buffer_to_tasko_base_dir()
      vim.api.nvim_buf_set_lines(0, 14, 15, false, { '1234-3' })
      Store:write_buffer_to_tasko_base_dir()
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

  describe('Store:write_task_to_tasko_base_dir', function()
    it('Writes the task file properly', function()
      local task = Task:new('test-id', 'test-title', 'test-body')
      Store:write_task_to_tasko_base_dir(task)
      local written_task = Store:get_task_from_file('test-id.md')
      assert(written_task.id == 'test-id', 'id is wrong')
      assert(written_task.body == [[
test-body

]], 'body is wrong')
      assert(written_task.title == 'test-title', 'title is wrong')
      Store:delete(task.id)
    end)
  end)
end)
