-- lua/markdown_transclusion/init.lua
-- A Neovim plugin that implements Obsidian-style transclusion functionality

local config = require("markdown_transclusion.config")
-- Try to load snacks.nvim safely
local has_snacks, snacks = pcall(require, "snacks")
if not has_snacks then
	vim.notify("snacks.nvim not found; falling back to inline expansion for transclusions", vim.log.levels.WARN)
end

local M = {}

-- Will hold the actual configuration after setup
M.config = {}
-- Store parsed gitignore patterns
M.gitignore_patterns = nil

-- Setup function to initialize the plugin with user configuration
function M.setup(opts)
	-- Apply and validate config
	M.config = config.apply(opts)

	-- Disable snacks integration if the plugin is not available
	if not has_snacks and M.config.use_snacks then
		M.config.use_snacks = false
		vim.notify("snacks.nvim is required for floating window transclusions but was not found", vim.log.levels.WARN)
	end

	-- Setup highlight groups
	config.setup_highlights()
	
	-- Load gitignore patterns if configured
	if M.config.respect_gitignore then
		M.load_gitignore_patterns()
	end

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

-- Function to load and parse .gitignore patterns
function M.load_gitignore_patterns()
	-- Find git root directory
	local git_root = vim.fn.fnamemodify(vim.fn.finddir('.git', '.;'), ':h')
	local gitignore_path = git_root .. '/.gitignore'
	
	if vim.fn.filereadable(gitignore_path) ~= 1 then
		print("No .gitignore file found at: " .. gitignore_path)
		M.gitignore_patterns = {}
		return
	end
	
	print("Loading .gitignore patterns from: " .. gitignore_path)
	local file = io.open(gitignore_path, "r")
	if not file then
		print("Failed to open .gitignore file")
		M.gitignore_patterns = {}
		return
	end
	
	local patterns = {}
	for line in file:lines() do
		-- Skip empty lines and comments
		if line ~= "" and not line:match("^%s*#") then
			-- Trim whitespace
			line = line:gsub("^%s*(.-)%s*$", "%1")
			-- Convert glob patterns to Lua patterns
			local lua_pattern = line:gsub("%.", "%%.")
									  :gsub("%*%*", ".*")
									  :gsub("%*", "[^/]*")
									  :gsub("%?", ".")
			table.insert(patterns, lua_pattern)
		end
	end
	
	file:close()
	M.gitignore_patterns = patterns
	print("Loaded " .. #patterns .. " .gitignore patterns")
end

-- Function to check if a path should be ignored
function M.should_ignore_path(path)
	-- Check against explicitly ignored folders
	local path_components = vim.split(path, "/")
	local dir_name = path_components[#path_components]
	
	-- Check if the directory is in the ignore_folders list
	for _, ignored_folder in ipairs(M.config.ignore_folders) do
		if dir_name == ignored_folder then
			print("Ignoring directory (in ignore_folders): " .. path)
			return true
		end
	end
	
	-- Check against gitignore patterns if enabled
	if M.config.respect_gitignore and M.gitignore_patterns then
		-- Get the relative path from the notes_dir
		local relative_path = path
		if path:sub(1, #M.config.notes_dir) == M.config.notes_dir then
			relative_path = path:sub(#M.config.notes_dir + 2) -- +2 to account for the trailing slash
		end
		
		for _, pattern in ipairs(M.gitignore_patterns) do
			if relative_path:match(pattern) then
				print("Ignoring path (matched gitignore pattern): " .. path)
				return true
			end
		end
	end
	
	return false
end

-- Find a note file by name
function M.find_note_file(name)
	-- Debug info
	print("\n=== FINDING NOTE FILE ===")
	print("Looking for note: '" .. name .. "'")
	print("Notes directory: '" .. M.config.notes_dir .. "'")
	print("Valid extensions: " .. table.concat(M.config.valid_extensions, ", "))

	-- First try with the name as-is
	local direct_path = M.config.notes_dir .. "/" .. name
	print("Trying direct path: " .. direct_path)
	if vim.fn.filereadable(direct_path) == 1 then
		print("✓ Found direct match: " .. direct_path)
		return direct_path
	else
		print("✗ File not found at direct path")
	end

	-- Try with each valid extension
	for _, ext in ipairs(M.config.valid_extensions) do
		local path_with_ext = M.config.notes_dir .. "/" .. name .. "." .. ext
		print("Trying path with extension: " .. path_with_ext)
		if vim.fn.filereadable(path_with_ext) == 1 then
			print("✓ Found with extension: " .. path_with_ext)
			return path_with_ext
		else
			print("✗ File not found with extension: " .. ext)
		end
	end

	-- Recursive search through subdirectories if enabled
	if M.config.recursive_search then
		print("Performing recursive search in: " .. M.config.notes_dir)
		local found_files = {}
		
		-- Function to search recursively
		local function search_dir(dir)
			local handle = vim.loop.fs_scandir(dir)
			if not handle then
				print("✗ Cannot scan directory: " .. dir)
				return
			end
			
			while true do
				local name_scan, type_scan = vim.loop.fs_scandir_next(handle)
				if not name_scan then 
					break 
				end
				
				local path = dir .. "/" .. name_scan
				
				if type_scan == "directory" then
					-- Skip if this directory should be ignored
					if not M.should_ignore_path(path) then
						print("Searching subdirectory: " .. path)
						search_dir(path)
					end
				elseif type_scan == "file" then
					-- Check if file matches the name we're looking for
					local file_base = vim.fn.fnamemodify(name_scan, ":r")
					local file_ext = vim.fn.fnamemodify(name_scan, ":e")
					
					if file_base == name and vim.tbl_contains(M.config.valid_extensions, file_ext) then
						print("✓ Found matching file: " .. path)
						table.insert(found_files, path)
					end
				end
			end
		end
		
		search_dir(M.config.notes_dir)
		
		-- Return the first matching file if any found
		if #found_files > 0 then
			print("✓ Found in subdirectory: " .. found_files[1])
			return found_files[1]
		else
			print("✗ No files found in recursive search")
		end
		
		-- If multiple files found, log a warning
		if #found_files > 1 then
			print("⚠ Multiple matching files found: " .. #found_files)
			for i, file in ipairs(found_files) do
				print("  " .. i .. ": " .. file)
			end
		end
	else
		print("Recursive search is disabled")
	end

	-- Last resort: Check if the notes_dir is accessible
	if vim.fn.isdirectory(M.config.notes_dir) ~= 1 then
		print("⚠ Notes directory does not exist or is not accessible: " .. M.config.notes_dir)
	end

	-- Not found
	print("✗ Note not found: " .. name)
	print("=== SEARCH COMPLETE ===\n")
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
	
	-- Print debug information
	print("Rendering transclusions in buffer: " .. bufnr)

	-- Get all lines in the buffer
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local transclusions = {}
	local count = 0

	-- Find all transclusion markers
	for i, line in ipairs(lines) do
		local start_idx, end_idx, note_name, section_name = line:find(M.config.transclusion_pattern)

		if start_idx then
			count = count + 1
			note_name = note_name:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
			section_name = section_name and section_name:gsub("^%s*(.-)%s*$", "%1") or nil -- Trim whitespace
			
			table.insert(transclusions, {
				line_idx = i - 1, -- 0-indexed for API
				start_idx = start_idx,
				end_idx = end_idx,
				note_name = note_name,
				section_name = section_name,
			})
			
			print(string.format("Found transclusion #%d at line %d: %s%s", 
				count, i, note_name, section_name and " (section: " .. section_name .. ")" or ""))
		end
	end
	
	print("Found " .. count .. " transclusions")

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
						virt_text = { { virtual_text, "ObsidianTransclusionVirtualText" } },
						virt_text_pos = "eol",
					})
					
					print("Added virtual text for " .. t.note_name)
				end

				-- Highlight the different parts of the transclusion marker
				
				-- Highlight the ![[
				vim.api.nvim_buf_add_highlight(
					bufnr,
					namespace,
					"ObsidianTransclusionMarker",
					t.line_idx,
					t.start_idx - 1,
					t.start_idx + 2
				)
				
				-- Highlight the note_name (and section if any)
				vim.api.nvim_buf_add_highlight(
					bufnr,
					namespace,
					"ObsidianTransclusionPath",
					t.line_idx,
					t.start_idx + 2,
					t.end_idx - 2
				)
				
				-- Highlight the closing ]]
				vim.api.nvim_buf_add_highlight(
					bufnr,
					namespace,
					"ObsidianTransclusionMarker",
					t.line_idx,
					t.end_idx - 2,
					t.end_idx
				)
				
				print("Applied highlighting for transclusion at line " .. (t.line_idx + 1))
			else
				-- File exists but couldn't read content
				if M.config.show_warnings then
					vim.api.nvim_buf_add_highlight(
						bufnr,
						namespace,
						"ObsidianTransclusionWarning",
						t.line_idx,
						0,
						-1
					)
				end
			end
		else
			-- File not found
			if M.config.show_warnings then
				vim.api.nvim_buf_add_highlight(
					bufnr,
					namespace,
					"ObsidianTransclusionWarning",
					t.line_idx,
					0,
					-1
				)
				
				-- Add warning as virtual text
				vim.api.nvim_buf_set_extmark(bufnr, namespace, t.line_idx, 0, {
					virt_text = { { " Note not found: " .. t.note_name, "ObsidianTransclusionWarning" } },
					virt_text_pos = "eol",
				})
			end
		end
	end
	
	print("Render complete - processed " .. #transclusions .. " transclusions")
end

-- Preview transclusion in a floating window
function M.preview_transclusion()
	print("\n=== PREVIEW TRANSCLUSION ===")
	local line = vim.api.nvim_get_current_line()
	print("Current line: " .. line)

	local start_idx, end_idx, note_name, section_name = line:find(M.config.transclusion_pattern)

	if not start_idx then
		vim.notify("No transclusion found on current line", vim.log.levels.INFO)
		print("No transclusion found on current line")
		return
	end

	note_name = note_name:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
	print("Previewing note: " .. note_name .. (section_name and (" section: " .. section_name) or ""))
	
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

	-- Create a more visually appealing floating window
	
	-- Split content into lines and remove trailing empty lines
	local lines = vim.split(content, "\n")
	while #lines > 0 and lines[#lines] == "" do
		table.remove(lines)
	end
	
	-- Calculate window dimensions
	local width = 80
	for _, line in ipairs(lines) do
		width = math.max(width, #line + 4) -- Add padding
	end
	width = math.min(width, 120) -- Cap maximum width
	
	local height = math.min(#lines + 2, 20) -- Cap maximum height
	
	-- Position window near the cursor
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local row = cursor_pos[1]
	local col = cursor_pos[2]
	
	-- Create title
	local title = " " .. note_name .. " "
	if section_name then
		title = title .. "(section: " .. section_name .. ") "
	end
	
	-- Create the buffer for our floating window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	
	-- Set buffer options
	vim.api.nvim_buf_set_option(buf, 'modifiable', false)
	vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
	
	-- Calculate position (centered, slightly below cursor)
	local win_height = vim.api.nvim_get_option("lines")
	local win_width = vim.api.nvim_get_option("columns")
	
	local win_opts = {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((win_width - width) / 2),
		row = math.floor(row - 3 + (win_height - height) / 3),
		style = "minimal",
		border = "rounded",
		title = title,
		title_pos = "center"
	}
	
	-- Create floating window
	local win = vim.api.nvim_open_win(buf, false, win_opts)
	
	-- Set window highlight
	vim.api.nvim_win_set_option(win, 'winhighlight', 'Normal:Pmenu,FloatBorder:PmenuSel')
	
	-- Add markdown syntax highlighting to the buffer
	vim.api.nvim_buf_set_option(buf, 'syntax', 'markdown')
	
	-- Add keymappings to close the window
	vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { noremap = true, silent = true })
	
	-- Create an autocommand to close the preview when cursor moves
	local preview_augroup = vim.api.nvim_create_augroup("ObsidianTransclusionPreview", { clear = true })
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = preview_augroup,
		buffer = vim.api.nvim_get_current_buf(),
		callback = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
				vim.api.nvim_del_augroup_by_id(preview_augroup)
			end
		end,
		once = true
	})
	
	print("Opened preview window")
	print("=== PREVIEW COMPLETE ===\n")
end

-- Function to expand a transclusion in place
function M.expand_transclusion()
	print("\n=== EXPANDING TRANSCLUSION ===")
	local bufnr = vim.api.nvim_get_current_buf()
	local line_idx = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed
	local line = vim.api.nvim_get_current_line()
	print("Current line: " .. line)

	local start_idx, end_idx, note_name, section_name = line:find(M.config.transclusion_pattern)
	
	if not start_idx then
		print("No transclusion found on current line")
		vim.notify("No transclusion found on current line", vim.log.levels.INFO)
		return
	end
	
	print("Pattern match found: " .. start_idx .. "-" .. end_idx)
	print("Note name: " .. note_name .. (section_name and (", Section: " .. section_name) or ""))

	note_name = note_name:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
	local file_path = M.find_note_file(note_name)
	print("Looking for file: " .. note_name)
	print("Full path: " .. (file_path or "file not found"))

	if not file_path then
		vim.notify("Note '" .. note_name .. "' not found", vim.log.levels.WARN)
		return
	end

	local content = M.read_file_contents(file_path)

	if not content then
		print("Failed to read content from " .. file_path)
		vim.notify("Failed to read content of '" .. note_name .. "'", vim.log.levels.ERROR)
		return
	end
	
	print("Read " .. #content .. " bytes from " .. file_path)

	-- Extract the specified section if any
	if section_name then
		print("Extracting section: " .. section_name)
		content = M.extract_section(content, section_name)
		print("Extracted section content: " .. #content .. " bytes")
	end

	-- Split the content into lines
	local content_lines = vim.split(content, "\n")
	print("Content split into " .. #content_lines .. " lines")
	
	-- Check if we should use snacks.nvim
	if M.config.use_snacks then
		-- Create title for the window
		local title = note_name
		if section_name then
			title = title .. " > " .. section_name
		end
		
		-- Merge default window options with user config
		local win_opts = vim.tbl_deep_extend("force", M.config.snacks_window or {}, {
			title = title,
			width = math.min(M.config.snacks_window.width or 120, vim.o.columns - 10),
			height = math.min(math.min(#content_lines + 2, M.config.snacks_window.height or 20), vim.o.lines - 10),
		})
		
		-- Display the expanded content in a snacks window
		local win = snacks.win(content_lines, {
			filetype = "markdown",
			mappings = {
				n = {
					-- Close the window with q or Escape
					["q"] = function(w) snacks.close(w) end,
					["<Esc>"] = function(w) snacks.close(w) end,
					
					-- Allow replacing the current line with the expanded content
					["<CR>"] = function(w)
						M.expand_in_place(bufnr, line_idx, line, start_idx, end_idx, note_name, content_lines)
						snacks.close(w)
					end
				}
			}
		}, win_opts)
		
		-- Create a footer with instructions
		vim.api.nvim_buf_set_lines(win.buf, -1, -1, false, {
			"",
			"Press <CR> to expand in-place, q or <Esc> to close"
		})
		
		-- Highlight the footer as a comment
		local ns_id = vim.api.nvim_create_namespace("markdown_transclusion_snacks")
		vim.api.nvim_buf_add_highlight(win.buf, ns_id, "Comment", #content_lines + 1, 0, -1)
		vim.api.nvim_buf_add_highlight(win.buf, ns_id, "Comment", #content_lines + 2, 0, -1)

		vim.notify("Expanded transclusion of '" .. note_name .. "' in a window", vim.log.levels.INFO)
	else
		-- Use the original expand in place behavior
		M.expand_in_place(bufnr, line_idx, line, start_idx, end_idx, note_name, content_lines)
	end
	
	print("=== EXPANSION COMPLETE ===\n")
end

-- Helper function to expand a transclusion in place
function M.expand_in_place(bufnr, line_idx, line, start_idx, end_idx, note_name, content_lines)
	-- Get leading whitespace
	local leading_whitespace = line:match("^%s*") or ""
	
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
	
	vim.notify("Expanded transclusion of '" .. note_name .. "' in-place", vim.log.levels.INFO)
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
