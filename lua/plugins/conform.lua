-- /home/miqu3iasg/.config/nvim/lua/plugins/conform.lua
return {
  "stevearc/conform.nvim",
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        purescript = { "purstidy", stop_after_first = true },
        lua = { "stylua", stop_after_first = true },
        ocaml = { "ocamlformat", stop_after_first = true },
        python = { "ruff_format" },
        rust = { "rustfmt" },
        java = { "google-java-format" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        astro = { "astro", stop_after_first = true },
        go = { "gofumpt", "golines", "goimports-reviser" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        haskell = { "fourmolu" },
        yaml = { "yamlfmt" },
        html = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        gleam = { "gleam" },
        asm = { "asmfmt" },
        css = { "prettierd", "prettier", stop_after_first = true },
        fennel = { "fnlfmt" },
        tex = { "latexindent" },
      },
      formatters = {
        ["google-java-format"] = {
          prepend_args = { "--skip-javadoc-formatting" },
        },
        clang_format = {
          prepend_args = { "--style=file" },
        },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    })
  end,
}
