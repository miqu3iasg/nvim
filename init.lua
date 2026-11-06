-- init.lua

-- Entry point. Enables vim.loader (caches compiled Lua bytecode so `require`
-- calls are faster on later startups) and neuters vim.deprecate, which would
-- otherwise raise deprecation errors from third-party code. Then loads
-- options, keymaps, autocmds, commands, the statusline and the plugins, sets
-- up the native :Compile feature, and applies the colorscheme.
vim.loader.enable()
vim.deprecate = function() end

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.commands")
require("features.statusline").setup()
require("config.pack")
require("plugins")
require("features.compile").setup()

vim.cmd.colorscheme("hollow")
