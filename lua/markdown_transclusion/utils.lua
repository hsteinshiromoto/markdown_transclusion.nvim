local M = {}
local config = require('markdown_transclusion.config')

---@param path string The file path
---@return string|nil content File content or nil if not found
function M.read_file(path)
  local file = io.open(path, 'r')
  if not file then
    return nil
  end
  
  local content = file:read('*all')
  file:close()
  
  return content
end

---@param path string Potentially relative file path
---@return string absolute_path Absolute file path
function M.resolve_path(path)
  -- If path is already absolute, return it
  if vim.fn.fnamemodify(path, ':p') == path then
    return path
  end
  
  -- Handle relative paths
  local current_file = vim.fn.expand('%:p')
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  
  -- Check if the path has an extension
  if not path:match('%.%w+$') then
    path = path .. '.md'  -- Add .md extension by default
  end
  
  return vim.fn.simplify(current_dir .. '/' .. path)
end

---@param content string Content to parse for transclusions
---@param depth number Current recursion depth
---@return string processed_content Content with transclusions expanded
function M.process_transclusions(content, depth)
  depth = depth or 0
  if depth >= config.get().format.max_depth then
    return content
  end
  
  local pattern = config.get().format.link_pattern
  
  return content:gsub(pattern, function(link)
    local path = M.resolve_path(link)
    local file_content = M.read_file(path)
    
    if file_content then
      -- Process nested transclusions
      local processed_content = M.process_transclusions(file_content, depth + 1)
      return '\n' .. processed_content .. '\n'
    else
      return '[Transclusion failed: File not found - ' .. link .. ']'
    end
  end)
end

---@param text string The text to display in the notification
---@param level string|nil The level of the notification (info, warn, error)
function M.notify(text, level)
  level = level or 'info'
  vim.notify(string.format('[Markdown Transclusion] %s', text), vim.log.levels[level:upper()])
end

return M