local utils = require("utils")
-- stop annoying deprecation errors that i cant control
-- because i dont have access to the plugins that use
-- the deprecated functions
vim.deprecate = function() end
require("options")

local km = require("keymaps")

require("custom_filetypes")
require("lazynvim")

require("cool_stuff")
require("mappings")
require("autocmds")
require("commands")
require("snippets")
require("macros")

utils.color_overrides.setup_colorscheme_overrides()

vim.cmd.colorscheme("burzum")

utils.fix_telescope_parens_win()

utils.dashboard.setup_dashboard_image_colors()
