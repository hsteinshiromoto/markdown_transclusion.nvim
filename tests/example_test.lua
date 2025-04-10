-- Example test for markdown_transclusion.nvim
-- This script processes the example files and shows the results

local function print_header(text)
  print(string.rep("=", 50))
  print(text)
  print(string.rep("=", 50))
end

local function init()
  -- Add plugin to runtimepath
  vim.opt.runtimepath:append(',/Users/hsteinshiromoto/Projects/markdown_transclusion.nvim')
  vim.opt.runtimepath:append(',/Users/hsteinshiromoto/Projects/markdown_transclusion.nvim/test_deps/snacks.nvim')
  
  -- Setup the plugin
  require('markdown_transclusion').setup()
end

local function test_example()
  local utils = require('markdown_transclusion.utils')
  local examples_path = '/Users/hsteinshiromoto/Projects/markdown_transclusion.nvim/examples'
  
  print_header("Testing Main Example File")
  
  -- Set current file to main.md
  vim.cmd('e ' .. examples_path .. '/main.md')
  
  -- Read and process transclusions
  local content = utils.read_file(examples_path .. '/main.md')
  local processed = utils.process_transclusions(content)
  
  -- Display results
  print("Original file content:")
  print(content)
  print("\nProcessed content with transclusions:")
  print(processed)
  
  -- Check for expected content
  local has_child1 = processed:match("Child Document 1") ~= nil
  local has_child2 = processed:match("Child Document 2") ~= nil
  local has_nested = processed:match("Code Examples") ~= nil
  
  print("\nTransclusion Results:")
  print("- Found Child1 content: " .. tostring(has_child1))
  print("- Found Child2 content: " .. tostring(has_child2))
  print("- Found nested content: " .. tostring(has_nested))
  
  print_header("Test Complete")
end

-- Run the example test
init()
test_example()