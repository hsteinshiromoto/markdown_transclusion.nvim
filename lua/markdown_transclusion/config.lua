local M = {}

local default_config = {
  auto_update = true,
  auto_open = false,
  auto_close = false,
  set_keymaps = true,
  keymaps = {
    toggle = '<leader>mt',
    update = '<leader>mu',
  },
  -- Win options for snacks.nvim
  win_options = {
    relative = 'editor',
    width = 80,
    height = 20,
    row = 2,
    col = 120,
    border = 'rounded',
    title = 'Transclusion Preview',
    title_pos = 'center',
  },
  -- Obsidian.nvim integration
  use_obsidian = true, -- Enable integration with obsidian.nvim
  -- Transclusion format options
  format = {
    link_pattern = '!%[%[(.-)%]%]', -- Obsidian-style transclusion pattern: ![[file_name]]
    max_depth = 3, -- Max recursion depth for nested transclusions
    link_prefix = '## ', -- Prefix for the linked title when using obsidian integration
  },
}

M.config = vim.deepcopy(default_config)

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

function M.get()
  return M.config
end

return M