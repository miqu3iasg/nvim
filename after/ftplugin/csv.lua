-- after/ftplugin/csv.lua

-- See: https://github.com/chrisbra/csv.vim/blob/master/autoload/csv.vim
-- See: https://github.com/chrisbra/csv.vim/blob/master/syntax/csv.vim

vim.opt_local.wrap = false
vim.opt_local.colorcolumn = ""
vim.b.no_trim_whitespace = true

local map = function(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = true, desc = desc })
end

-- Open the file in VisiData for heavy exploration (sort, filter, pivot).
map("<leader>cd", function()
	vim.cmd("split | terminal vd " .. vim.fn.shellescape(vim.fn.expand("%:p")))
	vim.cmd("startinsert")
end, "CSV: open in visidata")

-- Heavy operations are better done with external filters, e.g.:
--
--   :%!qsv sort -s name        sort by column
--   :%!qsv search -s city SP   filter rows
