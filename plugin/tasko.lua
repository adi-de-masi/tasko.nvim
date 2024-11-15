local Store = require("tasko.store")
local Task = require("tasko.task")
local utils = require("tasko.utils")
local Todoist = require("todoist"):new()
local Path = require("plenary.path")

vim.api.nvim_create_user_command("TaskoList", function()
	local buf = Store:get_task_list_file()
	local task_list = Store:list_tasks()
	for _, task_file in ipairs(task_list) do
		local task = Store:get_task_from_file(task_file)
		local escaped_task_id = string.gsub(task.id, "%-", "%%-")
		local line_number_in_task_list = utils.line_number_of(buf, escaped_task_id)
		utils.replace_line(buf, line_number_in_task_list, task.to_task_list_line())
	end
	vim.api.nvim_set_current_buf(buf)
	vim.fn.execute("set ft=markdown")
	return buf
end, {})

vim.api.nvim_create_user_command("TaskoNew", function()
	local task = Task:new()
	local buf = task:to_buffer()
	vim.api.nvim_set_current_buf(buf)
	vim.fn.execute("set ft=markdown")
end, {})

vim.api.nvim_create_user_command("TaskoSyncTask", function()
	local current_task = Task:from_current_buffer()
	if current_task.todoist_id == nil then
		local task_payload = { content = current_task.title, description = current_task.body }
		local new_task_response = Todoist:new_task(task_payload)
		assert(new_task_response["status"] == 200, "Error creating task")
		local new_task_body = vim.json.decode(new_task_response["body"])
		current_task.todoist_id = new_task_body.id
		local current_buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_buf_call(current_buf, function()
			vim.api.nvim_buf_set_lines(
				current_buf,
				-1,
				-1,
				true,
				{ "", "[//]: # (todoist_id)", current_task.todoist_id }
			)
		end)
	else
		local update_task_payload =
			{ content = current_task.title, description = current_task.body, priority = current_task.priority }
		Todoist:update(current_task.todoist_id, update_task_payload)
	end
end, {})

vim.api.nvim_create_user_command("TaskoDone", function()
	local current_buf = vim.api.nvim_get_current_buf()
	local now = os.date("!%Y-%m-%dT%TZ")
	if type(now) == "string" then
		print("now is " .. now)
		vim.api.nvim_buf_call(current_buf, function()
			vim.api.nvim_buf_set_lines(current_buf, -1, -1, true, { "", "[//]: # (done)", now })
		end)
	end
	local task = Task:from_current_buffer()
	if task.todoist_id ~= nil then
		Todoist:complete(task.todoist_id)
	end
end, {})

function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

vim.api.nvim_create_user_command("TaskoFetchTasks", function()
	local tasks = Todoist:query_all("tasks")
	for _, value in ipairs(tasks) do
		local task = Task:new(tonumber(value["id"]), value["content"], value["description"])
		local task_path = Path:new(task.get_file_name())
		if not task_path:exists() then
			print("writing " .. task.id)
			Store:write_task_to_tasko_base_dir(task)
		end
	end
end, {})
