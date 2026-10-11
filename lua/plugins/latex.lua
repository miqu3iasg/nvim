-- lua/plugins/latex.lua

-- The .tex writing-mode setup (wrap, conceallevel, readable width,
-- <localleader>x compile/view/toc keymaps) lives in lua/langs/latex/,
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
--     - https://github.com/echasnovski/mini.surround
--     - https://github.com/echasnovski/mini.pairs

-- Augroup shared by the buffer-local mini.pairs / nvim-surround
-- overrides below. Both only apply to .tex buffers.
local tex_group = vim.api.nvim_create_augroup("latex_buffer_plugins", { clear = true })

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
      -- driving the menu (see :h g:vimtex_complete_bib)
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

  -- Buffer-local mini.pairs overrides for .tex files.
  --
  -- mini.pairs normally prevents "(" and "[" from pairing when the
  -- preceding character is a backslash (neigh_pattern = "[^\\].").
  -- This is unsuitable for LaTeX, where "\(" and "\[" are math
  -- delimiters rather than escaped brackets. Using ".." makes these
  -- delimiters pair normally, producing "\)" and "\]" as expected.
  --
  -- "$" is not a default pair because it uses the same character to
  -- open and close. A "closeopen" rule is therefore added so typing
  -- the second "$" moves past the existing character instead of
  -- creating a nested pair ("$$" -> "$$$$"). The backslash guard
  -- remains to prevent escaped dollar signs (e.g. "\$5") from pairing.
  --
  -- Refs:
  --     - https://github.com/echasnovski/mini.pairs
  --     - :h MiniPairs.map_buf()
  {
    "echasnovski/mini.pairs",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = tex_group,
        pattern = "tex",
        callback = function(args)
          local ok, pairs_mod = pcall(require, "mini.pairs")
          if not ok then
            return
          end

          local bufnr = args.buf

          -- "register.cr = false": a bare <CR> after the opening character
          -- does not close the pair, matching mini.pairs' default behavior;
          -- only the pairing pattern is overridden here.
          local always = { register = { cr = false }, neigh_pattern = ".." }

          pairs_mod.map_buf(bufnr, "i", "(", vim.tbl_extend("force", { action = "open", pair = "()" }, always))
          pairs_mod.map_buf(bufnr, "i", ")", vim.tbl_extend("force", { action = "close", pair = "()" }, always))
          pairs_mod.map_buf(bufnr, "i", "[", vim.tbl_extend("force", { action = "open", pair = "[]" }, always))
          pairs_mod.map_buf(bufnr, "i", "]", vim.tbl_extend("force", { action = "close", pair = "[]" }, always))

          pairs_mod.map_buf(bufnr, "i", "$", {
            action = "closeopen",
            pair = "$$",
            neigh_pattern = "[^\\].",
            register = { cr = false },
          })
        end,
      })
    end,
  },

  -- Structural "surround" text objects (sa, sd, sr). Set up with the
  -- defaults globally (parentheses, quotes, tags, ...); the LaTeX-specific
  -- surroundings are added per-buffer through `vim.b.minisurround_config`
  -- in .tex files, so they never shadow the defaults elsewhere.
  --
  -- LaTeX-specific surroundings:
  --
  -- "$" for inline math, "x" for \text{}, and "l" for \left...\right.
  --
  -- Usage:
  --
  --   saiw$   -> $x$
  --   sd$     -> x
  --   sr$x    -> \text{x}
  --
  --   saiwx   -> \text{hello}
  --   sdx     -> hello
  --   srx$    -> $x$
  --
  --   saiwl   -> \left(x+y\right)
  --   sdl     -> x+y
  --
  -- "x" is used for \text{} instead of "t" to avoid overriding the
  -- default HTML/XML tag surrounding.
  --
  -- In `input` patterns, the two empty captures "()" mark where the
  -- surrounded text starts and ends; everything outside them is the
  -- surrounding itself.
  --
  -- Refs:
  --     - https://github.com/echasnovski/mini.surround
  --     - :h MiniSurround-surrounding-specification
  {
    "echasnovski/mini.surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = tex_group,
        pattern = "tex",
        callback = function(args)
          vim.b[args.buf].minisurround_config = {
            custom_surroundings = {
              ["$"] = {
                input = { "%$().-()%$" },
                output = { left = "$", right = "$" },
              },
              ["x"] = {
                input = { "\\text{().-()}" },
                output = { left = "\\text{", right = "}" },
              },
              ["l"] = {
                input = { "\\left%(().-()\\right%)" },
                output = { left = "\\left(", right = "\\right)" },
              },
            },
          }
        end,
      })
    end,
  },
}
