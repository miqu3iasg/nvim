-- after/ftplugin/tsv.lua

-- Reuse the CSV settings for TSV files (see after/ftplugin/csv.lua);
-- csv.vim already uses the tab as the delimiter for the tsv filetype.
vim.cmd("runtime! ftplugin/csv.lua")
