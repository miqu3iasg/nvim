local M = {}

-- Leader keys
-- must be set before any <leader>-based mapping below is created
vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("keymaps.windows")
require("keymaps.command_mode")
require("keymaps.search")
require("keymaps.editing")
require("keymaps.lsp")
require("keymaps.quickfix")
require("keymaps.buffers")
require("keymaps.terminal")
require("keymaps.files")
require("keymaps.misc")

return M
