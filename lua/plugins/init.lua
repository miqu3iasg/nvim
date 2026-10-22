-- lua/plugins/init.lua

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
	"obsidian",
	"oil",
}) do
	local ok, err = pcall(require, "plugins." .. mod)
	if not ok then
		vim.notify(("Errors at .%s:\n%s"):format(mod, err), vim.log.levels.ERROR)
	end
end
