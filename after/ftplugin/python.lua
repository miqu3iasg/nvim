-- after/ftplugin/python.lua

-- PEP 8 style. 4-space indentation, comment continuation enabled
-- (`croql` without `t`, so wrapping stays with a formatter), indent-based
-- folding and an 88-column text width (matching the ruff/black defaults
-- that conform uses for formatting).

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
