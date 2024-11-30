local Store = require("tasko.store")
local Task = require("tasko.task")
local utils = require("tasko.utils")
local Todoist = require("todoist"):new()
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

vim.api.nvim_create_user_command("TaskoList", function()
	local displayed_list = {}
	local task_files = Store:list_tasks()
	for i, task_file in ipairs(task_files) do
		local task = Store:get_task_from_path(task_file)
		local has_todoist_id = task.todoist_id ~= nil
		local display_string = (has_todoist_id and "📅 " or "") .. task.title
		displayed_list[i] = {
			value = task_file,
			display = display_string,
			ordinal = task.priority,
		}
	end
	local opts = {}
	pickers
		.new(opts, {
			prompt_title = "All Tasks",
			finder = finders.new_table({
				results = displayed_list,
				entry_maker = function(entry)
					return {
						value = entry.value,
						display = entry.display,
						ordinal = entry.ordinal,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			previewer = require("telescope.previewers").cat.new(opts),
		})
		:find()
end, {})

vim.api.nvim_create_user_command("TaskoNew", function()
	local task = Task:new()
	local buf = task:to_buffer()
	vim.api.nvim_set_current_buf(buf)
	vim.fn.execute("set ft=markdown")
end, {})

vim.api.nvim_create_user_command("TaskoSyncTask", function()
	local current_task = Task:from_current_buffer()
	if current_task == nil then
		print("cannot parse a task from this buffer")
		return
	end
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
	if task == nil then
		print("cannot parse a task from this buffer")
		return
	end
	if task.todoist_id ~= nil then
		Todoist:complete(task.todoist_id)
	end
end, {})

vim.api.nvim_create_user_command("TaskoFetchTasks", function()
	local tasks = Todoist:query_all("tasks")
	for _, value in ipairs(tasks) do
		local task = Task:new(
			tonumber(value["id"]),
			value["content"],
			value["description"],
			tonumber(value["priority"]),
			value["is_completed"]
		)
		Store:write(task)
	end
end, {})
