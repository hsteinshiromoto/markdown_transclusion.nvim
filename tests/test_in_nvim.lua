-- tests/test_in_nvim.lua
-- To run in Neovim: source this file with :source tests/test_in_nvim.lua

-- Add our test markdown file to the current buffer
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "# Test Markdown File",
    "",
    "This is a test file to verify transclusions.",
    "",
    "![[test]]",
    "",
    "![[test#Test Section]]"
})

-- Set the buffer filetype
vim.cmd('set filetype=markdown')

-- Now test our plugin
require('markdown_transclusion').setup({
    -- Override the notes directory to use our local tests/testnotes/ folder
    notes_dir = vim.fn.getcwd() .. '/tests/testnotes',
    
    -- Enable debug messages
    show_warnings = true,
    virtual_text_enabled = true
})

-- Manually render transclusions
require('markdown_transclusion').render_transclusions()

-- Print instructions for testing
print("-------------------------------------")
print("Test instructions:")
print("1. Move cursor to line 5 (![[test]])")
print("2. Press 'gp' to preview the transclusion")
print("3. Press 'ge' to expand the transclusion")
print("4. Move cursor to line 7 (![[test#Test Section]])")
print("5. Press 'gp' to preview the transclusion with section")
print("6. Press 'ge' to expand the transclusion with section")
print("-------------------------------------")