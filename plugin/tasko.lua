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
	return Task:new(
		tonumber(value["id"]),
		value["content"],
		value["description"],
		tonumber(value["priority"]),
		value["is_completed"]
	)
end

vim.api.nvim_create_user_command("TaskoList", function()
	local displayed_list = {}
	local task_files = Store:list_tasks()
	local i = 1
	for id, task_file in pairs(task_files) do
		local task = Store:get_task_from_paths(task_file.task_file, task_file.task_description_file)
		local has_todoist_id = task.todoist_id ~= nil
		local display_string = (has_todoist_id and "📅 " or "")
			.. (task.title or task.description or "(no title, no description)")

		displayed_list[i] = {
			value = { files = task_files[id], task = task },
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
						value = { files = entry.value.files, task = entry.value.task },
						display = entry.display,
						ordinal = entry.display,
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
						local task = selection.value.task
						vim.cmd("edit " .. selection.value.files.task_description_file)
						local buf = vim.api.nvim_get_current_buf()
						task.to_buffer(buf)

						if task.todoist_id ~= nil then
							vim.api.nvim_buf_set_keymap(
								buf,
								"n",
								"<leader>u",
								":lua require('todoist'):new():update(" .. selection.value.task.todoist_id .. ")<CR>",
								{ noremap = true, silent = true }
							)
						end
					else
						print("No file selected")
					end
				end)
				return true
			end,
			previewer = previewers.new_buffer_previewer({
				define_preview = function(self, entry)
					local task = entry.value.task
					local buf = self.state.bufnr
					if task then
						local description_file_content = Store:get_task_title_and_description(task.id)
						vim.api.nvim_buf_call(buf, function()
							vim.api.nvim_put({ description_file_content }, "l", true, false)
						end)
						task.to_buffer(buf)
					else
						vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Could not open file" })
					end
				end,
			}),
		})
		:find()
end, {})

vim.api.nvim_create_user_command("TaskoSave", function()
	local filename = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
	local _, _, task_id = string.find(filename, ".*/(.*).md")
	if not task_id then
		print("Not a task")
		return
	end
	Store:update_task_from_markdown(task_id)

	local task = Store:get_task_by_id(task_id)
	assert(task ~= nil, "task with id " .. task_id .. " not found!")

	if task.todoist_id == nil or task.todoist_id == "" then
		print("new task! " .. task.todoist_id .. ".")
		local updated_task = Todoist:new_task(task)
		Store:write(To_task(updated_task))
		local buf = vim.api.nvim_get_current_buf()
		updated_task.to_buffer(buf)
	else
		Todoist:update(task.id)
	end
end, {})

vim.api.nvim_create_user_command("TaskoNew", function()
	vim.ui.input({ prompt = "Task Title: " }, function(input)
		local task = Task:new()
		task.title = input
		local files = Store:write(task)
		vim.cmd("edit " .. files.task_description_file)
		local buf = vim.api.nvim_get_current_buf()
		task.to_buffer(buf)
	end)
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
		local task = To_task(value)
		Store:write(task)
	end
end, {})
