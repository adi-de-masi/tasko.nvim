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
	-- TODO: only add newline if there is a description
	local title_and_description = "# " .. task.title .. "\n" .. task.description
	local params = task.to_params_as_md_comment()
	task_description_file:write(title_and_description .. "\n" .. table.concat(params, "\n"), "w")
	return { task_file = task_file.filename, task_description_file = task_description_file.filename }
end

-- Intended to use when users save the task_description_file, meaning they probably want to update it.
function Store:update_task_from_markdown(task_id)
	local task_file = get_task_json_file(task_id)
	local task_description_file = get_task_description_file(task_id)
	local task_description_file_lines = utils.split_by_newline(task_description_file:read())
	local task = Task:new()
	local task_metatable = getmetatable(task)
	for index, line in ipairs(task_description_file_lines) do
		local key, value = line:match("^-- ([a-zA-Z_-]*): (.*)$")
		if index == 1 then
			task.title = line -- todo: remove #
		elseif key and value then
			task[key] = value
			task_metatable[key] = value
		else
			task.description = task.description .. "\n" .. line
		end
	end
	setmetatable(task, task_metatable)
	task_file:rm()
	task_file:write(vim.fn.json_encode(tableToSerializable(task)), "w")
end

function Store:delete(task_id)
	local file_path = vim.fs.joinpath(tasko_base_dir, task_id .. ".md")
	local json_path = vim.fs.joinpath(tasko_base_dir, task_id .. ".json")
	Path:new(json_path):rm()
	return Path:new(file_path):rm()
end

function Store:get_task_by_id(task_id)
	print("get_task_by_id here: " .. task_id)
	return Store:get_task_from_paths(get_task_json_file(task_id), get_task_description_file(task_id))
end

function Store:get_task_title_and_description(task_id)
	return get_task_description_file(task_id):read()
end

-- Constructs the task table based on these infos:
-- 1. Title and Description from the file in `path_to_description`
-- 2. All the rest from `path_to_file`
function Store:get_task_from_paths(path_to_file, path_to_description)
	assert(path_to_file, "path_to_file is required")
	assert(path_to_description, "path_to_description is required")
	local file_content = Path:new(path_to_file):read()
	local description = Path:new(path_to_description):read()
	local task = Task:from_json(file_content)
	task.title = nil
	task.description = nil

	local i = 1

	for _, line in ipairs(utils.split_by_newline(description)) do
		if i == 1 then
			local _, _, column = string.find(line, "^#%s*(.*)$")
			task.title = column
		elseif string.find(line, "^---") then
		-- do nothing
		else
			task.description = (task.description or "") .. line .. "\n"
		end
		i = i + 1
	end
	print("done getting the task from files: " .. task.id .. " / " .. task.title)
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
