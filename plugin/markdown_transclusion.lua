-- Entry point for plugin
local setup_ok, markdown_transclusion = pcall(require, 'markdown_transclusion')
if not setup_ok then
  vim.notify('Failed to load markdown_transclusion plugin', vim.log.levels.ERROR)
  return
end

markdown_transclusion.setup()