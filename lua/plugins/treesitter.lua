-- lua/plugins/treesitter.lua

-- This is an essential module. Tree-sitter provides syntax-aware code parsing
-- and highlighting for the languages supported by this configuration. It
-- enables more accurate syntax highlighting than traditional regex-based rules
-- and provides the parsing infrastructure used by other Neovim features and
-- plugins. Several language-specific features depend on the corresponding
-- parser being installed.
--
-- nvim-treesitter uses the Tree-sitter CLI to compile language parsers,
-- so the CLI must be installed and available on PATH. On Arch Linux:
--
-- $ sudo pacman -S tree-sitter-cli
--
-- The parsers listed in `ts.install()` are requested for automatic
-- installation. The installation process may take some time because
-- parsers need to be downloaded and compiled. The `max_jobs` option
-- limits the number of concurrent installation jobs to reduce resource
-- usage. To install parsers manually from Neovim, use `:TSInstall`
-- followed by the desired parser names, for example:
--
-- :TSInstall lua python javascript
--
-- This configuration starts Tree-sitter highlighting automatically when
-- a buffer's `FileType` event fires, provided the corresponding parser
-- is available. The filetype is mapped to a Tree-sitter language where
-- possible, and `vim.treesitter.start()` is called inside `pcall()` so
-- a missing or unsupported parser does not interrupt the rest of the
-- configuration. Parser installation and highlighting activation are
-- separate operations: requesting installation does not mean a parser
-- is already available when a buffer is opened.
--
-- LaTeX is a special case. VimTeX relies on Vim's legacy syntax engine
-- for its syntax groups and conceal rules, so Tree-sitter highlighting
-- must not attach directly to `tex` or `latex` buffers. The LaTeX parser
-- remains installed because it can be useful for highlighting LaTeX
-- math inside Markdown documents. This exception preserves VimTeX's
-- behavior while allowing Tree-sitter to handle other supported languages.
--
-- The indentation configuration is intentionally left inactive because
-- Tree-sitter indentation is not enabled globally. If indentation is
-- enabled later, it should be restricted to languages where its results
-- have been verified to work correctly.
--
-- See: https://github.com/nvim-treesitter/nvim-treesitter
-- See: :h vim-treesitter
-- See: :h vimtex-faq-treesitter
-- See: https://github.com/lervag/vimtex/wiki/Syntax

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
	"javadoc",
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

-- Keep Vim's legacy syntax engine for `tex` buffers because VimTeX
-- depends on its highlight groups and conceal rules. The `latex`
-- parser remains installed for LaTeX math highlighting inside Markdown,
-- but must not attach directly to `tex` or `latex` buffers.
--
-- See: :h vimtex-faq-treesitter
-- See: https://github.com/lervag/vimtex/wiki/Syntax
local ts_highlight_excluded = {
	tex = true,
	latex = true,
}

-- Enable Tree-sitter highlighting when a buffer's filetype is detected.
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	desc = "Enable treesitter highlighting and indentation",
	callback = function(event)
		local lang = vim.treesitter.language.get_lang(event.match) or event.match
		local buf = event.buf

		if ts_highlight_excluded[event.match] or ts_highlight_excluded[lang] then
			return
		end

		-- Start highlighting immediately if the parser is available.
		pcall(vim.treesitter.start, buf, lang)

		-- Enable Tree-sitter indentation only for languages where it has
		-- been verified to behave correctly.
		-- local good_ts_indent = { lua = true }
		-- if good_ts_indent[lang] then
		--   vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		-- end
	end,
})
