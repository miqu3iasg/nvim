-- lua/commands.lua

-- Change the working directory to the current file's directory.
vim.api.nvim_create_user_command("Setwd", function()
	vim.cmd.cd(vim.fn.expand("%:p:h"))
end, {})

-- Automatic Formatting
vim.api.nvim_create_user_command("FormatDisable", function()
	vim.g.disable_autoformat = true
end, { desc = "Disable autoformat-on-save" })

vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end, { desc = "Re-enable autoformat-on-save" })

-- Plugin Management

-- Add plugins
vim.api.nvim_create_user_command("PackAdd", function(opts)
	vim.pack.add(opts.fargs)
end, {
	nargs = "+",
	desc = "Add plugins (:PackAdd user/repo1 user/repo2)",
})

-- PackDel and PackUpdate are built into Neovim Nightly 0.13
vim.api.nvim_create_user_command("PackDel", function(opts)
	vim.pack.del(opts.fargs)
end, {
	nargs = "+",
	desc = "Delete plugins (:PackDel plugin1 plugin2)",
})

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
