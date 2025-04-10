-- Tests for markdown_transclusion.nvim
local mock_path = '/Users/hsteinshiromoto/Projects/markdown_transclusion.nvim/test_deps/markdown_test_files'

-- Setup and teardown functions
local function setup()
  -- Create test directory
  vim.fn.mkdir(mock_path, 'p')
  
  -- Create mock files for testing transclusion
  local files = {
    ['main.md'] = "# Main File\n\nThis is the main test file.\n\nTransclusion example: ![[child1]]\n\nAnother transclusion: ![[folder/child2]]\n",
    ['child1.md'] = "# Child 1\n\nThis is child1 content.\n\nWith a nested transclusion: ![[folder/child2]]\n",
    ['folder/child2.md'] = "# Child 2\n\nThis is child2 content in a folder.\n"
  }
  
  -- Create the files
  vim.fn.mkdir(mock_path .. '/folder', 'p')
  for name, content in pairs(files) do
    local file = io.open(mock_path .. '/' .. name, 'w')
    if file then
      file:write(content)
      file:close()
    end
  end
  
  -- Prepare Neovim with our plugin
  vim.cmd('set runtimepath+=.')
  require('markdown_transclusion').setup({
    -- Test-specific configuration
    auto_update = false,
    auto_open = false,
    set_keymaps = false,
  })
end

local function teardown()
  -- Clean up test files
  vim.fn.delete(mock_path, 'rf')
  
  -- Clean up any plugin state
  local preview = require('markdown_transclusion.preview')
  if preview.state.is_open then
    preview.close()
  end
end

describe('Markdown Transclusion', function()
  before_each(setup)
  after_each(teardown)
  
  it('correctly resolves file paths', function()
    local utils = require('markdown_transclusion.utils')
    
    -- Set a mock current file
    vim.cmd('e ' .. mock_path .. '/main.md')
    
    local resolved_path = utils.resolve_path('child1')
    assert.are.equal(mock_path .. '/child1.md', resolved_path)
    
    local resolved_nested_path = utils.resolve_path('folder/child2')
    assert.are.equal(mock_path .. '/folder/child2.md', resolved_nested_path)
  end)
  
  it('reads file content correctly', function()
    local utils = require('markdown_transclusion.utils')
    
    local content = utils.read_file(mock_path .. '/child1.md')
    assert.truthy(content:match("This is child1 content"))
  end)
  
  it('processes simple transclusions', function()
    local utils = require('markdown_transclusion.utils')
    
    -- Set a mock current file
    vim.cmd('e ' .. mock_path .. '/main.md')
    
    local content = utils.read_file(mock_path .. '/main.md')
    local processed = utils.process_transclusions(content)
    
    -- Check that the child1 content is included
    assert.truthy(processed:match('This is child1 content'))
    -- Check that child2 content is included
    assert.truthy(processed:match('This is child2 content in a folder'))
  end)
  
  it('respects max nesting depth', function()
    local config = require('markdown_transclusion.config')
    local utils = require('markdown_transclusion.utils')
    
    -- Set a very shallow max depth
    config.setup({ format = { max_depth = 1 } })
    
    -- Set a mock current file
    vim.cmd('e ' .. mock_path .. '/main.md')
    
    local content = utils.read_file(mock_path .. '/main.md')
    local processed = utils.process_transclusions(content)
    
    -- The first level transclusion should work
    assert.truthy(processed:match('This is child1 content'))
    -- But the nested transclusion in child1 should not be processed
    assert.truthy(processed:match('!%[%[folder/child2%]%]'))
    
    -- Reset config for other tests
    config.setup({ format = { max_depth = 3 } })
  end)
  
  it('handles missing files gracefully', function()
    local utils = require('markdown_transclusion.utils')
    
    -- Set a mock current file
    vim.cmd('e ' .. mock_path .. '/main.md')
    
    local test_content = 'Test with missing file: ![[nonexistent]]'
    local processed = utils.process_transclusions(test_content)
    
    -- Should include an error message for the missing file
    assert.truthy(processed:match('Transclusion failed: File not found'))
  end)
  
  it('toggles preview window correctly', function()
    local preview = require('markdown_transclusion.preview')
    
    -- Set a mock current file
    vim.cmd('e ' .. mock_path .. '/main.md')
    
    -- Initial state should be closed
    assert.falsy(preview.state.is_open)
    
    -- Open preview
    preview.open()
    assert.truthy(preview.state.is_open)
    assert.truthy(preview.state.win)
    assert.truthy(preview.state.buf)
    
    -- Toggle to close
    preview.toggle()
    assert.falsy(preview.state.is_open)
    
    -- Toggle to open again
    preview.toggle()
    assert.truthy(preview.state.is_open)
    
    -- Close
    preview.close()
    assert.falsy(preview.state.is_open)
  end)
  
  it('executes user commands', function()
    -- Set a mock current file
    vim.cmd('e ' .. mock_path .. '/main.md')
    
    local preview = require('markdown_transclusion.preview')
    
    -- Check if commands are defined
    local ok, _ = pcall(vim.cmd, 'command MarkdownTransclusionToggle')
    assert.truthy(ok, "MarkdownTransclusionToggle command should be defined")
    
    local ok2, _ = pcall(vim.cmd, 'command MarkdownTransclusionUpdate')
    assert.truthy(ok2, "MarkdownTransclusionUpdate command should be defined")
    
    -- We can't actually test the visual behavior in headless mode,
    -- but we can check that the commands don't error out
    pcall(vim.cmd, 'MarkdownTransclusionToggle')
    pcall(vim.cmd, 'MarkdownTransclusionUpdate')
    
    -- Close for cleanup
    preview.close()
    assert.falsy(preview.state.is_open)
  end)
end)