local Path = require("plenary.path")
local utils = {}
local random = math.random

function utils.split_by_newline(str)
	local result = {}
	for line in str:gmatch("([^\n]*)\n?") do
		table.insert(result, line)
	end
	return result
end

function utils.uuid()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	return string.gsub(template, "[xy]", function(c)
		local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
		return string.format("%x", v)
	end)
end

function utils.get_buf_by_pattern(pattern)
	local open_buffers = vim.api.nvim_list_bufs()
	local buf = nil
	for _, buf_nr in ipairs(open_buffers) do
		if vim.api.nvim_buf_is_loaded(buf_nr) then
			local buf_name = vim.api.nvim_buf_get_name(buf_nr)
			if string.find(buf_name, pattern) then
				buf = buf_nr
				break
			end
		end
	end
	return buf
end

function utils.line_number_of(buf, pattern)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	for line_number, line in ipairs(lines) do
		if string.find(line, pattern) then
			return line_number
		end
	end
	return nil
end

function utils.replace_line(buf, line_number, new_line)
	if line_number == nil then
		line_number = -1
	end
	vim.api.nvim_buf_call(buf, function()
		if line_number > 0 then
			vim.api.nvim_win_set_cursor(0, { line_number, 0 })
			vim.api.nvim_del_current_line()
			if line_number > 1 then
				vim.api.nvim_win_set_cursor(0, { line_number - 1, 0 })
			end
		end
		vim.api.nvim_put({ new_line }, "l", true, false)
	end)
end

function utils.get_or_create_tasko_directory()
	-- `~/.config/share/nvim` on unix
	local data_dir = vim.fn.stdpath("data")
	if type(data_dir) == "table" then
		data_dir = data_dir[1]
	end
	local tasko_dir = vim.fs.joinpath(data_dir, "tasko")
	local tasko_dir_path = Path:new(tasko_dir)
	if not tasko_dir_path:exists() then
		tasko_dir_path:mkdir()
	end
	return tasko_dir
end

return utils
