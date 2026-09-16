-- lua/langs/markdown/init.lua

local M = {}

function M.setup(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  require("langs.markdown.settings").setup(bufnr)
  require("langs.markdown.keymaps").setup(bufnr)
end

return M
