local utils = require("tasko.utils")
local Task = {}

function Task:new(id, title, description, priority, is_completed)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.id = id or utils.uuid()
	o.title = title or ""
	o.description = description or ""
	o.priority = priority or 4
	o.is_completed = is_completed or false
	o.set_provider_id = function(provider_id)
		o.provider_id = provider_id
	end
	o.to_buffer = function(buf)
		-- first remove old ones
		local existing_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local meta_lines_start = nil
		local meta_lines_end = vim.api.nvim_buf_line_count(buf)
		for index, value in ipairs(existing_lines) do
			if string.match(value, "^---------------------$") then
				meta_lines_start = index
			end
		end

		if meta_lines_start ~= nil then
			vim.api.nvim_buf_set_lines(buf, meta_lines_start - 1, meta_lines_end, false, {})
		end

		local lines = o.to_params_as_md_comment()
		local last_line = vim.api.nvim_buf_line_count(buf)
		vim.api.nvim_buf_set_lines(buf, last_line, last_line, false, { "" })
		vim.api.nvim_buf_set_lines(buf, last_line + 1, last_line + 1, false, lines)
	end
	o.to_params_as_md_comment = function()
		return {
			"---------------------",
			"-- id: " .. o.id,
			"-- provider_id: " .. (o.provider_id or ""),
			"-- priority: " .. (o.priority or 4),
			"-- is_completed: " .. tostring(o.is_completed or false),
		}
	end
	return o
end

function Task:from_current_buffer()
	return Task:from_buffer(vim.api.nvim_get_current_buf())
end

function Task:from_buffer(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	return Task:from_lines(table.concat(lines, "\n"))
end

function Task:from_lines(lines_as_string)
	local task = Task:new()
	task.id = nil
	local delimiter_regex = "^%-%-%s+([%w%-_]+):%s+(%w+)"
	local lines = utils.split_by_newline(lines_as_string)
	for index, line in ipairs(lines) do
		if index == 1 then
			task.title = string.gsub(line, "^#%s*", "")
		else
			local key, value = string.match(line, delimiter_regex)
			if key and value then
				task[key] = value
			elseif string.match(line, "^%-.*") == nil then
				task["description"] = (task["description"] or "") .. "\n" .. line
			end
		end
	end
	if task.id == nil then
		return nil
	end
	return task
end

return Task
