-- lua/langs/markdown/settings.lua

local M = {}

function M.setup()
  vim.opt_local.wrap = true
  vim.opt_local.linebreak = true
  vim.opt_local.breakindent = true
  vim.opt_local.showbreak = "  "

  vim.opt_local.spell = true
  vim.opt_local.spelllang = { "pt_br", "en_us" }

  vim.opt_local.textwidth = 88
  -- Hard wrap automatically at textwidth while typing
  vim.opt_local.formatoptions:append("t")
  vim.opt_local.formatoptions:remove("l")
  vim.opt_local.formatoptions:append("n")

  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = "no"

  vim.opt_local.shiftwidth = 2
end

return M
