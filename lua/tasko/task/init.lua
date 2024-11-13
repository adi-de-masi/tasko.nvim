local utils = require("tasko.utils")
local tasko_base_dir = utils.get_or_create_tasko_directory()
local Task = {}
function Task:new(id, title, body)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.id = id or utils.uuid()
	o.title = title or ""
	o.body = body or ""
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
			o.id,
		}
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

function Task:from_lines(lines)
	--[[
  Our delimiter is a markdown comment like so
  `[//]: # (title)`
  --]]
	local delimiter_regex = "^%s*(%[//%]: #)%s*%((.*)%)"
	local task = Task:new()
	local current_column = nil
	for _, line in ipairs(lines) do
		local _, _, delimiter, column = string.find(line, delimiter_regex)
		if delimiter then
			current_column = column
		elseif current_column ~= nil then
			local empty_captures = not string.match(line, "^%s*$")
			local value = string.gsub(line, "^#%s*", "")
			if current_column == "body" then
				-- the only place where we accept blank lines
				local existing_body = (task["body"] ~= nil and task["body"] or "")
				task["body"] = existing_body .. value .. "\n"
			elseif value ~= "" and empty_captures ~= nil then
				task[current_column] = value
			end
		end
	end
	return task
end

return Task
