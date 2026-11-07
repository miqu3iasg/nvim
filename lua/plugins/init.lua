-- lua/plugins/init.lua

-- Loads all plugin configuration modules. Plugin installation is managed by
-- Neovim's built-in package manager (`vim.pack`), configured in
-- lua/config/pack.lua. Add new plugin modules to the list below; the load
-- order matters because some modules depend on others (for example,
-- lua/plugins/fzf.lua must load before lua/plugins/markdown.lua).
-- A module that fails to load notifies an error instead of aborting the rest.

for _, mod in ipairs({
	"treesitter",
	"formatting",
	"completions",
	"lsp",
	"fzf",
	"git",
	"unnecessary-shit",
	"oil",
	"colorschemes",
	"latex",
	"lisp",
	"markdown",
}) do
	local ok, err = pcall(require, "plugins." .. mod)
	if not ok then
		vim.notify(("Errors at .%s:\n%s"):format(mod, err), vim.log.levels.ERROR)
	end
end
