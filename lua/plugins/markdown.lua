-- lua/plugins/markdown.lua

return {
  -- Make sure the markdown parsers are present for everything below
  -- (obsidian's own LSP, treesitter folding, etc).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "markdown", "markdown_inline" })
      return opts
    end,
  },

  -- Smart lists
  {
    "gaoDean/autolist.nvim",
    ft = { "markdown" },
    config = function()
      require("autolist").setup({})

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(args)
          local map = function(mode, lhs, rhs, desc, opts)
            opts = opts or {}
            vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", {
              buffer = args.buf,
              silent = true,
              desc = desc,
            }, opts))
          end

          map("i", "<CR>", function()
            local ok, blink = pcall(require, "blink.cmp")
            if ok and blink.is_visible and blink.is_visible() then
              return blink.select_and_accept()
            end
            return "<CR><cmd>AutolistNewBullet<cr>"
          end, "Confirm completion, or continue the list", { expr = true })

          map("n", "o", "o<cmd>AutolistNewBullet<cr>", "New line, continuing the list")
          map("n", "O", "O<cmd>AutolistNewBulletBefore<cr>", "New line above, continuing the list")
          map("n", "<leader>lr", "<cmd>AutolistRecalculate<cr>", "Recalculate list numbering")

          vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
            buffer = args.buf,
            callback = function()
              require("autolist").recalculate()
            end,
          })
        end,
      })
    end,
  },

  -- Markdown linting (style/consistency issues prettier won't catch:
  -- duplicate headings, bad heading hierarchy, trailing punctuation in
  -- headings, etc). The binary is pulled in automatically below.
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

  -- Installs non-LSP CLI tools through Mason automatically, the same
  -- way mason-lspconfig's ensure_installed does for language servers.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "markdownlint-cli2" },
    },
  },
}
