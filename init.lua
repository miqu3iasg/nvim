-- init.lua

-- stop annoying deprecation errors that i cant control
-- because i dont have access to the plugins that use
-- the deprecated functions
vim.deprecate = function() end

require("options")

require("keymaps")

require("lazynvim")

require("autocmds")
require("commands")
require("snippets")
require("statusline").setup()

-- vim.cmd.colorscheme("hollow")
vim.cmd.colorscheme("insanity")
