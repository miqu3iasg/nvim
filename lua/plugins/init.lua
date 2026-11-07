-- lua/plugins/init.lua

-- Loads all plugin configuration modules. Plugin installation is managed by
-- Neovim's built-in package manager (`vim.pack`), configured in
-- lua/config/pack.lua. Add new plugin modules to the list below; the load
-- order matters because some modules depend on others (for example,
-- lua/plugins/fzf.lua must load before lua/plugins/markdown.lua).
-- A module that fails to load notifies an error instead of aborting the rest.
--
-- Latex (vimtex) and lisp (conjure) are lazy plugins: each config module
-- self-declares its lazy spec via utils.lazy.setup (see lua/utils/lazy.lua),
-- so their require is cheap here - only the registry entry runs at startup;
-- configure() + :packadd fire on the first matching filetype buffer.
-- See: lua/config/pack.lua
--
-- Natively replaced features live in lua/features/ instead: todos.lua
-- (todo-comments) and compile.lua (:Compile/compile-mode) set themselves up.

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
