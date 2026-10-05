-- after/ftplugin/gitcommit.lua

-- Commit message buffers (:Git commit, `git commit` with nvim as $EDITOR)

local opt = vim.opt_local

opt.spell = true
opt.spelllang = { "en", "pt_br" }
opt.complete:append("kspell")
opt.textwidth = 72
opt.colorcolumn = ""
opt.wrap = true
opt.linebreak = true
opt.formatoptions:append("t")
opt.number = false
opt.relativenumber = false

local function map(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, desc = desc })
end

map("<leader>w", "<cmd>wq<CR>", "Save and confirm commit")
map("<leader>q", "<cmd>cq<CR>", "Abort commit")
