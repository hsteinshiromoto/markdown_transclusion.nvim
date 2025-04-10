local M = {}
local config = require('markdown_transclusion.config')
local utils = require('markdown_transclusion.utils')

-- Dependency check
local has_snacks, snacks = pcall(require, 'snacks')
if not has_snacks then
  utils.notify('This plugin requires snacks.nvim to be installed', 'error')
  return M
end

-- State management
M.state = {
  win = nil,
  buf = nil,
  is_open = false,
  current_file = nil,
}

---@param force_update boolean|nil Force update even if not open
function M.update(force_update)
  if not M.state.is_open and not force_update then 
    return 
  end
  
  local file_path = vim.fn.expand('%:p')
  
  -- Only update if different file or forced
  if M.state.current_file == file_path and not force_update then
    return
  end
  
  M.state.current_file = file_path
  
  local content = utils.read_file(file_path)
  
  if not content then
    utils.notify('Failed to read current file', 'error')
    return
  end
  
  -- Process transclusions
  local processed_content = utils.process_transclusions(content)
  
  -- Create buffer if needed
  if not M.state.buf or not vim.api.nvim_buf_is_valid(M.state.buf) then
    M.state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(M.state.buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(M.state.buf, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(M.state.buf, 'filetype', 'markdown')
  end
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, vim.split(processed_content, '\n'))
  
  -- Create window using snacks if needed
  if not M.state.win or not vim.api.nvim_win_is_valid(M.state.win) then
    M.state.win = snacks.win.create(M.state.buf, config.get().win_options)
  end
  
  M.state.is_open = true
end

function M.open()
  M.update(true)
end

function M.close()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  
  M.state.is_open = false
end

function M.toggle()
  if M.state.is_open then
    M.close()
  else
    M.open()
  end
end

return M