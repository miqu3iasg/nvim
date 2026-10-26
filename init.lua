-- init.lua

-- Caches compiled Lua bytecode so `require` calls are faster on later startups
vim.loader.enable()

-- Stop annoying deprecation errors that I can't control
vim.deprecate = function() end

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.commands")
require("config.statusline").setup()
require("config.pack")
require("plugins")

vim.cmd.colorscheme("hollow")
