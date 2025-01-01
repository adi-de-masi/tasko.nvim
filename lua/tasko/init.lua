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
end

return M
