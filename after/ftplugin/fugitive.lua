-- after/ftplugin/fugitive.lua

-- Fugitive status window (:Git / :G)

local opt = vim.opt_local

opt.number = false
opt.relativenumber = false
opt.signcolumn = "no"

-- `remap = true` lets these mappings trigger fugitive's own buffer-local
-- mappings (e.g. `gq`), which a plain noremap would ignore.
local function map(lhs, rhs, desc, remap)
  vim.keymap.set("n", lhs, rhs, {
    buffer = true,
    silent = true,
    remap = remap or false,
    desc = desc,
  })
end

map("q", "gq", "Close status window", true)
