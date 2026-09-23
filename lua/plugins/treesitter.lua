-- lua/plugins/treesitter.lua

---@module "lazy"
---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {},
  lazy = false,
  branch = "main",
  build = ":TSUpdate",
  config = function()
    vim.env.PYTHONIOENCODING = "utf-8"
    local ts = require("nvim-treesitter")
    ts.install({
      "typst",
      "purescript",
      "vimdoc",
      "go",
      "rust",
      "c",
      "lua",
      "python",
      "html",
      "css",
      "java",
      "javascript",
      "typescript",
      "haskell",
      "zig",
      "gleam",
      "wgsl",
      "php",
      "nim",
      "sql",
      "markdown",
      "markdown_inline",
      "latex",
      "bash",
      "yaml",
      "json",
      "toml",
      "ruby",
      "c_sharp",
      "dockerfile",
      "terraform",
      "cmake",
      "fortran",
    }, {
      max_jobs = 4,
    })

    local group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true })

    -- Filetypes where a legacy :syntax engine must stay in charge of
    -- highlighting instead of Treesitter. vimtex ships its own syntax
    -- file (tex*, texCmd*, texMathZone*, ...) and relies on it for both
    -- highlighting and its conceal rules (accents, greek letters, math
    -- bounds, etc). If Treesitter also attaches to the buffer, its
    -- captures win and vimtex's groups (and any colorscheme highlights
    -- built on top of them) never get applied.
    --
    -- The `latex` parser is still installed above, it's needed for
    -- markdown_inline to inject LaTeX math highlighting inside
    -- $...$/$$...$$ regions in markdown buffers (see render-markdown.nvim
    -- in lua/plugins/latex.lua). It just must never attach directly to
    -- a `tex` buffer.
    --
    -- Refs:
    --     - :h vimtex-faq-treesitter
    --     - https://github.com/lervag/vimtex/wiki/Syntax
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
  end,
}
