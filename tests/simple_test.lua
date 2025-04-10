-- Simple test for markdown_transclusion.nvim
local mock_path = '/Users/hsteinshiromoto/Projects/markdown_transclusion.nvim/test_deps/markdown_test_files'

describe('Markdown Transclusion', function()
  it('loads the module', function()
    local ok, module = pcall(require, 'markdown_transclusion')
    assert.truthy(ok)
    assert.truthy(module)
  end)
  
  it('loads the config module', function()
    local ok, config = pcall(require, 'markdown_transclusion.config')
    assert.truthy(ok)
    assert.truthy(config)
  end)
  
  it('loads the utils module', function()
    local ok, utils = pcall(require, 'markdown_transclusion.utils')
    assert.truthy(ok)
    assert.truthy(utils)
  end)
  
  it('loads the preview module', function()
    local ok, preview = pcall(require, 'markdown_transclusion.preview')
    assert.truthy(ok)
    assert.truthy(preview)
  end)
end)