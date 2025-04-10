local M = {}

function M.create(buf, options)
  local win_id = vim.api.nvim_open_win(buf, false, options or {})
  return win_id
end

return M