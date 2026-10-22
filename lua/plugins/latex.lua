-- lua/plugins/latex.lua

-- The .tex writing-mode setup (wrap, conceallevel, readable width,
-- <localleader>x compile/view/toc keymaps) lives in after/ftplugin/latex/,
-- alongside MarkdownWriting.
--
-- For this configuration to work, you need a full TeX distribution,
-- a PDF viewer with SyncTeX support, and the dependencies required
-- by latexindent installed on your machine.
--
-- You can install the required dependencies on Arch Linux via:
--
-- `sudo pacman -S texlive-basic texlive-bin texlive-latexextra texlive-fontsextra`
--
-- A PDF viewer with SyncTeX support is also required. This configuration
-- uses the viewer specified by `vimtex_view_method`.
--
-- You can install Zathura and its PDF backend on Arch Linux via:
--
-- `sudo pacman -S zathura zathura-pdf-mupdf`
--
-- `latexindent` is installed through Mason, but it requires `libcrypt.so.1`,
-- which may be missing on systems that have moved to libxcrypt.
--
-- On Arch Linux, install the compatibility library using:
--
-- `sudo pacman -S libxcrypt-compat`
--
-- refs:
--     - https://github.com/lervag/vimtex
--     - https://github.com/cmhughes/latexindent.pl
--     - https://github.com/latex3/latex2e

local tex_group = vim.api.nvim_create_augroup("latex_buffer_plugins", { clear = true })

-- Core LaTeX engine
-- vim.pack: this was lazy's `init`. The plugin itself is installed in
-- lua/config/pack.lua; vimtex only reads these globals when it initializes
-- for a tex buffer (FileType/VimEnter), which happens after init.lua finishes
vim.g.vimtex_view_method = "zathura"
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_compiler_latexmk = {
	continuous = 1,
	-- This used to be `build_dir`, which vimtex renamed to
	-- `out_dir` in v2.13 (build_dir is now silently ignored). This is
	-- relative to the .tex file's own directory (exports/build/), so
	-- everything latexmk generates (.aux, .log, .fls, .fdb_latexmk,
	-- .synctex.gz, and the .pdf itself) goes into exports/build/output/,
	-- with nothing left behind next to the .tex file
	out_dir = "output",
	options = {
		"-pdf",
		"-interaction=nonstopmode",
		"-synctex=1",
	},
}
vim.g.vimtex_quickfix_mode = 0 -- don't steal focus on every warning
vim.g.vimtex_fold_enabled = true
vim.g.vimtex_indent_enabled = true

vim.g.vimtex_syntax_conceal_disable = true

-- Citation completion use vimtex's "simple" algorithm (plain
-- cite-key matching) instead of its default "smart" one (a fuzzy
-- search over titles/authors done by vimtex itself). vimtex's own
-- docs recommend "simple" whenever an autocomplete plugin is
-- driving the menu (see :h g:vimtex_complete_bib)
vim.g.vimtex_complete_bib = {
	simple = 1,
	info_fmt = "@author_all (@year)\n@title",
}

-- After every successful compile, copy the resulting PDF out of
-- exports/build/output/ up into exports/, so exports/ only ever
-- shows the final PDFs and build/ (plus build/output/) only ever
-- holds the source + compilation byproducts
vim.api.nvim_create_autocmd("User", {
	pattern = "VimtexEventCompileSuccess",
	group = vim.api.nvim_create_augroup("latex_export_pdf", { clear = true }),
	callback = function()
		local state = vim.b.vimtex
		local tex_file = (state and state.tex) or vim.fn.expand("%:p")
		if tex_file == "" then
			return
		end

		local build_dir = vim.fn.fnamemodify(tex_file, ":h")
		local basename = vim.fn.fnamemodify(tex_file, ":t:r")
		local src = build_dir .. "/output/" .. basename .. ".pdf"
		local exports_dir = vim.fn.fnamemodify(build_dir, ":h")
		local dest = exports_dir .. "/" .. basename .. ".pdf"

		if vim.fn.filereadable(src) == 0 then
			return
		end

		local uv = vim.uv or vim.loop
		uv.fs_copyfile(src, dest, function(err)
			if err then
				vim.schedule(function()
					vim.notify("vimtex: Failed to copy PDF to exports/ (" .. err .. ")", vim.log.levels.ERROR)
				end)
			end
		end)
	end,
})

-- Installs latexindent (the formatter referenced in the conform.lua
-- edit below) through Mason automatically. See libcrypt note above.
-- vim.pack: lazy merged `ensure_installed` across specs; here it's a single
-- setup call, so if another file also uses mason-tool-installer, merge the lists.
-- mason.nvim itself is set up in plugins/lsp.lua (loaded before this file)
require("mason-tool-installer").setup({
	ensure_installed = { "latexindent" },
})
