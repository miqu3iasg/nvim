-- lua/langs/latex/init.lua

local M = {}

function M.setup(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  require("langs.latex.settings").setup(bufnr)
  require("langs.latex.keymaps").setup(bufnr)
end

return M
