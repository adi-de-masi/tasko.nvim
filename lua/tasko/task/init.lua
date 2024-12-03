local utils = require("tasko.utils")
-- local Store = require("tasko.store")
local tasko_base_dir = utils.get_or_create_tasko_directory()
local Task = {}

function Task:new(id, title, description, priority, is_completed)
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
	o.description = description or ""
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
	o.to_buffer = function(buf)
		local lines = {
			"# " .. o.title,
			"",
			o.description,
			"",
			"---------------------",
			"-- id: " .. o.id,
			"-- todoist_id: " .. (o.todoist_id or ""),
			"-- priority: " .. o.priority,
			"-- is_completed: " .. tostring(o.is_completed),
		}
		vim.api.nvim_buf_call(buf, function()
			vim.api.nvim_put(lines, "l", false, false)
		end)
	end
	return o
end

function Task:from_json(json_lines)
	local decoded = vim.json.decode(json_lines)
	local id = decoded.id
	local title = decoded.title
	local description = decoded.description
	local priority = decoded.priority or 1
	local is_completed = decoded.is_completed or false
	return Task:new(id, title, description, priority, is_completed)
end

function Task:from_current_buffer()
	return Task:from_buffer(vim.api.nvim_get_current_buf())
end

function Task:from_buffer(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	return Task:from_lines(lines)
end

function Task:from_lines(lines)
	local task = Task:new()
	local current_column = nil
	local delimiter_regex = "^%s*(%[//%]: #)%s*%((.*)%)"
	for _, line in ipairs(lines) do
		local _, _, delimiter, column = string.find(line, delimiter_regex)
		if delimiter then
			current_column = column
		elseif current_column ~= nil then
			local empty_captures = not string.match(line, "^%s*$")
			local value = string.gsub(line, "^#%s*", "")
			if current_column == "description " then
				local existing_description = (task["description"] ~= nil and task["description"] or "")
				task["description"] = existing_description .. value .. "\n"
			elseif value ~= "" and empty_captures ~= nil then
				task[current_column] = value
			end
		end
	end
end

return Task
