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

vim.keymap.set("i", "<C-c><C-c>", "<cmd>wq<CR>", { buffer = true, silent = true, desc = "Save and confirm commit" })

map("<C-c><C-c>", "<cmd>wq<CR>", "Save and confirm commit")

map("q", function()
  local standalone = #vim.api.nvim_list_tabpages() == 1
      and #vim.api.nvim_list_wins() == 1
      and #vim.fn.getbufinfo({ buflisted = 1 }) == 1

  if standalone then
    vim.cmd("cq")
  else
    vim.cmd("bwipeout!")
  end
end, "Abort commit")
