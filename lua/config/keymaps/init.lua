-- lua/config/keymaps/init.lua

-- Entry point for the keymaps: sets the leader keys (they must be set before
-- any `<leader>` mapping is created) and loads the keymap themes. Keymaps that
-- belong to a single plugin live in that plugin's file under lua/plugins/.

local M = {}

-- Leader keys
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
require("config.keymaps.pack")

return M
