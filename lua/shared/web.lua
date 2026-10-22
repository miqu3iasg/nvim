-- lua/langs/jsts/web.lua

-- Shared setup for the JavaScript, TypeScript and React ftplugins

local M = {}

-- Indentation of line `row`; when `deeper` and the line opens a block, add one level
local function line_indent(row, deeper)
	local line = vim.fn.getline(row)
	local indent = line:match("^%s*")
	if deeper and line:match("[{(%[]%s*$") then
		indent = indent .. string.rep(" ", vim.fn.shiftwidth())
	end
	return indent
end

-- Setup for JavaScript, TypeScript and React
---@param opts? { react?: boolean }
function M.setup(opts)
	opts = opts or {}
	local o = vim.opt_local

	o.shiftwidth = 2
	o.tabstop = 2
	o.softtabstop = 2
	o.expandtab = true
	o.conceallevel = 0
	o.suffixesadd:append({ ".ts", ".tsx", ".js", ".jsx", ".json", "/index.ts", "/index.tsx", "/index.js" })
	o.iskeyword:append("$")

	if opts.react then
		o.iskeyword:append("-")
	end
end

-- Setup for CSS, SCSS and HTML
function M.markup()
	local o = vim.opt_local
	o.shiftwidth = 2
	o.tabstop = 2
	o.softtabstop = 2
	o.expandtab = true
	o.iskeyword:append("-")
end

return M
