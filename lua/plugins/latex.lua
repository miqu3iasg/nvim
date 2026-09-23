-- lua/plugins/latex.lua

-- The .tex writing-mode setup (wrap, conceallevel, readable width,
-- <leader>x compile/view/toc keymaps) lives in lua/langs/latex/,
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
--     - https://github.com/kylechui/nvim-surround

return {
  -- Core LaTeX engine, continuous compilation, PDF viewer sync
  -- (forward/inverse search), TOC panel, LaTeX-aware folding, motions
  -- and text objects (e.g. `dae` deletes an environment, `]]`/`[[`
  -- jumps sections). texlab (already configured) still handles
  -- diagnostics/completion/go-to-definition on top of this.
  {
    "lervag/vimtex",
    ft = { "tex" },
    init = function()
      -- Swap "zathura" for "skim" on macOS or "sumatrapdf" on Windows.
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        continuous = 1,
        -- This used to be `build_dir`, which vimtex renamed to
        -- `out_dir` in v2.13 (build_dir is now silently ignored). This is
        -- relative to the .tex file's own directory (exports/build/), so
        -- everything latexmk generates (.aux, .log, .fls, .fdb_latexmk,
        -- .synctex.gz, and the .pdf itself) goes into exports/build/output/,
        -- with nothing left behind next to the .tex file.
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

      -- Concealment for \alpha, sub/superscripts, etc. Mirrors the
      -- conceallevel = 2 used for markdown.
      -- vim.g.vimtex_syntax_conceal = {
      --   accents = true,
      --   cites = true,
      --   fancy = true,
      --   greek = true,
      --   math_bounds = true,
      --   sections = false,
      --   styles = true,
      -- }
      vim.g.vimtex_syntax_conceal_disable = true

      -- Citation completion: use vimtex's "simple" algorithm (plain
      -- cite-key matching) instead of its default "smart" one (a fuzzy
      -- search over titles/authors done by vimtex itself). vimtex's own
      -- docs recommend "simple" whenever an autocomplete plugin is
      -- driving the menu (see :h g:vimtex_complete_bib) -- here that's
      -- cmp-vimtex -> blink.cmp, which already does its own fuzzy
      -- matching, so "smart" mode was redundant work and slower to
      -- populate. The title/author/year still show up, just in the
      -- documentation window instead of being searched directly.
      vim.g.vimtex_complete_bib = {
        simple = 1,
        info_fmt = "@author_all (@year)\n@title",
      }

      -- After every successful compile, copy the resulting PDF out of
      -- exports/build/output/ up into exports/, so exports/ only ever
      -- shows the final PDFs and build/ (plus build/output/) only ever
      -- holds the source + compilation byproducts.
      vim.api.nvim_create_autocmd("User", {
        pattern = "VimtexEventCompileSuccess",
        group = vim.api.nvim_create_augroup("latex_export_pdf", { clear = true }),
        callback = function()
          local state = vim.b.vimtex
          local tex_file = (state and state.tex) or vim.fn.expand("%:p")
          if tex_file == "" then
            return
          end

          local build_dir = vim.fn.fnamemodify(tex_file, ":h")    -- .../exports/build
          local basename = vim.fn.fnamemodify(tex_file, ":t:r")   -- note name, no extension
          local src = build_dir .. "/output/" .. basename .. ".pdf"
          local exports_dir = vim.fn.fnamemodify(build_dir, ":h") -- .../exports
          local dest = exports_dir .. "/" .. basename .. ".pdf"

          if vim.fn.filereadable(src) == 0 then
            return
          end

          local uv = vim.uv or vim.loop
          uv.fs_copyfile(src, dest, function(err)
            if err then
              vim.schedule(function()
                vim.notify(
                  "vimtex: Failed to copy PDF to exports/ (" .. err .. ")",
                  vim.log.levels.ERROR
                )
              end)
            end
          end)
        end,
      })
    end,
  },

  -- Completion for \cite{}, \ref{}, labels, environments, packages,
  -- wired into blink.cmp through blink.compat (blink has no native
  -- vimtex source, this is the same bridge used below for
  -- cmp-latex-symbols).
  { "micangl/cmp-vimtex",        ft = { "tex" } },

  -- LaTeX symbol completion (\alpha, \sum, \Rightarrow -> shown with
  -- their preview glyph) for both real .tex files and math typed
  -- inside markdown/Obsidian notes.
  { "kdheepak/cmp-latex-symbols" },

  -- Bridges old nvim-cmp-only sources (both above) into blink.cmp.
  { "saghen/blink.compat",       version = "*", lazy = true, opts = {} },

  -- Extends the blink.cmp spec that already exists in completions.lua
  -- (lazy.nvim merges specs for the same plugin across files) instead
  -- of duplicating its whole config here.
  {
    "saghen/blink.cmp",
    dependencies = { "saghen/blink.compat", "micangl/cmp-vimtex", "kdheepak/cmp-latex-symbols" },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}

      -- score_offset raised from the shared default (50 for most
      -- extra sources) to 80: in a .tex buffer, a \ref/\cite/\alpha
      -- match should almost always outrank a same-looking word pulled
      -- from the buffer or from ripgrep.
      opts.sources.providers.latex_symbols = {
        name = "latex_symbols",
        module = "blink.compat.source",
        score_offset = 80,
      }
      opts.sources.providers.vimtex = {
        name = "vimtex",
        module = "blink.compat.source",
        score_offset = 80,
      }

      -- latex_symbols is useful in both tex and markdown (Obsidian
      -- math); vimtex's own source (citations/refs/labels) only
      -- makes sense in real .tex files.
      opts.sources.per_filetype = opts.sources.per_filetype or {}

      -- Listed explicitly (rather than derived from opts.sources.default)
      -- so that "lazydev" -- irrelevant outside Lua buffers -- isn't
      -- carried into every .tex buffer's candidate list for no reason.
      opts.sources.per_filetype.tex = { "lsp", "path", "snippets", "vimtex", "latex_symbols", "buffer", "ripgrep" }
      opts.sources.per_filetype.markdown =
          vim.list_extend(vim.deepcopy(opts.sources.default), { "latex_symbols" })

      return opts
    end,
  },

  -- Makes sure the `latex` treesitter grammar is present so that
  -- markdown_inline can inject it into $...$ / $$...$$ regions (this
  -- is what lets render-markdown.nvim, below, actually see the math).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "latex" })
      return opts
    end,
  },

  -- Converts math inside markdown/Obsidian notes into readable
  -- Unicode inline (e.g. \alpha -> α, x^2 -> x²), the same idea as
  -- render-markdown's heading/checkbox rendering. Requires the
  -- pylatexenc Python package -- see the note at the bottom of this
  -- file.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = function(_, opts)
      opts.latex = {
        enabled = true,
      }
      return opts
    end,
  },

  -- Installs latexindent (the formatter referenced in the conform.lua
  -- edit below) through Mason automatically. See libcrypt note above.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "latexindent" })
      return opts
    end,
  },

  -- Structural "surround" text objects (ys, ds, cs). Set up with empty
  -- defaults here (parentheses, quotes, tags, ...); the LaTeX-specific
  -- surrounds ($, \text{}, \left(\right)) are added per-buffer by
  -- lua/langs/latex/surround.lua, loaded from ftplugin/tex.lua, so they
  -- only apply in .tex buffers and never shadow the defaults elsewhere.
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },
}
