local M = {}

-- Default configuration
M.default_config = {
  provider = "local", -- Default to 'local' provider
}

-- Store the configuration
M.config = {}

-- Setup function
function M.setup(user_config)
  -- Merge user-provided config with the default config
  M.config = vim.tbl_deep_extend("force", M.default_config, user_config or {})

  -- Define an augroup to ensure autocommand is only created once
  local augroup = vim.api.nvim_create_augroup("TaskoAutocommands", { clear = true })

  -- Create the autocommand
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    pattern = "tasko-*.md",
    callback = function()
      local current_date = os.date "!%Y-%m-%dT%H:%M:%SZ"

      local edited_line_pattern = "^%-%- edited_time: %w"
      local updated_line_pattern = "^%-%- updated_time: %w"

      local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

      local edited_line_index = nil
      for i, line in ipairs(buf_lines) do
        if string.match(line, edited_line_pattern) ~= nil then
          edited_line_index = i - 1
          break
        end
      end

      if edited_line_index then
        -- Replace the existing `--edited_time:` line with the new timestamp
        vim.api.nvim_buf_set_lines(
          0,
          edited_line_index,
          edited_line_index + 1,
          true,
          { "-- edited_time: " .. current_date }
        )
      elseif edited_line_index and not updated_line_index then
        -- Add the `--edited_time:` line to the end of the file
        vim.api.nvim_buf_set_lines(0, -1, -1, false, { "-- edited_time: " .. current_date })
      end
    end,
  })
end

return M
