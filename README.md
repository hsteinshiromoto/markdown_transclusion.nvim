# markdown_transclusion.nvim

A Neovim plugin that implements Obsidian-style transclusion functionality for Markdown files.

## Features

- Obsidian-compatible transclusion syntax (`![[file_name]]`)
- Live preview in a floating window
- Nested transclusions support
- Auto-update on cursor hold
- Configurable display options

## Requirements

- Neovim >= 0.7.0
- [snacks.nvim](https://github.com/creativenull/snacks.nvim) for the floating window functionality

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'hsteinshiromoto/markdown_transclusion.nvim',
  dependencies = { 'creativenull/snacks.nvim' },
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
  requires = { 'creativenull/snacks.nvim' },
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
  win_options = {              -- snacks.nvim window options
    relative = 'editor',
    width = 80,
    height = 20,
    row = 2, 
    col = 120,
    border = 'rounded',
    title = 'Transclusion Preview',
    title_pos = 'center',
  },
  format = {
    link_pattern = '!%[%[(.-)%]%]', -- Regex pattern for transclusion links
    max_depth = 3,            -- Maximum depth for nested transclusions
  },
})
```

## License

MIT
