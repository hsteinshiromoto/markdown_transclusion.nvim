-- lua/markdown_transclusion/init.lua
-- A Neovim plugin that implements Obsidian-style transclusion functionality

local config = require("markdown_transclusion.config")
local M = {}

-- Will hold the actual configuration after setup
M.config = {}

-- Setup function to initialize the plugin with user configuration
function M.setup(opts)
	-- Apply and validate config
	M.config = config.apply(opts)

	-- Setup highlight groups
	config.setup_highlights()

	-- Create autocommands for the plugin
	local augroup = vim.api.nvim_create_augroup("ObsidianTransclusion", { clear = true })

	-- Render transclusions when opening a valid file
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		pattern = { "*.md", "*.markdown" },
		callback = function()
			M.render_transclusions()
		end,
	})

	-- Update transclusions when saving if configured
	if M.config.update_on_save then
		vim.api.nvim_create_autocmd("BufWritePost", {
			group = augroup,
			pattern = { "*.md", "*.markdown" },
			callback = function()
				M.render_transclusions()
			end,
		})
	end

	-- Command to manually render transclusions
	vim.api.nvim_create_user_command("ObsidianRenderTransclusions", function()
		M.render_transclusions()
	end, {})

	-- Command to toggle virtual text
	vim.api.nvim_create_user_command("ObsidianToggleVirtualText", function()
		M.config.virtual_text_enabled = not M.config.virtual_text_enabled
		M.render_transclusions()
	end, {})

	-- Set up keymaps if enabled
	if M.config.setup_keymaps then
		M.setup_keymaps()
	end
end

-- Find a note file by name
function M.find_note_file(name)
	-- First try with the name as-is
	local direct_path = M.config.notes_dir .. "/" .. name
	if vim.fn.filereadable(direct_path) == 1 then
		return direct_path
	end

	-- Try with each valid extension
	for _, ext in ipairs(M.config.valid_extensions) do
		local path_with_ext = M.config.notes_dir .. "/" .. name .. "." .. ext
		if vim.fn.filereadable(path_with_ext) == 1 then
			return path_with_ext
		end
	end

	-- Not found
	return nil
end

-- Read the contents of a file
function M.read_file_contents(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return nil
	end

	local content = file:read("*all")
	file:close()
	return content
end

-- Get the namespace for virtual text and extmarks
function M.get_namespace()
	if not M.namespace then
		M.namespace = vim.api.nvim_create_namespace("markdown_transclusion")
	end
	return M.namespace
end

-- Extract a section from markdown content based on header
function M.extract_section(content, section_name)
	if not section_name then
		return content
	end

	local lines = vim.split(content, "\n")
	local result = {}
	local in_section = false
	local section_level = 0

	for _, line in ipairs(lines) do
		local header_match = line:match("^(#+)%s+(.+)$")
		if header_match then
			local level = #header_match
			local title = header_match:match("^#+%s+(.+)$")

			if title == section_name then
				in_section = true
				section_level = level
				table.insert(result, line)
			elseif in_section then
				-- Check if we've hit a header of the same or higher level
				if level <= section_level then
					break
				end
				table.insert(result, line)
			end
		elseif in_section then
			table.insert(result, line)
		end
	end

	return table.concat(result, "\n")
end

-- Render all transclusions in the current buffer
function M.render_transclusions()
	local bufnr = vim.api.nvim_get_current_buf()
	local namespace = M.get_namespace()

	-- Clear previous extmarks and virtual text
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

	-- Get all lines in the buffer
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local transclusions = {}

	-- Find all transclusion markers
	for i, line in ipairs(lines) do
		local start_idx, end_idx, note_name, _, section_name = line:find(M.config.transclusion_pattern)

		if start_idx then
			table.insert(transclusions, {
				line_idx = i - 1, -- 0-indexed for API
				start_idx = start_idx,
				end_idx = end_idx,
				note_name = note_name:gsub("^%s*(.-)%s*$", "%1"), -- Trim whitespace
				section_name = section_name and section_name:gsub("^%s*(.-)%s*$", "%1") or nil, -- Trim whitespace
			})
		end
	end

	-- Process each transclusion
	for _, t in ipairs(transclusions) do
		local file_path = M.find_note_file(t.note_name)

		if file_path then
			local content = M.read_file_contents(file_path)

			if content then
				-- Extract the specified section if any
				local transcluded_content = M.extract_section(content, t.section_name)

				-- Add virtual text if enabled
				if M.config.virtual_text_enabled then
					local virtual_text = " Transcluded from: " .. t.note_name
					if t.section_name then
						virtual_text = virtual_text .. " (section: " .. t.section_name .. ")"
					end
					vim.api.nvim_buf_set_extmark(bufnr, namespace, t.line_idx, 0, {
						virt_text = { { virtual_text, M.config.virtual_text_hl_group } },
						virt_text_pos = "eol",
					})
				end

				-- Visually distinguish transclusion markers with highlighting
				vim.api.nvim_buf_add_highlight(
					bufnr,
					namespace,
					"ObsidianTransclusionMarker",
					t.line_idx,
					t.start_idx - 1,
					t.start_idx + 2
				)
				vim.api.nvim_buf_add_highlight(
					bufnr,
					namespace,
					"ObsidianTransclusionPath",
					t.line_idx,
					t.start_idx + 2,
					t.end_idx - 2
				)
				vim.api.nvim_buf_add_highlight(
					bufnr,
					namespace,
					"ObsidianTransclusionMarker",
					t.line_idx,
					t.end_idx - 2,
					t.end_idx
				)
			end
		elseif M.config.show_warnings then
			-- Show warning for missing files
			if M.config.virtual_text_enabled then
				vim.api.nvim_buf_set_extmark(bufnr, namespace, t.line_idx, 0, {
					virt_text = {
						{ " Warning: Note '" .. t.note_name .. "' not found", "ObsidianTransclusionWarning" },
					},
					virt_text_pos = "eol",
				})
			end

			-- Highlight the missing file path differently
			vim.api.nvim_buf_add_highlight(
				bufnr,
				namespace,
				"ObsidianTransclusionMarker",
				t.line_idx,
				t.start_idx - 1,
				t.start_idx + 2
			)
			vim.api.nvim_buf_add_highlight(
				bufnr,
				namespace,
				"ObsidianTransclusionWarning",
				t.line_idx,
				t.start_idx + 2,
				t.end_idx - 2
			)
			vim.api.nvim_buf_add_highlight(
				bufnr,
				namespace,
				"ObsidianTransclusionMarker",
				t.line_idx,
				t.end_idx - 2,
				t.end_idx
			)
		end
	end
end

-- Function to preview transcluded content
function M.preview_transclusion()
	local line = vim.api.nvim_get_current_line()
	local start_idx, end_idx, note_name, _, section_name = line:find(M.config.transclusion_pattern)

	if not start_idx then
		vim.notify("No transclusion found on current line", vim.log.levels.INFO)
		return
	end

	note_name = note_name:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
	local file_path = M.find_note_file(note_name)

	if not file_path then
		vim.notify("Note '" .. note_name .. "' not found", vim.log.levels.WARN)
		return
	end

	local content = M.read_file_contents(file_path)

	if not content then
		vim.notify("Failed to read content of '" .. note_name .. "'", vim.log.levels.ERROR)
		return
	end

	-- Extract the specified section if any
	if section_name then
		content = M.extract_section(content, section_name)
	end

	-- Create a floating window to display the content
	local width = math.min(80, vim.o.columns - 4)
	local height = math.min(20, vim.o.lines - 4)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))

	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

	local opts = {
		relative = "cursor",
		width = width,
		height = height,
		col = 0,
		row = 1,
		style = "minimal",
		border = "rounded",
		title = " " .. note_name .. " ",
		title_pos = "center",
	}

	local win = vim.api.nvim_open_win(buf, false, opts)

	-- Close the window with 'q' or Escape
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })

	-- Add autocommand to close when cursor moves
	local augroup = vim.api.nvim_create_augroup("ObsidianTransclusionPreview", { clear = true })
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = augroup,
		buffer = vim.api.nvim_get_current_buf(),
		callback = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
			vim.api.nvim_del_augroup_by_id(augroup)
		end,
		once = true,
	})
