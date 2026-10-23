-- lua/plugins/latex.lua

-- The LaTeX writing-mode setup (wrapping, conceal, readable width and
-- <localleader>x compile/view/TOC mappings) lives in after/ftplugin/latex/,
-- alongside MarkdownWriting.
--
-- This configuration requires a full TeX distribution to compile documents,
-- a PDF viewer with SyncTeX support, and the dependencies required by
-- latexindent for LaTeX indentation and formatting.
--
-- On Arch Linux, install the TeX Live packages and build tools with pacman:
--
-- $ sudo pacman -S texlive-basic texlive-bin texlive-latexextra texlive-fontsextra
--
-- This configuration uses Zathura as the PDF viewer. Install it with its
-- MuPDF backend to enable PDF viewing and SyncTeX integration:
--
-- $ sudo pacman -S zathura zathura-pdf-mupdf
--
-- latexindent is installed automatically through Mason. It may require
-- `libcrypt.so.1`, which can be missing on systems using libxcrypt.
-- On Arch Linux, install the compatibility library with:
--
-- $ sudo pacman -S libxcrypt-compat
--
-- See: https://github.com/lervag/vimtex
-- See: https://github.com/cmhughes/latexindent.pl
-- See: https://github.com/latex3/latex2e

local tex_group = vim.api.nvim_create_augroup("latex_buffer_plugins", { clear = true })

local exports = require("shared.exports")

vim.g.vimtex_view_method = "zathura"
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_compiler_latexmk = {
	continuous = 1,
	-- NOTE: VimTeX renamed `build_dir` to `out_dir` in v2.13; `build_dir` is
	-- now silently ignored.

	-- Byproducts (and the first PDF) go to <root>/.build/<reldir>/<name>/.
	-- A function is used because the folder depends on the project.
	out_dir = function()
		return exports.build_dir(vim.api.nvim_get_current_buf())
	end,
	options = {
		"-pdf",
		"-interaction=nonstopmode",
		"-synctex=1",
	},
}
vim.g.vimtex_quickfix_mode = 0 -- Avoid stealing focus for every warning.
vim.g.vimtex_fold_enabled = true
vim.g.vimtex_indent_enabled = true
vim.g.vimtex_syntax_conceal_disable = true

-- Use VimTeX's "simple" algorithm (plain citation-key matching) instead
-- of the default "smart" search over titles and authors. The documentation
-- recommends "simple" when another completion plugin provides the menu.
-- See: :h g:vimtex_complete_bib
vim.g.vimtex_complete_bib = {
	simple = 1,
	info_fmt = "@author_all (@year)\n@title",
}

-- After a successful compilation, copy the PDF from .build/ to exports/
vim.api.nvim_create_autocmd("User", {
	pattern = "VimtexEventCompileSuccess",
	group = vim.api.nvim_create_augroup("latex_export_pdf", { clear = true }),
	callback = function()
		local state = vim.b.vimtex
		local tex_file = (state and state.tex) or vim.fn.expand("%:p")

		if tex_file == "" then
			return
		end

		local src = exports.build_dir(tex_file) .. "/" .. exports.basename(tex_file) .. ".pdf"
		local dest = exports.output_path(tex_file)

		if vim.fn.filereadable(src) == 0 then
			return
		end

		vim.fn.mkdir(vim.fs.dirname(dest), "p")

		vim.uv.fs_copyfile(src, dest, function(err)
			if err then
				vim.schedule(function()
					vim.notify("vimtex: failed to copy PDF to exports/ (" .. err .. ")", vim.log.levels.ERROR)
				end)
			end
		end)
	end,
})

-- Install latexindent automatically through Mason. Mason itself is
-- configured in lua/plugins/lsp.lua, which must load before this file.
-- If other files also configure mason-tool-installer, merge their
-- `ensure_installed` lists into a single setup call.
require("mason-tool-installer").setup({
	ensure_installed = { "latexindent" },
})
