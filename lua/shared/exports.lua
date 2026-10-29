-- lua/shared/exports.lua

-- Single source of truth for where exported documents go, shared by the
-- pandoc (markdown), vimtex (LaTeX) and tinymist (Typst) setups.
--
-- <root>/exports/<reldir>/<name>.pdf     final documents, from any source
-- <root>/.build/<reldir>/<name>/         compilation byproducts (latexmk)
--
-- <reldir> is the folder of the note relative to <root>, so notes with the
-- same file name in different folders never overwrite each other. <root> is
-- found through `M.markers`, falling back to the note's own folder. Set
-- `vim.g.exports_root` to force one global folder instead.
--
-- Every function takes a `src`: a buffer number or a file path. An unnamed
-- buffer is treated as a file called `scratch` in the cwd.
--
-- Usage:
--   local exports = require("shared.exports")
--   exports.output_path(0, "pdf")   --> <root>/exports/<reldir>/<name>.pdf
--   exports.build_dir("/a/b/c.tex") --> <root>/.build/<reldir>/c

local M = {}

-- Folder names created under <root>
M.exports_dirname = "exports"
M.build_dirname = ".build"

---Markers that identify the root, searched in order from highest to lowest
---priority. Markers inside the same inner table have equal priority (the
---closest parent with any of them wins). Nested lists need a Neovim whose
---`vim.fs.root` accepts them (0.11+).
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

---File path of `src`. Buffers without a name resolve to `<cwd>/scratch`.
---@param src integer|string buffer number or file path
---@return string
local function path_of(src)
	if type(src) == "number" then
		local name = vim.api.nvim_buf_get_name(src)
		return name ~= "" and name or (vim.uv.cwd() .. "/scratch")
	end
	return src
end

---Root folder that holds `exports/` and `.build/` for `src`.
---`vim.g.exports_root`, when set, wins over everything. Otherwise it is the
---closest parent matching `M.markers`, falling back to the folder of `src`.
---@param src integer|string
---@return string
function M.root(src)
	if vim.g.exports_root and vim.g.exports_root ~= "" then
		return vim.fs.normalize(vim.g.exports_root)
	end
	local path = path_of(src)
	return vim.fs.root(path, M.markers) or vim.fs.dirname(path)
end

---File name of `src` without directory and extension (`/a/note.md` -> `note`).
---@param src integer|string
---@return string
function M.basename(src)
	return vim.fn.fnamemodify(path_of(src), ":t:r")
end

---Folder for final documents: `<root>/exports`.
---@param src integer|string
---@return string
function M.exports_dir(src)
	return M.root(src) .. "/" .. M.exports_dirname
end

---Folder of the note relative to the root, with a trailing slash ("" if the
---note sits at the root, or outside it).
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

---Final document: `<root>/exports/<reldir>/<name>.<ext>`.
---@param src integer|string
---@param ext? string extension without the dot (default `"pdf"`)
---@return string
function M.output_path(src, ext)
	return M.exports_dir(src) .. "/" .. M.reldir(src) .. M.basename(src) .. "." .. (ext or "pdf")
end

---Compilation byproducts folder: `<root>/.build/<reldir>/<name>`.
---@param src integer|string
---@return string
function M.build_dir(src)
	return M.root(src) .. "/" .. M.build_dirname .. "/" .. M.reldir(src) .. M.basename(src)
end

return M
