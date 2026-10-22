-- lua/plugins/treesitter.lua

vim.env.PYTHONIOENCODING = "utf-8"
local ts = require("nvim-treesitter")
ts.install({
	"typst",
	"vimdoc",
	"go",
	"rust",
	"c",
	"lua",
	"python",
	"html",
	"css",
	"scss",
	"java",
	"javascript",
	"typescript",
	"tsx",
	"jsdoc",
	"regex",
	"sql",
	"markdown",
	"markdown_inline",
	"latex",
	"bash",
	"yaml",
	"json",
	"toml",
	"c_sharp",
	"dockerfile",
	"terraform",
	"cmake",
}, {
	max_jobs = 4,
})

local group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true })

-- Keep Vim's legacy syntax engine for `tex` buffers because vimtex
-- depends on its highlight groups and conceal rules. Treesitter's
-- `latex` parser remains installed for LaTeX math highlighting inside
-- Markdown, but must not attach directly to `tex` buffers.
--
-- See: :h vimtex-faq-treesitter
-- See: https://github.com/lervag/vimtex/wiki/Syntax
local ts_highlight_excluded = {
	tex = true,
	latex = true,
}

-- Auto-install parsers and enable highlighting on FileType
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	desc = "Enable treesitter highlighting and indentation",
	callback = function(event)
		local lang = vim.treesitter.language.get_lang(event.match) or event.match
		local buf = event.buf

		if ts_highlight_excluded[event.match] or ts_highlight_excluded[lang] then
			return
		end

		-- Start highlighting immediately (works if parser exists)
		pcall(vim.treesitter.start, buf, lang)

		-- local good_ts_indent = { lua = true }
		-- if good_ts_indent[lang] then
		--   vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		-- end
	end,
})
