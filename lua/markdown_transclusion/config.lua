-- config.lua
-- Configuration module for obsidian-transclusion plugin

local M = {}

-- Default configuration values
M.defaults = {
	-- Base directory for notes (default: notes/ directory relative to git root)
	notes_dir = vim.fn.fnamemodify(vim.fn.finddir('.git', '.;'), ':h') .. '/notes',

	-- File extensions to consider for transclusion (default: md, markdown)
	valid_extensions = { "md", "markdown" },

	-- Search recursively in subdirectories
	recursive_search = true,

	-- Pattern to identify transclusion syntax (default: Obsidian's ![[note]] with optional section)
	transclusion_pattern = "!%[%[([^#]*)#?([^%]]*)%]%]",

	-- Virtual text to indicate transclusion
	virtual_text_enabled = true,
	virtual_text_hl_group = "Comment",

	-- Update transclusions when saving the file
	update_on_save = true,

	-- Show warnings for missing files
	show_warnings = true,

	-- Automatically setup keymaps
	setup_keymaps = true,
}

-- Function to validate and merge user config with defaults
function M.apply(user_config)
	local config = vim.tbl_deep_extend("force", M.defaults, user_config or {})

	-- Validation and normalization

	-- Make sure notes_dir doesn't end with a slash
	if config.notes_dir:sub(-1) == "/" then
		config.notes_dir = config.notes_dir:sub(1, -2)
	end

	-- Convert to absolute path if relative
	if config.notes_dir:sub(1, 1) == "~" then
		config.notes_dir = vim.fn.expand(config.notes_dir)
	end

	-- Ensure valid_extensions is a table
	if type(config.valid_extensions) == "string" then
		config.valid_extensions = { config.valid_extensions }
	end

	-- Make sure transclusion_pattern is valid
	if config.transclusion_pattern == "" then
		config.transclusion_pattern = M.defaults.transclusion_pattern
		vim.notify("Invalid transclusion pattern, using default", vim.log.levels.WARN)
	end

	-- Convert highlight group to string
	config.virtual_text_hl_group = tostring(config.virtual_text_hl_group)

	return config
end

-- Function to create highlight groups
function M.setup_highlights()
	-- Define highlight links if they don't exist
	local highlights = {
		ObsidianTransclusionMarker = { link = "Special" },
		ObsidianTransclusionPath = { link = "String" },
		ObsidianTransclusionVirtualText = { link = "Comment" },
		ObsidianTransclusionWarning = { link = "WarningMsg" },
	}

	for group_name, definition in pairs(highlights) do
		vim.api.nvim_set_hl(0, group_name, definition)
	end
end

return M
