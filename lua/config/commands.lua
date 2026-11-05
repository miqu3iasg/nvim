-- lua/config/commands.lua

-- Side-effect-only file. User commands defined with :command. Plugin
-- management commands here ("Pack*") mirror the built-in :vim.pack commands
-- with friendlier names; the plugin list itself lives in lua/config/pack.lua.

-- Change the working directory to the current file's directory.
-- Mapped to <leader>nw in lua/config/keymaps/files.lua.
vim.api.nvim_create_user_command("Setwd", function()
	vim.cmd.cd(vim.fn.expand("%:p:h"))
end, {})

-- Autoformat on save, controlled with :FormatEnable/:FormatDisable.
-- The toggle state (with global and buffer-local scopes) lives in
-- lua/shared/autoformat.lua, together with conform.nvim's save hook.

-- Disable autoformatting until re-enabled
vim.api.nvim_create_user_command("FormatDisable", function()
	require("shared.autoformat").disable()
end, { desc = "Disable autoformat-on-save" })

-- Enable autoformatting again
vim.api.nvim_create_user_command("FormatEnable", function()
	require("shared.autoformat").enable()
end, { desc = "Re-enable autoformat-on-save" })

-- Plugin Management
-- Thin wrappers around the builtin vim.pack API. See also: config/keymaps/pack.lua.

-- Add plugins (as "user/repo" specs) to the running session, installing them
-- when they are not present yet
---@param opts { fargs: string[] } invocation info for the user command
vim.api.nvim_create_user_command("PackAdd", function(opts)
	vim.pack.add(opts.fargs)
end, {
	nargs = "+",
	desc = "Add plugins (:PackAdd user/repo1 user/repo2)",
})

-- :PackDel and :PackUpdate become builtins in Neovim 0.13; these user commands
-- keep the same names available while running 0.12.
---Delete plugins by name
---@param opts { fargs: string[] } invocation info for the user command
vim.api.nvim_create_user_command("PackDel", function(opts)
	vim.pack.del(opts.fargs)
end, {
	nargs = "+",
	desc = "Delete plugins (:PackDel plugin1 plugin2)",
})

---Update every tracked plugin, or only the ones named as command arguments
---(`:PackUpdate foo/bar ...`). With no arguments, updates everything.
---@param opts { args: string, fargs: string[] } invocation info for the user command
vim.api.nvim_create_user_command("PackUpdate", function(opts)
	if opts.args:match("%S") then
		local plugins = vim.split(opts.args, "%s+", { trimempty = true })
		vim.pack.update(plugins)
	else
		vim.pack.update()
	end
end, {
	nargs = "*",
	desc = "Update all plugins or specific ones",
})
