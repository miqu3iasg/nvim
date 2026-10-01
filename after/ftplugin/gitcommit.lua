-- after/ftplugin/gitcommit.lua

-- Commit message buffers (:Git commit, `git commit` with nvim as $EDITOR)

local opt = vim.opt_local

-- Commit message conventions
opt.spell = true
opt.spelllang = { "en", "pt_br" }
opt.complete:append("kspell") -- dictionary words in <C-n>/<C-p> completion
opt.textwidth = 72
opt.colorcolumn = ""
opt.wrap = true
opt.linebreak = true
opt.formatoptions:append("t") -- auto-wrap text at textwidth
opt.number = false
opt.relativenumber = false

-- Start in insert mode when the message is empty
if vim.fn.getline(1) == "" then
  vim.cmd("startinsert")
end

local function map(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, desc = desc })
end

map("<leader>w", "<cmd>wq<CR>", "Save and confirm commit")
map("<leader>q", "<cmd>cq<CR>", "Abort commit")
