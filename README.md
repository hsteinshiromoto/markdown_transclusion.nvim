# Obsidian Transclusion for Neovim

A Neovim plugin that brings Obsidian-style transclusion functionality to your markdown files. This plugin allows you to include the contents of one note within another using the familiar `![[note]]` syntax.

## Features

- ✨ **Automatic Detection**: Recognizes Obsidian-style `![[note]]` transclusion syntax
- 🎨 **Visual Indicators**: Highlights transclusion markers and adds virtual text showing the source
- 👁️ **Preview**: Quickly preview transcluded content in a floating window without leaving your current file
- 📝 **Expansion**: Expand transclusions in-place when you need the actual content
- ⚠️ **Warnings**: Visual indicators for missing files
- 🔄 **Auto-update**: Transclusions are automatically rendered when opening and saving files

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "username/obsidian-transclusion.nvim",
  ft = { "markdown", "md" },
  config = function()
    require("obsidian-transclusion").setup({
      notes_dir = vim.fn.expand("~/Notes"),
      -- Additional options (see Configuration section)
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "username/obsidian-transclusion.nvim",
  config = function()
    require("obsidian-transclusion").setup({
      notes_dir = vim.fn.expand("~/Notes"),
    })
  end
}
```

### Manual Installation

Clone the repository and add it to your runtimepath:

```bash
git clone https://github.com/username/obsidian-transclusion.nvim ~/.config/nvim/pack/plugins/start/obsidian-transclusion.nvim
```

Then initialize the plugin in your `init.lua`:

```lua
require("obsidian-transclusion").setup({
  notes_dir = vim.fn.expand("~/Notes"),
})
```

## Usage

### Basic Usage

1. Create markdown notes with the extension `.md` or `.markdown`
2. Use the Obsidian-style syntax to transclude content: `![[note-name]]`
3. The plugin will automatically highlight these transclusions and add virtual text

### Key Mappings

- `gp`: Preview the transcluded content in a floating window
- `ge`: Expand the transclusion in place (replaces the marker with actual content)

### Commands

- `:ObsidianRenderTransclusions`: Manually refresh all transclusions
- `:ObsidianToggleVirtualText`: Toggle the virtual text indicators

## Configuration

Here are all available configuration options with their default values:

```lua
require("obsidian-transclusion").setup({
  -- Base directory for notes (default: current working directory)
  notes_dir = vim.fn.getcwd(),

  -- File extensions to consider for transclusion
  valid_extensions = { "md", "markdown" },

  -- Pattern to identify transclusion syntax
  transclusion_pattern = "!%[%[(.-)%]%]",

  -- Virtual text to indicate transclusion
  virtual_text_enabled = true,
  virtual_text_hl_group = "Comment",

  -- Update transclusions when saving the file
  update_on_save = true,

  -- Show warnings for missing files
  show_warnings = true,
})
```

### Customizing Key Mappings

If you want to customize the default key mappings, you can do so after the setup:

```lua
-- Disable default keymaps
vim.g.obsidian_transclusion_no_default_keymaps = true

-- Setup the plugin
require("obsidian-transclusion").setup({
  -- Your config here
})

-- Define your own keymaps
vim.api.nvim_set_keymap('n', '<leader>op', '<cmd>lua require("obsidian-transclusion").preview_transclusion()<CR>',
  { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>oe', '<cmd>lua require("obsidian-transclusion").expand_transclusion()<CR>',
  { noremap = true, silent = true })
```

## Example

Suppose you have these files:

1. `~/Notes/ProjectIdeas.md`:
```markdown
# Project Ideas

## Programming Projects
- Create a markdown parser
- Build a personal knowledge base
```

2. `~/Notes/WeeklyGoals.md`:
```markdown
# Weekly Goals

1. Complete documentation
2. Review pull requests
```

3. `~/Notes/MainNote.md`:
```markdown
# Main Working Document

## Project Ideas Section
![[ProjectIdeas]]

## This Week's Goals
![[WeeklyGoals]]
```

When you open `MainNote.md` in Neovim, the plugin will:
- Highlight the transclusion markers
- Add virtual text showing the source files
- Allow you to preview or expand the content on demand

## Screenshots

![Plugin in action](screenshots/example.png)

## License

MIT