end

-- Function to expand a transclusion in place
function M.expand_transclusion()
	local bufnr = vim.api.nvim_get_current_buf()
	local line_idx = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed
	local line = vim.api.nvim_get_current_line()

	local start_idx, end_idx, note_name, _, section_name = line:find(M.config.transclusion_pattern)

	if not start_idx then
		vim.notify("No transclusion found on current line", vim.log.levels.INFO)
		return
	end

	note_name = note_name:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
	local file_path = M.find_note_file(note_name)

	if not file_path then
		vim.notify("Note '" .. note_name .. "' not found", vim.log.levels.WARN)
		return
	end

	local content = M.read_file_contents(file_path)

	if not content then
		vim.notify("Failed to read content of '" .. note_name .. "'", vim.log.levels.ERROR)
		return
	end

	-- Extract the specified section if any
	if section_name then
		content = M.extract_section(content, section_name)
	end

	-- Get leading whitespace
	local leading_whitespace = line:match("^%s*") or ""

	-- Split the content into lines
	local content_lines = vim.split(content, "\n")

	-- Add leading whitespace to each line except the first
	for i = 2, #content_lines do
		content_lines[i] = leading_whitespace .. content_lines[i]
	end

	-- Replace the transclusion marker with the content
	local before_marker = line:sub(1, start_idx - 1)
	local after_marker = line:sub(end_idx + 1)

	-- First line combines before_marker + first content line + after_marker
	local first_line = before_marker .. content_lines[1] .. after_marker

	-- Prepare the replacement lines
	local replacement_lines = { first_line }
	for i = 2, #content_lines do
		table.insert(replacement_lines, content_lines[i])
	end

	-- Replace the current line with the expanded content
	vim.api.nvim_buf_set_lines(bufnr, line_idx, line_idx + 1, false, replacement_lines)

	-- Notify user
	vim.notify("Expanded transclusion of '" .. note_name .. "'", vim.log.levels.INFO)
end

-- Set up key mappings
function M.setup_keymaps()
	-- Preview transclusion content in a floating window (press 'gp' over a transclusion)
	vim.api.nvim_set_keymap(
		"n",
		"gp",
		'<cmd>lua require("markdown_transclusion").preview_transclusion()<CR>',
		{ noremap = true, silent = true, desc = "Preview transclusion" }
	)

	-- Expand transclusion in place (press 'ge' over a transclusion)
	vim.api.nvim_set_keymap(
		"n",
		"ge",
		'<cmd>lua require("markdown_transclusion").expand_transclusion()<CR>',
		{ noremap = true, silent = true, desc = "Expand transclusion" }
	)
end

return M
