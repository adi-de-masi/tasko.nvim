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

function Store:write(task)
	local outputFile = utils.get_or_create_tasko_directory() .. "/" .. task.id .. ".json"
	io.output(outputFile)
	io.write(vim.fn.json_encode(tableToSerializable(task)))
	io.flush()
	io.close()
	return outputFile
end

function Store:delete(task_id)
	local file_path = vim.fs.joinpath(tasko_base_dir, task_id .. ".md")
	return Path:new(file_path):rm()
end

function Store:get_task_from_path(path_to_file)
	local file_content = Path:new(path_to_file):read()
	return Task:from_json(file_content)
end

function Store:list_tasks()
	local result = {}
	local i = 1
	for file in io.popen("ls -pa " .. tasko_base_dir .. "| grep -v / "):lines() do
		result[i] = vim.fs.joinpath(tasko_base_dir, file)
		i = i + 1
	end
	return result
end

return Store
