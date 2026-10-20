-- lua/plugins/typescript.lua

local js_filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

---@module "lazy"
---@type LazySpec
return {
  {
    "windwp/nvim-ts-autotag",
    ft = {
      "html", "xml", "javascriptreact", "typescriptreact",
      "vue", "svelte", "php", "markdown",
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = true,
      },
    },
  },

  {
    "catgoose/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    init = function()
      if vim.lsp.document_color then
        vim.lsp.document_color.enable(false)
      end
    end,
    opts = {
      filetypes = {
        "css",
        "scss",
        "lua",
        "vue",
        "svelte",
        "astro",
        "html",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
      },
      user_default_options = {
        names = false,
        tailwind = false,
        -- mode = "virtualtext",
        -- virtualtext = "■",
        -- virtualtext_inline = "before",
      },
    },
  },
}
