-- lua/plugins/latex.lua
--
-- LaTeX support through VimTeX, covering compilation, PDF viewer sync, motions,
-- folding and the table of contents, plus a hook that copies the compiled PDF
-- to `exports/`.
--
-- VimTeX is loaded lazily. The plugin is declared at the bottom of this file
-- and its scripts are only loaded on the first tex buffer, right after
-- `configure()` sets the globals that VimTeX reads when it initializes.
--
-- A full TeX distribution is required to compile documents, along with a PDF
-- viewer with SyncTeX support and the dependencies of latexindent, which handles
-- indentation and formatting. On Arch Linux, install the TeX Live packages with:
--
-- $ sudo pacman -S texlive-basic texlive-bin texlive-latexextra texlive-fontsextra
--
-- Zathura is the PDF viewer and needs its MuPDF backend for viewing and SyncTeX:
--
-- $ sudo pacman -S zathura zathura-pdf-mupdf
--
-- latexindent is installed automatically through Mason. It may require
-- `libcrypt.so.1`, which is missing on systems that use libxcrypt. On Arch
-- Linux, install the compatibility library with:
--
-- $ sudo pacman -S libxcrypt-compat
--
-- See: after/ftplugin/tex.lua
-- See: lua/utils/lazy.lua
-- See: lua/shared/exports.lua
-- See: https://github.com/lervag/vimtex
-- See: https://github.com/cmhughes/latexindent.pl
-- See: https://github.com/latex3/latex2e

local M = {}

-- Filetype detection must produce `tex` instead of the builtin `plaintex` for
-- the lazy loading to fire. VimTeX's own ftdetect sets this, but a lazy plugin
-- is not on the runtimepath at detection time, so it is set here.
vim.g.tex_flavor = "latex"

---Set the VimTeX globals. Called once per session by `utils.lazy`, before VimTeX
---is loaded.
function M.configure()
	local exports = require("shared.exports")

	vim.g.vimtex_view_method = "zathura"
	vim.g.vimtex_compiler_method = "latexmk"
	vim.g.vimtex_compiler_latexmk = {
		continuous = 1,
		-- Byproducts and the first PDF go to `<root>/.build/<reldir>/<name>/`.
		-- It is a function because the folder depends on the project.
		out_dir = function()
			return exports.build_dir(vim.api.nvim_get_current_buf())
		end,
		options = {
			"-pdf",
			"-interaction=nonstopmode",
			"-synctex=1",
		},
	}
	-- Avoids stealing focus for every warning.
	vim.g.vimtex_quickfix_mode = 0
	vim.g.vimtex_fold_enabled = true
	vim.g.vimtex_indent_enabled = true
	vim.g.vimtex_syntax_conceal_disable = true

	-- Plain citation-key matching, which the VimTeX documentation recommends over
	-- the default search through titles and authors when another source provides
	-- the completion menu.
	-- See: :help g:vimtex_complete_bib
	vim.g.vimtex_complete_bib = {
		simple = 1,
		info_fmt = "@author_all (@year)\n@title",
	}
end

-- Registered globally at startup because it is cheap and only fires on a user
-- event that exists while VimTeX is loaded.
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

require("utils.lazy").setup({
	src = "https://github.com/lervag/vimtex",
	filetypes = { "tex", "latex" },
	configure = M.configure,
})

return M
