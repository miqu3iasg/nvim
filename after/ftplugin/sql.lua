-- after/ftplugin/sql.lua

vim.opt_local.autoindent = true
vim.opt_local.smartindent = false
vim.opt_local.cindent = false
vim.opt_local.indentexpr = ""

vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2

vim.opt_local.commentstring = "-- %s"
vim.opt_local.comments = "b:--,s1:/*,mb:*,ex:*/"
vim.opt_local.formatoptions:append({ "c", "r", "o", "j" })
vim.opt_local.formatoptions:remove({ "t" })

vim.opt_local.wrap = false

vim.g.omni_sql_no_default_maps = 1
