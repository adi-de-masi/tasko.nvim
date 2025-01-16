local M = {}
local Task = require "tasko.task"
local utils = require "tasko.utils"

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

      local task = Task:from_current_buffer()

      if task and task.edited_time and task.updated_time then
        local edited = utils.parse_iso8601(task.edited_time)
        local updated = utils.parse_iso8601(task.updated_time)
        if updated >= edited then
          task.edited_time = nil
          task.updated_time = nil
        end
      elseif task then
        task.edited_time = current_date
      else
        debug = "No task found in the current buffer"
        return
      end
      local buf = vim.api.nvim_get_current_buf()
      task.to_buffer(buf)
    end,
  })
end

return M
