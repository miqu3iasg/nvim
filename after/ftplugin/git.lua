-- after/ftplugin/git.lua

local opt = vim.opt_local

opt.foldenable = false
opt.wrap = false
opt.number = false
opt.relativenumber = false
opt.cursorline = false

local function map(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, nowait = true, desc = desc })
end

local ftype = vim.b.fugitive_type
if (ftype == "temp" or ftype == "commit") and not vim.bo.modifiable then
	opt.bufhidden = "wipe"
	map("q", "<cmd>close<CR>", "Close buffer")
end

map("]f", [[/^diff --git<CR>]], "Next file")
map("[f", [[?^diff --git<CR>]], "Previous file")
map("]h", [[/^@@<CR>]], "Next hunk")
map("[h", [[?^@@<CR>]], "Previous hunk")
