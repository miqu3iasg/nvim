-- lua/keymaps/init.lua

local M = {}

-- Leader keys
-- must be set before any <leader>, based mapping below is created
vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("config.keymaps.windows")
require("config.keymaps.command_mode")
require("config.keymaps.search")
require("config.keymaps.editing")
require("config.keymaps.buffers")
require("config.keymaps.terminal")
require("config.keymaps.files")
require("config.keymaps.misc")
require("config.keymaps.marks")
require("config.keymaps.inserts")

return M
