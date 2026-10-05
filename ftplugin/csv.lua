-- ftplugin/csv.lua

-- References:
-- - https://github.com/chrisbra/csv.vim/blob/master/autoload/csv.vim
-- - https://github.com/chrisbra/csv.vim/blob/master/syntax/csv.vim

vim.opt_local.wrap = false
vim.opt_local.colorcolumn = ""
vim.b.no_trim_whitespace = true

local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = true, desc = desc })
end

local delimiter_arg = ""
if vim.bo.filetype == "csv" then
  local first = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ""
  local _, semicolons = first:gsub(";", "")
  local _, commas = first:gsub(",", "")
  if semicolons > commas then
    delimiter_arg = " delimiter=;"
  end
end
pcall(vim.cmd, "CsvViewEnable" .. delimiter_arg)

map("<leader>cv", "<cmd>CsvViewToggle<cr>", "CSV: toggle view")
map("<leader>ci", "<cmd>CsvViewInfo<cr>", "CSV: info")

-- Open the file in VisiData for heavy exploration (sort, filter, pivot).
map("<leader>cd", function()
  vim.cmd("split | terminal vd " .. vim.fn.shellescape(vim.fn.expand("%:p")))
  vim.cmd("startinsert")
end, "CSV: open in visidata")

-- Heavy operations are better done with external filters, e.g.:
--
--   :%!qsv sort -s name        sort by column
--   :%!qsv search -s city SP   filter rows
