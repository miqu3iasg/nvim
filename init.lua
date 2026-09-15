-- init.lua

local utils = require("utils")
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
require("macros")
require("statusline")

utils.color_overrides.setup_colorscheme_overrides()

vim.cmd.colorscheme("insanity")

utils.fix_telescope_parens_win()
