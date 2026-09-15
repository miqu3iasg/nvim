-- ftplugin/scheme.lua

-- Indentation
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.expandtab = true
vim.opt_local.autoindent = true
vim.opt_local.smartindent = false
vim.opt_local.cindent = false
vim.opt_local.lisp = true

-- Comments
vim.opt_local.commentstring = "; %s"

-- Editing
vim.opt_local.textwidth = 0
vim.opt_local.wrap = false
vim.opt_local.formatoptions:remove({ "c", "r", "o" })
