local Store = require("tasko.store")
local Task = require("tasko.task")
local Todoist = require("todoist"):new()
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local function To_task(value)
	local title = string.gsub((value["content"] or ""), "\n", "")
	if title == nil or title == "" then
		print("scheisendreck " .. value["id"])
	end
	return Task:new(
		tonumber(value["id"]),
		title,
		value["description"],
		tonumber(value["priority"]),
		value["is_completed"]
	)
end

vim.api.nvim_create_user_command("TaskoList", function()
	local displayed_list = {}
	local task_files = Store:list_tasks()
	local i = 1
	for _, task_file in pairs(task_files) do
		local task = Store:get_task_from_path(task_file)
		local has_todoist_id = task.todoist_id ~= nil
		local display_string = (has_todoist_id and "📅 " or "")
			.. (task.title or task.description or "(no title, no description)")

		displayed_list[i] = {
			value = { file = task_file, task = task },
			display = display_string,
			ordinal = task.priority,
		}
		i = i + 1
	end
	local opts = {}
	pickers
		.new(opts, {
			prompt_title = "All Tasks",
			finder = finders.new_table({
				results = displayed_list,
				entry_maker = function(entry)
					return {
						value = { file = entry.value.file, task = entry.value.task },
						display = entry.display,
						ordinal = entry.display,
						filename = entry.value.file,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(_, _)
				-- Define what happens on Enter
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(vim.api.nvim_get_current_buf()) -- Close the picker
					if selection and selection.value and selection.value.task then
						vim.cmd("edit " .. selection.filename)
					else
						print("No file selected")
					end
				end)
				return true
			end,
			previewer = previewers.cat.new(opts),
		})
		:find()
end, {})

vim.api.nvim_create_user_command("TaskoSave", function()
	local filename = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())

	local task = Store:get_task_from_path(filename)
	assert(task ~= nil, filename .. " cannot be interpreted as task")

	if task.todoist_id == nil or task.todoist_id == "" then
		local updated_task = Todoist:new_task(task)
		Store:write(To_task(updated_task))
		local buf = vim.api.nvim_get_current_buf()
		updated_task.to_buffer(buf)
	else
		Todoist:update(task)
	end
end, {})

vim.api.nvim_create_user_command("TaskoNew", function()
	vim.ui.input({ prompt = "Task Title: " }, function(input)
		local task = Task:new()
		task.title = input
		local file = Store:write(task)
		vim.cmd("edit " .. file)
		local buf = vim.api.nvim_get_current_buf()
		task.to_buffer(buf)
	end)
end, {})

vim.api.nvim_create_user_command("TaskoDone", function()
	local task = Task:from_current_buffer()
	if task ~= nil and task.todoist_id ~= nil then
		Todoist:complete(task.todoist_id)
		task.is_completed = true
		Store:write(task)
		local buf = vim.api.nvim_get_current_buf()
		task.to_buffer(buf)
	end
end, {})

vim.api.nvim_create_user_command("TaskoFetchTasks", function()
	local tasks = Todoist:query_all("tasks")
	for _, value in ipairs(tasks) do
		local task = To_task(value)
		Store:write(task)
	end
end, {})
