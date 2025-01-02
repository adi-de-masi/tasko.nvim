local Path = require "plenary.path"
local Task = require "tasko.task"
local utils = require "tasko.utils"
local tasko_base_dir = utils.get_or_create_tasko_directory()
local Store = {}

local get_task_file = function(task_id)
  return Path:new(utils.get_or_create_tasko_directory(), task_id .. ".md")
end

function Store:write(task)
  local task_file = get_task_file(task.id)
  local title_and_description = "# " .. task.title
  if task.description and task.description ~= "" then
    title_and_description = title_and_description .. "\n" .. task.description
  end
  local task_params = task.to_params_as_md_comment()
  task_file:write(title_and_description .. "\n" .. table.concat(task_params, "\n"), "w")
  return task_file.filename
end

function Store:delete(task_id)
  local file_path = vim.fs.joinpath(tasko_base_dir, task_id .. ".md")
  return Path:new(file_path):rm()
end

-- Constructs the task table based on these infos:
-- 1. Title and Description from the file in `path_to_description`
-- 2. All the rest from `path_to_file`
function Store:get_task_from_path(path_to_file)
  assert(path_to_file, "path_to_file is required")
  local file_content = Path:new(path_to_file):read()
  return Task:from_lines(file_content)
end

function Store:list_tasks()
  local result = {}
  for file in io.popen("ls -pa " .. tasko_base_dir .. "| grep -v /"):lines() do
    local filename_without_extension = file:match "^(.*)%."
    result[filename_without_extension] = vim.fs.joinpath(tasko_base_dir, file)
  end
  return result
end

return Store
