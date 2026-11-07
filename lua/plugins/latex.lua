-- lua/plugins/latex.lua

-- VimTeX globals and the PDF export hook.
--
-- This plugin is lazy: the src and its trigger filetypes are declared at the
-- bottom of this file via utils.lazy.setup, which defers the plugin/ scripts
-- until the first tex/latex buffer and calls configure() (below) right
-- before the :packadd (VimTeX reads these globals when it initializes for
-- the buffer).
--
-- The LaTeX writing-mode setup (wrapping, conceal, readable width and
-- <localleader>x compile/view/TOC mappings) lives in after/ftplugin/tex.lua.
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

local M = {}

-- Triggered only once per session, by utils/lazy before the vimtex packadd.
function M.configure()
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
end

-- After a successful compilation, copy the PDF from .build/ to exports/.
-- Kept global (registered once at startup): it is cheap and only fires on
-- the VimtexEventCompileSuccess user event, which exists only when vimtex
-- is loaded.
vim.api.nvim_create_autocmd("User", {
	pattern = "VimtexEventCompileSuccess",
	group = vim.api.nvim_create_augroup("latex_export_pdf", { clear = true }),
	callback = function()
		local exports = require("shared.exports")
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

-- Declares this plugin as lazy (see the pattern in lua/utils/lazy.lua):
-- the module only registers the spec here; configure() runs on the first
-- tex/latex buffer, before the :packadd.
require("utils.lazy").setup({
	-- vimtex
	-- https://github.com/lervag/vimtex
	-- Full LaTeX support: compilation, PDF viewer sync, motions, folding, and TOC.
	src = "https://github.com/lervag/vimtex",
	filetypes = { "tex", "latex" },
	configure = M.configure,
})

return M
