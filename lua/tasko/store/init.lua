local Path = require("plenary.path")
local Task = require("tasko.task")
local utils = require("tasko.utils")
local tasko_base_dir = utils.get_or_create_tasko_directory()
local Store = {}
Store.TASK_LIST_FILENAME = "*tasks*.md"

local function tableToSerializable(tbl)
	local serializable = {}
	for key, value in pairs(tbl) do
		if type(value) ~= "function" then
			serializable[key] = value
		end
	end
	return serializable
end

local get_task_json_file = function(task_id)
	return Path:new(utils.get_or_create_tasko_directory(), task_id .. ".json")
end

local get_task_description_file = function(task_id)
	return Path:new(utils.get_or_create_tasko_directory(), task_id .. ".md")
end

function Store:write(task)
	local task_file = get_task_json_file(task.id)
	task_file:write(vim.fn.json_encode(tableToSerializable(task)), "w")
	local task_description_file = get_task_description_file(task.id)
	task_description_file:write(task.description or "", "w")
	return { task_file = task_file.filename, task_description_file = task_description_file.filename }
end

function Store:update_description(task_id)
	local task_description_file = get_task_description_file(task_id)
	local task_file = get_task_json_file(task_id)
	local task = Task:from_json(task_file:read())
	local description = task_description_file:read()
	task.description = description
	Store:write(task)
end

function Store:delete(task_id)
	local file_path = vim.fs.joinpath(tasko_base_dir, task_id .. ".md")
	return Path:new(file_path):rm()
end

function Store:get_task_by_id(task_id)
	return Store:get_task_from_paths(get_task_json_file(task_id), get_task_description_file(task_id))
end

function Store:get_task_from_paths(path_to_file, path_to_description)
	assert(path_to_file, "path_to_file is required")
	assert(path_to_description, "path_to_description is required")
	local file_content = Path:new(path_to_file):read()
	local description = Path:new(path_to_description):read()
	local task = Task:from_json(file_content)
	task.description = description
	return task
end

function Store:list_tasks()
	local result = {}
	for file in io.popen("ls -pa " .. tasko_base_dir .. "| grep -v /"):lines() do
		local filename_without_extension = file:match("^(.*)%.")
		local file_extension = file:match(".*%.(.*)$")
		local type = file_extension == "json" and "task_file" or "task_description_file"
		if result[filename_without_extension] == nil then
			result[filename_without_extension] = { [type] = vim.fs.joinpath(tasko_base_dir, file) }
		else
			result[filename_without_extension][type] = vim.fs.joinpath(tasko_base_dir, file)
		end
	end
	return result
end

return Store
