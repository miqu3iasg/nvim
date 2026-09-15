-- lua/plugins/conform.lua

-- Conform.nvim uses external formatter executables.
-- Mason can install many of the formatters configured below, but
-- some dependencies may need to be installed manually on your machine.
--
-- For JavaScript, TypeScript, HTML, CSS, JSON, and Markdown formatting,
-- install Node.js and npm if they are not already available:
--
-- `sudo pacman -S nodejs npm`
--
-- Prettier and Prettierd can be installed through Mason.
-- Alternatively, install them globally via npm:
--
-- `npm install -g prettier prettierd`
--
-- Prettierd is preferred when available. Conform falls back to Prettier
-- through `stop_after_first = true`.
--
-- Astro formatting requires the Astro CLI to be available.
-- Install Astro through your project dependencies:
--
-- `npm install astro`
--
-- The `astro` formatter must be available through the project's
-- local dependencies or the configured executable path.
--
-- C and C++ formatting requires clang-format.
-- On Arch Linux:
--
-- `sudo pacman -S clang`
--
-- Go formatting requires Go to be installed.
-- On Arch Linux:
--
-- `sudo pacman -S go`
--
-- LaTeX formatting requires a TeX distribution and latexindent.
-- On Arch Linux:
--
-- `sudo pacman -S texlive-basic texlive-bin texlive-latexextra texlive-fontsextra`
--
-- Mason can install the remaining formatters used in this configuration,
-- including Stylua, Ruff, Rustfmt, Google Java Format, Fourmolu,
-- yamlfmt, and other supported formatters.
--
-- Make sure the formatter executables are available on PATH
-- when Conform.nvim attempts to run them.
--
-- refs:
--     - https://github.com/stevearc/conform.nvim
--     - https://github.com/prettier/prettier
--     - https://github.com/fsouza/prettierd
--     - https://docs.astro.build/
--     - https://github.com/cmhughes/latexindent.pl
--     - https://clang.llvm.org/docs/ClangFormat.html
--     - https://go.dev/

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
          -- this file must be located in `~/.clang-format`. We have an example
          -- of this file in `lua/clang-format.example.yaml`.
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
