-- lua/plugins/markdown.lua

return {
  -- Markdown parsers for treesitter highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "markdown", "markdown_inline" })
      return opts
    end,
  },

  -- Markdown linting (duplicate headings, bad hierarchy, etc)
  {
    "mfussenegger/nvim-lint",
    ft = { "markdown" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = lint.linters_by_ft or {}
      lint.linters_by_ft.markdown = { "markdownlint-cli2" }

      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        pattern = { "*.md", "*.markdown" },
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },

  -- Installs the linter binary through Mason automatically
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "markdownlint-cli2" },
    },
  },
}
