-- lua/langs/jsts/web_filetype.lua

-- Shared setup for the JavaScript, TypeScript and React ftplugins
--
-- Every option is set with `vim.opt_local`, so call these functions from an
-- ftplugin: they only affect the current buffer.
--
-- Usage
--   -- after/ftplugin/typescriptreact.lua
--   require("langs.jsts.web_filetype_settings").setup({ react = true })
--
--   -- after/ftplugin/css.lua
--   require("langs.jsts.web_filetype_settings").markup()

local M = {}

---Indentation of line `row`; when `deeper` and the line opens a block (ends
---with `{`, `(` or `[`), add one level.
---NOTE: not used anywhere in this file.
---@param row integer 1-based line number
---@param deeper? boolean
---@return string indent whitespace to use as indentation
local function line_indent(row, deeper)
	local line = vim.fn.getline(row)
	local indent = line:match("^%s*")
	if deeper and line:match("[{(%[]%s*$") then
		indent = indent .. string.rep(" ", vim.fn.shiftwidth())
	end
	return indent
end

---Setup for JavaScript, TypeScript and React: 2-space indentation with spaces,
---no conceal, `gf` resolving extensionless imports (`.ts`, `.tsx`, `.js`,
---`.jsx`, `.json` and `/index.*`) and `$` as a word character (`$el`).
---With `react`, `-` is also a word character, so `data-foo` and class names
---with dashes are a single word.
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

---Setup for CSS, SCSS and HTML: 2-space indentation with spaces, and `-` as a
---word character (`font-size`, `my-class`).
function M.markup()
	local o = vim.opt_local
	o.shiftwidth = 2
	o.tabstop = 2
	o.softtabstop = 2
	o.expandtab = true
	o.iskeyword:append("-")
end

return M
