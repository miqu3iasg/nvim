-- lua/plugins/init.lua

-- Loads all plugin configuration modules. Plugin installation is managed
-- by Neovim's built-in package manager (`vim.pack`), configured in
-- lua/config/pack.lua. Add new plugin modules to the list below

for _, mod in ipairs({
	"treesitter",
	"formatting",
	"completions",
	"lsp",
	"fzf",
	"git",
	"unnacessary-shit",
	"latex",
	"lisp",
	"oil",
	"colorschemes",
	"markdown",
}) do
	local ok, err = pcall(require, "plugins." .. mod)
	if not ok then
		vim.notify(("Errors at .%s:\n%s"):format(mod, err), vim.log.levels.ERROR)
	end
end
