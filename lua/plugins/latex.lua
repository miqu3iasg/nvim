-- /home/miqu3iasg/.config/nvim/lua/plugins/latex.lua

-- The .tex writing-mode setup (wrap, conceallevel, readable width,
-- <leader>x compile/view/toc keymaps) lives in autocmds.lua,
-- alongside MarkdownWriting.
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
        options = {
          "-pdf",
          "-interaction=nonstopmode",
          "-synctex=1",
          "-auxdir=build",
        },
      }
      vim.g.vimtex_quickfix_mode = 0 -- don't steal focus on every warning
      vim.g.vimtex_fold_enabled = true
      vim.g.vimtex_indent_enabled = true
      -- Concealment for \alpha, sub/superscripts, etc. Mirrors the
      -- conceallevel = 2 used for markdown.
      vim.g.vimtex_syntax_conceal = {
        accents = true,
        cites = true,
        fancy = true,
        greek = true,
        math_bounds = true,
        sections = false,
        styles = true,
      }
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

      opts.sources.providers.latex_symbols = {
        name = "latex_symbols",
        module = "blink.compat.source",
        score_offset = 50,
      }
      opts.sources.providers.vimtex = {
        name = "vimtex",
        module = "blink.compat.source",
        score_offset = 50,
      }

      -- latex_symbols is useful in both tex and markdown (Obsidian
      -- math); vimtex's own source (citations/refs/labels) only
      -- makes sense in real .tex files.
      opts.sources.per_filetype = opts.sources.per_filetype or {}
      opts.sources.per_filetype.tex =
          vim.list_extend(vim.deepcopy(opts.sources.default), { "latex_symbols", "vimtex" })
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
  -- edit below) through Mason automatically.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "latexindent" })
      return opts
    end,
  },
}
