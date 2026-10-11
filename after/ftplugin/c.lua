-- after/ftplugin/c.lua

-- Following the linux kernel coding style.
-- See: https://www.kernel.org/doc/html/v4.10/process/coding-style.html

vim.opt_local.expandtab = false
vim.opt_local.smarttab = false
vim.opt_local.tabstop = 8
vim.opt_local.shiftwidth = 8
vim.opt_local.softtabstop = 8
vim.opt_local.textwidth = 80

vim.opt_local.cindent = true
vim.opt_local.cinoptions = ":0,l1,t0,g0,(0"

vim.opt_local.formatoptions:append("croql")
