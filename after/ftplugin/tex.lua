-- after/ftplugin/tex.lua

-- Runs once per tex buffer. Mappings below are buffer-local, so they need the
-- real buffer number (a nil `buffer` would make them global)
local bufnr = vim.api.nvim_get_current_buf()

-- Visual wrapping, respecting word boundaries.
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.showbreak = "  "

-- Spell check
vim.opt_local.spell = true
vim.opt_local.spelllang = "en_us"

-- Required for vimtex's own concealment (accents, greek, etc.)
vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = "nc"

-- No line numbers or sign column
vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = "no"

-- Visual-line motion (matters with 'wrap'); a count keeps physical lines
for key, visual in pairs({ j = "gj", k = "gk" }) do
	vim.keymap.set({ "n", "x" }, key, ("v:count == 0 ? '%s' : '%s'"):format(visual, key), {
		buffer = bufnr,
		expr = true,
		silent = true,
		desc = "Move by visual line (" .. key .. ")",
	})
end

local function map(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
end

map("<localleader>xc", "<cmd>VimtexCompile<cr>", "Compile (continuous)")
map("<localleader>xv", "<cmd>VimtexView<cr>", "View PDF")
map("<localleader>xt", "<cmd>VimtexTocToggle<cr>", "Table of contents")
map("<localleader>xs", "<cmd>VimtexStop<cr>", "Stop compilation")
map("<localleader>xk", "<cmd>VimtexClean<cr>", "Clean aux files")
