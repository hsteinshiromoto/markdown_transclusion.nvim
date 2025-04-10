local M = {}
local config = require('markdown_transclusion.config')
local utils = require('markdown_transclusion.utils')
local preview = require('markdown_transclusion.preview')

function M.setup(opts)
  config.setup(opts)
  
  -- Define the command to toggle preview
  vim.api.nvim_create_user_command('MarkdownTransclusionToggle', function()
    preview.toggle()
  end, { desc = 'Toggle markdown transclusion preview' })
  
  -- Define the command to update preview
  vim.api.nvim_create_user_command('MarkdownTransclusionUpdate', function()
    preview.update()
  end, { desc = 'Update markdown transclusion preview' })
  
  -- Setup autocommands
  local augroup = vim.api.nvim_create_augroup('MarkdownTransclusion', { clear = true })
  
  vim.api.nvim_create_autocmd('CursorHold', {
    group = augroup,
    pattern = '*.md',
    callback = function()
      if config.get().auto_update then
        preview.update()
      end
    end,
    desc = 'Auto-update markdown transclusion preview'
  })
  
  vim.api.nvim_create_autocmd('BufEnter', {
    group = augroup,
    pattern = '*.md',
    callback = function()
      if config.get().auto_open then
        preview.open()
      end
    end,
    desc = 'Auto-open markdown transclusion preview'
  })
  
  vim.api.nvim_create_autocmd('BufLeave', {
    group = augroup,
    pattern = '*.md',
    callback = function()
      if config.get().auto_close then
        preview.close()
      end
    end,
    desc = 'Auto-close markdown transclusion preview'
  })
  
  -- Setup keymaps if enabled
  if config.get().set_keymaps then
    local keymap_opts = { noremap = true, silent = true }
    vim.keymap.set('n', config.get().keymaps.toggle, '<cmd>MarkdownTransclusionToggle<CR>', keymap_opts)
    vim.keymap.set('n', config.get().keymaps.update, '<cmd>MarkdownTransclusionUpdate<CR>', keymap_opts)
  end
end

return M