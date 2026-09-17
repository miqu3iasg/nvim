-- lua/langs/latex/settings.lua

local M = {}

function M.setup(bufnr)
  -- Visual wrapping, respecting word boundaries.
  vim.opt_local.wrap = true
  vim.opt_local.linebreak = true
  vim.opt_local.breakindent = true
  vim.opt_local.showbreak = "  "

  -- Spell check
  vim.opt_local.spell = true
  vim.opt_local.spelllang = "en_us"

  -- Required for vimtex's own concealment (accents, greek, etc.)
  vim.opt_local.conceallevel = 2
  vim.opt_local.concealcursor = "nc"

  -- No line numbers or sign column
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = "no"
end

return M
