-- lua/shared/exports.lua

-- Single source of truth for where exported documents go, shared by the pandoc,
-- vimtex and tinymist setups.
--
-- Final documents are written to `<root>/exports/<reldir>/<name>.pdf`, and
-- compilation byproducts from latexmk go to `<root>/.build/<reldir>/<name>/`.
-- `<reldir>` is the folder of the note relative to `<root>`, so notes with the
-- same file name in different folders never overwrite each other. `<root>` is
-- found through `M.markers`, falling back to the note's own folder. Setting
-- `vim.g.exports_root` forces one global folder instead.
--
-- Every function takes a `src`, which is a buffer number or a file path. An
-- unnamed buffer is treated as a file called `scratch` in the current directory.
--
-- See: lua/plugins/latex.lua
-- See: lua/plugins/lsp.lua

local M = {}

---@type string
M.exports_dirname = "exports"
---@type string
M.build_dirname = ".build"

-- Markers are searched in order, from highest to lowest priority. Markers inside
-- the same inner table have equal priority, and the closest parent with any of
-- them wins. Nested lists require a Neovim whose `vim.fs.root` accepts them.
---@type (string|string[])[]
M.markers = {
	".exports-root",
	{ ".git", ".jj", ".hg", ".svn" },
	{
		".obsidian",
		"README.md",
		"README.markdown",
		"README",
		"LICENSE",
		"LICENSE.md",
		"LICENSE.txt",
		"Makefile",
		".editorconfig",
	},
}

---@param src integer|string Buffer number or file path.
---@return string
local function path_of(src)
	if type(src) == "number" then
		local name = vim.api.nvim_buf_get_name(src)
		return name ~= "" and name or (vim.uv.cwd() .. "/scratch")
	end
	return src
end

---Root folder that holds `exports/` and `.build/` for `src`. `vim.g.exports_root`
---wins over everything when set. Otherwise it is the closest parent matching
---`M.markers`, falling back to the folder of `src`.
---@param src integer|string
---@return string
function M.root(src)
	if vim.g.exports_root and vim.g.exports_root ~= "" then
		return vim.fs.normalize(vim.g.exports_root)
	end
	local path = path_of(src)
	return vim.fs.root(path, M.markers) or vim.fs.dirname(path)
end

---File name of `src` without directory and extension, so `/a/note.md` gives
---`note`.
---@param src integer|string
---@return string
function M.basename(src)
	return vim.fn.fnamemodify(path_of(src), ":t:r")
end

---@param src integer|string
---@return string
function M.exports_dir(src)
	return M.root(src) .. "/" .. M.exports_dirname
end

---Folder of the note relative to the root, with a trailing slash. It is empty
---when the note sits at the root or outside it.
---@param src integer|string
---@return string
function M.reldir(src)
	local path = path_of(src)
	local root = M.root(src)
	local dir = vim.fs.dirname(path)
	if dir:sub(1, #root + 1) == root .. "/" then
		return dir:sub(#root + 2) .. "/"
	end
	return ""
end

---Path of the final document, `<root>/exports/<reldir>/<name>.<ext>`.
---@param src integer|string
---@param ext? string Extension without the dot, `"pdf"` by default.
---@return string
function M.output_path(src, ext)
	return M.exports_dir(src) .. "/" .. M.reldir(src) .. M.basename(src) .. "." .. (ext or "pdf")
end

---Output path template for tools that expand file-name variables themselves,
---such as tinymist. It uses the variables `$root`, `$dir` and `$name` and
---mirrors `M.output_path`, so the two layouts stay in sync.
---@return string
function M.output_pattern()
	return ("$root/%s/$dir/$name"):format(M.exports_dirname)
end

---@param src integer|string
---@return string
function M.build_dir(src)
	return M.root(src) .. "/" .. M.build_dirname .. "/" .. M.reldir(src) .. M.basename(src)
end

return M
