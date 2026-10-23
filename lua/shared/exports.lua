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

local M = {}

M.exports_dirname = "exports"
M.build_dirname = ".build"

-- Searched in order, from highest to lowest priority. Markers inside the same
-- inner table have equal priority (the closest parent with any of them wins)
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

-- Accepts a buffer number or a file path
local function path_of(src)
	if type(src) == "number" then
		local name = vim.api.nvim_buf_get_name(src)
		return name ~= "" and name or (vim.uv.cwd() .. "/scratch")
	end
	return src
end

function M.root(src)
	if vim.g.exports_root and vim.g.exports_root ~= "" then
		return vim.fs.normalize(vim.g.exports_root)
	end
	local path = path_of(src)
	return vim.fs.root(path, M.markers) or vim.fs.dirname(path)
end

function M.basename(src)
	return vim.fn.fnamemodify(path_of(src), ":t:r")
end

function M.exports_dir(src)
	return M.root(src) .. "/" .. M.exports_dirname
end

-- Folder of the note relative to the root, with a trailing slash ("" if the
-- note sits at the root)
function M.reldir(src)
	local path = path_of(src)
	local root = M.root(src)
	local dir = vim.fs.dirname(path)
	if dir:sub(1, #root + 1) == root .. "/" then
		return dir:sub(#root + 2) .. "/"
	end
	return ""
end

-- Final document: <root>/exports/<reldir>/<name>.<ext>
function M.output_path(src, ext)
	return M.exports_dir(src) .. "/" .. M.reldir(src) .. M.basename(src) .. "." .. (ext or "pdf")
end

-- Byproducts: <root>/.build/<reldir>/<name>
function M.build_dir(src)
	return M.root(src) .. "/" .. M.build_dirname .. "/" .. M.reldir(src) .. M.basename(src)
end

return M
