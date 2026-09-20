-- lua/plugins/conform.lua

-- Conform.nvim uses external formatter executables.
-- Mason can install many of the formatters configured below, but
-- some dependencies may need to be installed manually on your machine.
--
-- For JavaScript, TypeScript, HTML, CSS, JSON, Markdown, GraphQL and Vue
-- formatting, install Node.js and npm if they are not already available:
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
-- Shell formatting requires shfmt.
-- On Arch Linux:
--
-- `sudo pacman -S shfmt`
--
-- SQL formatting uses sql-formatter (Node-based).
--
-- `npm install -g sql-formatter`
--
-- TOML formatting requires taplo.
-- On Arch Linux:
--
-- `sudo pacman -S taplo-cli`
--
-- XML formatting requires xmlformatter (Python-based).
--
-- `pip install xmlformatter`
--
-- Ruby formatting requires rubocop.
--
-- `gem install rubocop`
--
-- Elixir formatting uses `mix format`, bundled with Elixir itself.
-- On Arch Linux:
--
-- `sudo pacman -S elixir`
--
-- Nix formatting requires nixfmt.
-- On Arch Linux:
--
-- `sudo pacman -S nixfmt`
--
-- Terraform formatting uses `terraform fmt`, bundled with Terraform itself.
--
-- Perl formatting requires Perl::Tidy.
--
-- `sudo pacman -S perltidy`
--
-- R formatting requires the `styler` R package.
--
-- `R -e 'install.packages("styler")'`
--
-- Scala formatting requires scalafmt.
-- On Arch Linux:
--
-- `sudo pacman -S scalafmt`
--
-- Julia formatting requires the `runic` package/binary.
--
-- Elm formatting requires elm-format.
--
-- `npm install -g elm-format`
--
-- Clojure formatting requires cljfmt.
--
-- Dockerfile formatting requires dockerfmt.
--
-- Protobuf formatting requires the Buf CLI.
-- On Arch Linux:
--
-- `sudo pacman -S buf`
--
-- Most of the remaining formatters (Stylua, Ruff, Rustfmt, Google Java
-- Format, Fourmolu, yamlfmt, shfmt, sql-formatter, taplo, ktlint,
-- swiftformat, csharpier, zigfmt, etc.) can be installed through Mason.
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
--     - https://github.com/mvdan/sh
--     - https://github.com/sql-formatter-org/sql-formatter
--     - https://taplo.tamasfe.dev/
--     - https://github.com/rubocop/rubocop
--     - https://hexdocs.pm/mix/Mix.Tasks.Format.html
--     - https://github.com/NixOS/nixfmt
--     - https://github.com/bufbuild/buf

return {
  "stevearc/conform.nvim",
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        -- Systems / compiled languages
        lua = { "stylua" },
        rust = { "rustfmt" },
        go = { "gofumpt", "golines", "goimports-reviser" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        zig = { "zigfmt" },
        csharp = { "csharpier" },
        swift = { "swiftformat" },
        kotlin = { "ktlint" },
        java = { "google-java-format" },
        scala = { "scalafmt" },

        -- Functional languages
        haskell = { "fourmolu" },

        -- Scripting
        python = { "ruff_format" },
        ruby = { "rubocop" },
        php = { "php_cs_fixer" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        perl = { "perltidy" },

        -- Web / frontend
        javascript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        vue = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        scss = { "prettierd", "prettier", stop_after_first = true },
        graphql = { "prettierd", "prettier", stop_after_first = true },

        -- Data / config formats
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "yamlfmt" },
        toml = { "taplo" },
        xml = { "xmlformatter" },
        sql = { "sql_formatter" },
        dockerfile = { "dockerfmt" },
        terraform = { "terraform_fmt" },

        -- Docs
        markdown = { "prettierd", "prettier", stop_after_first = true },
        tex = { "latexindent" },

        -- Misc
        asm = { "asmfmt" },

        -- Fallback for filetypes not explicitly configured above:
        -- just trims trailing whitespace and extra blank lines,
        -- so `format_on_save` never silently no-ops.
        ["_"] = { "trim_whitespace", "trim_newlines" },
      },
      formatters = {
        ["google-java-format"] = {
          prepend_args = { "--skip-javadoc-formatting" },
        },
        clang_format = {
          -- this file must be located in `~/.clang-format`. We have an example
          -- of this file in `assets/templates/clang-format.example.yaml`.
          prepend_args = { "--style=file" },
        },
        shfmt = {
          -- 2-space indentation, matching common shell style guides
          prepend_args = { "-i", "2" },
        },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    })
  end,
}
