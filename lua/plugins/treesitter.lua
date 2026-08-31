---@module "lazy"
---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    {
      "nvim-treesitter/nvim-treesitter-context",
      enabled = false,
      opts = {
        max_lines = 4,
        multiline_threshold = 2,
      },
    },
  },
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
    }, {
      max_jobs = 1,
    })
    local group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true })
    -- Auto-install parsers and enable highlighting on FileType
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      desc = "Enable treesitter highlighting and indentation",
      callback = function(event)
        local lang = vim.treesitter.language.get_lang(event.match) or event.match
        local buf = event.buf
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
