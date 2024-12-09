local Store = require("tasko.store")
local Task = require("tasko.task")
local Todoist = require("todoist"):new()
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

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
						ordinal = entry.ordinal,
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

						-- Check if the autocmd is already set for this buffer
						if vim.b[buf] and vim.b[buf].autocmd_attached then
							print("no autocmd")
							return
						end

						-- Set a buffer-local variable to indicate the autocmd is set
						vim.api.nvim_buf_set_var(buf, "autocmd_attached", true)

						vim.api.nvim_create_autocmd("BufWritePost", {
							callback = function()
								Store:update_title_and_description(task.id)
							end,
						})
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

vim.api.nvim_create_user_command("TaskoNew", function()
	vim.ui.input({ prompt = "Task Title: " }, function(input)
		local task = Task:new()
		task.title = input
		local description_file = Store:write(task)
		vim.cmd("edit " .. description_file)
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
