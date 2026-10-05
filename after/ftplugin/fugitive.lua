-- after/ftplugin/fugitive.lua

-- Fugitive status window

local opt = vim.opt_local

opt.number = false
opt.relativenumber = false
opt.signcolumn = "no"

local function map(lhs, rhs, desc, remap)
  vim.keymap.set("n", lhs, rhs, {
    buffer = true,
    silent = true,
    remap = remap or false,
    desc = desc,
  })
end

map("q", "gq", "Close status window", true)
