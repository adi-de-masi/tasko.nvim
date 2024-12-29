local Store = require("tasko.store")
local Task = require("tasko.task")
local config = require("lazy.core.config").plugins["tasko"].config
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
	for _, task_file in pairs(task_files) do
		local task = Store:get_task_from_path(task_file)
		if task ~= nil and tostring(task.is_completed) ~= "true" then
			local has_provider_id = task.provider_id ~= nil
			local display_string = (has_provider_id and "✅ " or "")
				.. (task.title or task.description or "(no title, no description)")

			displayed_list[i] = {
				value = { file = task_file, task = task },
				display = display_string,
				ordinal = task.priority,
			}
		end
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
						ordinal = entry.display
								.. entry.value.task.description
								.. "priority: "
								.. entry.value.task.priority
								.. " "
								.. entry.value.task.provider_id
							or "" .. " " .. entry.value.task.id,
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

local function get_provider()
	if config and config.provider then
		local provider = require("tasko.providers." .. config.provider)
		if provider == nil then
			print("Provider not found: " .. config.provider)
			return {}
		end
		return provider
	end
	return {}
end

vim.api.nvim_create_user_command("TaskoSync", function()
	local filename = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())

	local task = Store:get_task_from_path(filename)
	assert(task ~= nil, filename .. " cannot be interpreted as task")

	if config and config.provider then
		local provider = get_provider()
		if task.provider_id == nil or task.provider_id == "" then
			local updated_task = provider:new_task(task)
			local buf = vim.api.nvim_get_current_buf()
			updated_task.to_buffer(buf)
			vim.cmd("write")
		else
			provider:update(task)
		end
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
	if task ~= nil and task.provider_id ~= nil then
		local provider = get_provider()
		provider:complete(task.provider_id)
		task.is_completed = true
		Store:write(task)
		local buf = vim.api.nvim_get_current_buf()
		task.to_buffer(buf)
		vim.cmd("write")
	end
end, {})

vim.api.nvim_create_user_command("TaskoFetchTasks", function()
	local provider = get_provider()
	local tasks = provider:query_all("tasks")
	for _, value in ipairs(tasks) do
		local task = provider:to_task(value)
		Store:write(task)
	end
end, {})

vim.api.nvim_create_user_command("TaskoTest", function()
	local task_files = Store:list_tasks()
	local i = 1
	for _, task_file in pairs(task_files) do
		print("i: " .. i)
		print("file: " .. task_file)
		local task = Store:get_task_from_path(task_file)
		print("task: " .. vim.inspect(task))
		i = i + 1
	end
end, {})
