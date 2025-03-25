-- tests/test_init.lua
-- Test for markdown transclusion

-- Mock vim global to allow testing outside of Neovim
_G.vim = {
    fn = {
        fnamemodify = function(path, mod)
            return "/tmp"  -- Mock return value
        end,
        finddir = function(dir, path)
            return "."     -- Mock return value
        end,
        expand = function(path)
            return path:gsub("^~", "/home/user")  -- Mock expand
        end
    },
    notify = function(msg, level)
        print("NOTIFY: " .. msg)
    end,
    log = {
        levels = {
            INFO = "INFO",
            WARN = "WARN",
            ERROR = "ERROR"
        }
    }
}

-- Add our pattern test function
local function test_pattern(pattern, str)
    print("Testing: " .. str)
    local matches = {str:find(pattern)}
    
    if #matches > 0 then
        print("  Match found!")
        print("  Start index: " .. matches[1])
        print("  End index: " .. matches[2])
        for i = 3, #matches do
            print("  Capture " .. (i-2) .. ": " .. (matches[i] or "nil"))
        end
    else
        print("  No match found")
    end
    print("")
end

-- Import markdown_transclusion pattern
package.path = "../lua/?.lua;" .. package.path
local config = require("markdown_transclusion.config")

-- Test the pattern
local pattern = config.defaults.transclusion_pattern
print("Testing pattern: " .. pattern)

-- Test with various transclusion formats
local test_strings = {
    "![[test]]",
    "![[test#section]]",
    "Some text ![[test]] more text",
    "Some text ![[test#section]] more text"
}

for _, str in ipairs(test_strings) do
    test_pattern(pattern, str)
end 