# markdown_transclusion.nvim

A Neovim plugin that implements Obsidian-style transclusion functionality for Markdown files.

## Features

- Obsidian-compatible transclusion syntax (`![[file_name]]`)
- Optional integration with obsidian.nvim for vault-aware path resolution
- Live preview in a floating window
- Nested transclusions support
- Auto-update on cursor hold
- Configurable display options

## Requirements

- Neovim >= 0.7.0
- [snacks.nvim](https://github.com/creativenull/snacks.nvim) (optional, will fall back to built-in floating windows)
- [obsidian.nvim](https://github.com/epwalsh/obsidian.nvim) (optional) for enhanced Obsidian vault integration

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'hsteinshiromoto/markdown_transclusion.nvim',
  dependencies = { 
    'creativenull/snacks.nvim',
    -- Optional: include obsidian.nvim for enhanced vault integration
    'epwalsh/obsidian.nvim',
  },
  ft = { 'markdown' },
  config = function()
    require('markdown_transclusion').setup({
      -- Optional configuration
    })
  end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'hsteinshiromoto/markdown_transclusion.nvim',
  requires = { 
    'creativenull/snacks.nvim',
    -- Optional: include obsidian.nvim for enhanced vault integration
    'epwalsh/obsidian.nvim',
  },
  config = function()
    require('markdown_transclusion').setup()
  end
}
```

## Usage

1. Place transclusion links in your Markdown files using the syntax: `![[path/to/file]]`
2. Use the provided commands to toggle the preview window:
   - `:MarkdownTransclusionToggle` - Toggle the preview window
   - `:MarkdownTransclusionUpdate` - Update the preview content

Default keymaps:
- `<leader>mt` - Toggle transclusion preview
- `<leader>mu` - Update transclusion preview

## Configuration

```lua
require('markdown_transclusion').setup({
  auto_update = true,          -- Update preview on cursor hold
  auto_open = false,           -- Auto-open preview when entering markdown buffer
  auto_close = false,          -- Auto-close preview when leaving markdown buffer
  set_keymaps = true,          -- Set default keymaps
  keymaps = {
    toggle = '<leader>mt',     -- Toggle preview window
    update = '<leader>mu',     -- Update preview content
  },
  -- Obsidian.nvim integration
  use_obsidian = true,        -- Enable integration with obsidian.nvim
  win_options = {             -- Window options (used by both snacks.nvim and built-in floating windows)
    relative = 'editor',
    width = 80,
    height = 20,
    row = 2, 
    col = 120,
    border = 'rounded',
    title = 'Transclusion Preview',
    title_pos = 'center',     -- Only used by snacks.nvim
  },
  format = {
    link_pattern = '!%[%[(.-)%]%]', -- Regex pattern for transclusion links
    max_depth = 3,                 -- Maximum depth for nested transclusions
    link_prefix = '## ',           -- Prefix for the linked title when using obsidian integration
  },
})
```

### Obsidian Integration

When `use_obsidian` is enabled and obsidian.nvim is installed, the plugin will:

1. Use obsidian.nvim's path resolution to find files within your vault
2. Create proper obsidian links (`[[file]]`) in the preview window
3. Use note titles from your vault when available
4. Work with Obsidian's link format and file structure

## License

MIT
