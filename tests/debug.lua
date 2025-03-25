-- tests/debug.lua
-- Test script for markdown_transclusion.nvim

-- Add the lua/ directory to the package path
package.path = "../lua/?.lua;" .. package.path

-- Load the plugin module
local mt = require("markdown_transclusion.init")

-- Initialize with default settings
mt.setup({})

-- Print the current configuration
print("Configuration:")
print("Notes directory: " .. mt.config.notes_dir)
print("Transclusion pattern: " .. mt.config.transclusion_pattern)

-- Test find_note_file function
local note_file = mt.find_note_file("test")
print("\nFind note file result:")
print("Looking for 'test'")
print("Result: " .. (note_file or "nil"))

-- Test pattern matching
local test_line = "Some text ![[test]] more text"
local start_idx, end_idx, note_name, section_part, section_name = test_line:find(mt.config.transclusion_pattern)
print("\nPattern matching test:")
print("Test line: " .. test_line)
print("Start index: " .. (start_idx or "nil"))
print("End index: " .. (end_idx or "nil"))
print("Note name: " .. (note_name or "nil"))
print("Section part: " .. (section_part or "nil"))
print("Section name: " .. (section_name or "nil"))

-- Test with section
local test_line2 = "Some text ![[test#Test Section]] more text"
local start_idx2, end_idx2, note_name2, section_part2, section_name2 = test_line2:find(mt.config.transclusion_pattern)
print("\nPattern matching test with section:")
print("Test line: " .. test_line2)
print("Start index: " .. (start_idx2 or "nil"))
print("End index: " .. (end_idx2 or "nil"))
print("Note name: " .. (note_name2 or "nil"))
print("Section part: " .. (section_part2 or "nil"))
print("Section name: " .. (section_name2 or "nil"))

-- Test reading file contents
if note_file then
    local content = mt.read_file_contents(note_file)
    print("\nFile contents:")
    print(content)
    
    -- Test section extraction if section_name2 is not nil
    if section_name2 then
        print("\nExtracted section:")
        local section_content = mt.extract_section(content, section_name2)
        print(section_content)
    end
end 