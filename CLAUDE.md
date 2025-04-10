# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Test/Lint Commands
- Run tests: `nvim --headless -u tests/minimal_init.lua -c "lua require('plenary.test_harness').test_directory('tests')" -c "quit"`
- Run a single test: `nvim --headless -u tests/minimal_init.lua -c "lua require('plenary.test_harness').test_directory('tests/transclusion_spec.lua')" -c "quit"`
- Lint code: `luacheck lua/ plugin/`
- Format code: `stylua lua/ plugin/`

## Code Style Guidelines
- Use 2-space indentation
- Line length: max 100 characters
- Module imports: `local module = require('module_name')`
- Functions: `snake_case` for all functions
- Variables: `snake_case` for local variables
- Error handling: Use `pcall` for error capturing
- Return errors rather than raising where possible
- Use type annotations with EmmyLua: `---@param name type` 
- Place imports at the top of files, followed by module constants
- Keep functions small and focused on a single responsibility
- Transclusion pattern follows Obsidian format: ![[file]]