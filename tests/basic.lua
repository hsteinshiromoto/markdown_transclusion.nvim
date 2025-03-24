-- tests/basic.lua
-- Basic tests for obsidian-transclusion plugin
-- Run with :luafile tests/basic.lua

local M = {}

-- Create test environment
function M.setup_test_env()
	-- Create temporary test directory
	local test_dir = vim.fn.tempname()
	vim.fn.mkdir(test_dir)

	-- Create some test files
	local files = {
		["test1.md"] = "# Test File 1\n\nThis is test file 1.",
		["test2.md"] = "# Test File 2\n\nThis is test file 2.",
		["main.md"] = "# Main Test Document\n\n## Test Section 1\n![[test1]]\n\n## Test Section 2\n![[test2]]\n\n## Missing File\n![[nonexistent]]",
	}

	for filename, content in pairs(files) do
		local file = io.open(test_dir .. "/" .. filename, "w")
		file:write(content)
		file:close()
	end

	return test_dir
end

-- Clean up test environment
function M.cleanup_test_env(test_dir)
	local files = vim.fn.glob(test_dir .. "/*.md")
	for file in string.gmatch(files, "[^\n]+") do
		vim.fn.delete(file)
	end
	vim.fn.delete(test_dir)
end

-- Run basic functionality tests
function M.run_tests()
	print("Starting obsidian-transclusion tests...")

	-- Setup test environment
	local test_dir = M.setup_test_env()
	print("Created test directory: " .. test_dir)

	-- Setup plugin with test configuration
	local obsidian = require("obsidian-transclusion")
	obsidian.setup({
		notes_dir = test_dir,
		valid_extensions = { "md" },
		update_on_save = true,
	})

	-- Open the main test file
	vim.cmd("edit " .. test_dir .. "/main.md")

	-- Allow autocommands to run
	vim.cmd("doautocmd BufReadPost")

	-- Print status
	print("\nTest setup complete!")
	print("The test file is now open with transclusions.")
	print("You should see:")
	print("1. Highlighted transclusion markers for test1 and test2")
	print("2. Virtual text showing the source files")
	print("3. A warning for the nonexistent file")
	print("\nTry these commands:")
	print("- Place cursor on ![[test1]] and press 'gp' to preview")
	print("- Place cursor on ![[test2]] and press 'ge' to expand")
	print("- Run :ObsidianToggleVirtualText to toggle virtual text")
	print("\nClean up test with :lua require('tests.basic').cleanup_test_env('" .. test_dir .. "')")
end

-- Register the test function to make it easier to run
_G.ObsidianTransclusionTest = M.run_tests

print("Obsidian Transclusion Test loaded.")
print("Run test with :lua _G.ObsidianTransclusionTest()")

return M
