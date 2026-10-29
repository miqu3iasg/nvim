-- after/ftplugin/python.lua

local opt = vim.opt_local

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4

opt.textwidth = 88
opt.formatoptions:remove("t")
opt.formatoptions:append("croql")

opt.foldmethod = "indent"
opt.foldlevel = 99
