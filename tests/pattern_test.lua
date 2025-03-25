-- tests/pattern_test.lua
-- Test script for Lua pattern matching

-- Test patterns
local patterns = {
    "!%[%[(.-)(#(.-))?%]%]",      -- Current pattern
    "!%[%[(.-)%]%]",               -- Simple pattern without section
    "!%[%[([^#]*)#?([^%]]*)%]%]", -- Pattern with explicit section handling
    "!%[%[([^%]]+)%]%]",           -- Just note name
    "!%[%[([^#%]]+)(#([^%]]+))?%]%]" -- Alternative with better optional group
}

-- Test strings
local test_strings = {
    "![[test]]",
    "![[test#section]]",
    "Some text ![[test]] more text",
    "Some text ![[test#section]] more text",
    "![[test with spaces]]",
    "![[test with spaces#section with spaces]]"
}

-- Function to print match results
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

-- Test each pattern against each string
for i, pattern in ipairs(patterns) do
    print("=== Testing pattern " .. i .. ": " .. pattern .. " ===\n")
    for _, str in ipairs(test_strings) do
        test_pattern(pattern, str)
    end
    print("\n")
end 