-- lua/langs/python/init.lua

local M = {}

function M.setup(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  require("langs.python.keymaps").setup(bufnr)
end

return M
