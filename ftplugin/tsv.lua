-- ftplugin/tsv.lua

-- Reuse the CSV settings for TSV files.
-- The delimiter is set to "\t" for tsv in lua/plugins/csv.lua.
vim.cmd("runtime! ftplugin/csv.lua")
