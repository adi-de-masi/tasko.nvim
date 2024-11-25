local utils = require("tasko.utils")
local tasko_base_dir = utils.get_or_create_tasko_directory()
local Task = {}
local function serialize(task)
	if type(task) == "number" then
		io.write(task)
	elseif type(task) == "string" then
		io.write(string.format("%q", task))
	elseif type(task) == "table" then
		io.write("{\n")
		for k, v in pairs(task) do
			if type(v) ~= "function" then
				io.write("  ", k, " = ")
				serialize(v)
				io.write(",\n")
			end
		end
		io.write("}\n")
	else
		-- error("cannot serialize a " .. type(o))
	end
end

function Task:new(id, title, body, priority, is_completed)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	if type(id) == "number" then
		o.todoist_id = id
	else
		o.todoist_id = nil
	end
	o.id = id or utils.uuid()
	o.title = title or ""
	o.body = body or ""
	o.priority = priority or 4
	o.is_completed = is_completed or false
	o.get_file_name = function()
		return string.format("[%s](%s/%s.md)", o.title, tasko_base_dir, o.id)
	end
	o.to_task_list_line = function()
		if o.done ~= nil then
			return string.format("DONE: [%s](%s/%s.md)", o.title, tasko_base_dir, o.id)
		else
			return o.get_file_name()
		end
	end
	o.serialize = function()
		local outputFile = utils.get_or_create_tasko_directory() .. "/" .. o.id .. ".tasko"
		io.output(outputFile)
		serialize(o)
		io.flush()
		io.close()
	end
	o.to_buffer = function()
		local buf = vim.api.nvim_create_buf(true, false)
		local new_task_file = vim.fs.joinpath(tasko_base_dir, o.id .. ".md")
		vim.api.nvim_buf_set_name(buf, new_task_file)
		local template = {
			"[//]: # (title)",
			"# " .. o.title,
			"",
			"[//]: # (body)",
			"# " .. o.body,
			"",
			"[//]: # (id)",
			tostring(o.id),
			"",
			"[//]: # (priority)",
			tostring(o.priority),
			"",
			"[//]: # (is_completed)",
			tostring(o.is_completed),
		}
		if o.todoist_id ~= nil then
			template.concat({
				"",
				"[//]: # (todoist_id)",
				tostring(o.todoist_id),
			})
			table.insert(template, 1, "[//]: # (todoist_id)")
			table.insert(template, 2, tostring(o.todoist_id))
		end
		vim.api.nvim_buf_call(buf, function()
			vim.api.nvim_put(template, "l", false, false)
		end)
		return buf
	end
	return o
end

function Task:from_current_buffer()
	return Task:from_buffer(vim.api.nvim_get_current_buf())
end

function Task:from_buffer(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	return Task:from_lines(lines)
end

local function split(input, delimiter)
	local result = {}
	for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

function Task:from_lines(lines)
	local task = Task:new()
	local current_column = nil
	for _, line in ipairs(lines) do
		local _, j = (line):find("=")
		if j ~= nil and j > 0 then
			local splitted_string = split(line, "=")
			if splitted_string[1] ~= nil then
				current_column = splitted_string[1]:gsub("%s+", "")
				task[current_column] = splitted_string[2] or ""
			end
		elseif current_column == "description" then
			task[current_column] = task[current_column] .. line .. "\n"
		end
	end
	return task
end

return Task
