# Obsidian Transclusion for Neovim

A Neovim plugin that brings Obsidian-style transclusion functionality to your markdown files. This plugin allows you to include the contents of one note within another using the familiar `![[note]]` syntax, with support for transcluding specific sections using headers.

## Features

- ✨ **Automatic Detection**: Recognizes Obsidian-style `![[note]]` transclusion syntax
- 📑 **Section Transclusion**: Include specific sections of notes using `![[note#section]]` syntax
- 🎨 **Visual Indicators**: Highlights transclusion markers and adds virtual text showing the source
- 👁️ **Preview**: Quickly preview transcluded content in a floating window without leaving your current file
- 📝 **Expansion**: Expand transclusions in-place when you need the actual content
- ⚠️ **Warnings**: Visual indicators for missing files
- 🔄 **Auto-update**: Transclusions are automatically rendered when opening and saving files

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "hsteinshiromoto/markdown_transclusion.nvim",
  ft = { "markdown", "md" },
  config = function()
    require("markdown_transclusion").setup({
      notes_dir = vim.fn.expand("~/Notes"),
      -- Additional options (see Configuration section)
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "hsteinshiromoto/markdown_transclusion.nvim",
  config = function()
    require("markdown_transclusion").setup({
      notes_dir = vim.fn.expand("~/Notes"),
    })
  end
}
```

### Manual Installation

Clone the repository and add it to your runtimepath:

```bash
git clone https://github.com/hsteinshiromoto/markdown_transclusion.nvim ~/.config/nvim/pack/plugins/start/markdown_transclusion.nvim
```

Then initialize the plugin in your `init.lua`:

```lua
require("markdown_transclusion").setup({
  notes_dir = vim.fn.expand("~/Notes"),
})
```

## Usage

### Basic Usage

1. Create markdown notes with the extension `.md` or `.markdown`
2. Use the Obsidian-style syntax to transclude content:
   - Transclude entire file: `![[note-name]]`
   - Transclude specific section: `![[note-name#section-name]]`
3. The plugin will automatically highlight these transclusions and add virtual text

### Section Transclusion

You can transclude specific sections of a markdown file by adding a `#` followed by the section name after the note name. The section name should match exactly with the header in the markdown file.

For example, if you have a file `note.md`:
```markdown
# Introduction
Some intro text...

# Main Content
Main content here...

## Subsection
More content...
```

You can transclude just the main content section using:
```markdown
![[note#Main Content]]
```

The plugin will extract everything from the "Main Content" header up to (but not including) the next header of the same or higher level. In this case, it would include the "Subsection" content as well since it's a lower-level header.

### Key Mappings

- `gp`: Preview the transcluded content in a floating window
- `ge`: Expand the transclusion in place (replaces the marker with actual content)

### Commands

- `:ObsidianRenderTransclusions`: Manually refresh all transclusions
- `:ObsidianToggleVirtualText`: Toggle the virtual text indicators

## Configuration

Here are all available configuration options with their default values:

```lua
require("markdown_transclusion").setup({
  -- Base directory for notes (default: current working directory)
  notes_dir = vim.fn.getcwd(),

  -- File extensions to consider for transclusion
  valid_extensions = { "md", "markdown" },

  -- Pattern to identify transclusion syntax (supports section transclusion)
  transclusion_pattern = "!%[%[([^#]*)#?([^%]]*)%]%]",

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
vim.g.markdown_transclusion_no_default_keymaps = true

-- Setup the plugin
require("markdown_transclusion").setup({
  -- Your config here
})

-- Define your own keymaps
vim.api.nvim_set_keymap('n', '<leader>op', '<cmd>lua require("markdown_transclusion").preview_transclusion()<CR>',
  { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>oe', '<cmd>lua require("markdown_transclusion").expand_transclusion()<CR>',
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

## Writing Projects
- Write a technical blog post
- Create documentation
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
![[ProjectIdeas#Programming Projects]]

## This Week's Goals
![[WeeklyGoals]]
```

When you open `MainNote.md` in Neovim, the plugin will:
- Highlight the transclusion markers
- Add virtual text showing the source files and sections
- Allow you to preview or expand the content on demand

## Testing

The plugin includes several test files in the `tests/` directory:

- `pattern_test.lua`: Tests different Lua patterns for matching transclusions
- `test_init.lua`: Tests pattern matching with the configured pattern
- `test_in_nvim.lua`: Provides an interactive test in Neovim with instructions
- `debug.lua`: Debugging script for testing plugin functions
- `basic.lua`: Basic test environment setup

To run the interactive test, open Neovim and execute:
```
:source tests/test_in_nvim.lua
```

This will set up a test environment with sample transclusion syntax and guide you through testing the preview and expand functionality.

## Troubleshooting

If the transclusion doesn't work as expected:

1. Ensure your pattern syntax is correct. The plugin uses Lua patterns, not regular expressions.
   - The pattern `!%[%[([^#]*)#?([^%]]*)%]%]` properly captures both note names and section names.
   - Note that Lua patterns do not support the `(?:...)` non-capturing group syntax found in other regex implementations.
2. Check if the `notes_dir` is correctly set and the files exist in that directory.
3. Make sure your transclusions follow the format `![[note]]` or `![[note#Section]]`.
4. Use the debug tools in `tests/debug.lua` to check pattern matching.

### Common Issues

- **"No transclusion found on current line"**: This error often appears when pressing `gp` or `ge` if the pattern matching is not working. Make sure your transclusion pattern is correctly set.
- **File not found**: Make sure your note file exists in the configured `notes_dir` directory. Check the debug logs for the exact path being searched.

## Screenshots

![Plugin in action](screenshots/example.png)

## License

MIT
