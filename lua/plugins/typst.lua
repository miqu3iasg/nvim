-- lua/plugins/typst.lua

-- Typst support requires the following dependencies.
--
-- Language server (diagnostics, completion, hover, rename, PDF export):
-- tinymist is already listed in `ensure_installed` in plugins/lspconfig.lua,
-- so Mason installs it automatically. It can also be installed manually:
--
-- `:MasonInstall tinymist`
--
-- Formatter (used by conform.nvim in plugins/conform.lua):
-- typstyle.
--
-- Typst CLI (only needed for `typst watch` / `typst compile` in the terminal;
-- tinymist ships its own compiler):
-- typst.
--
-- On Arch Linux:
--
-- `sudo pacman -S typst typstyle`
--
-- Treesitter parser (highlighting):
--
-- `:TSInstall typst`
--
-- Live preview (plugins/typst.lua, installed by lazy.nvim):
-- chomosuke/typst-preview.nvim. It reuses the tinymist binary found on PATH.
--
-- Opening the exported PDF with <localleader>o uses `vim.ui.open`, which
-- needs xdg-utils and a default PDF viewer (e.g. zathura, sioyek, okular):
--
-- `sudo pacman -S xdg-utils zathura zathura-pdf-mupdf`
--
-- refs:
--     - https://github.com/Myriad-Dreamin/tinymist
--     - https://github.com/typstyle-rs/typstyle
--     - https://github.com/chomosuke/typst-preview.nvim
--     - https://typst.app/docs/
return {
  {
    "chomosuke/typst-preview.nvim",
    ft = "typst",
    version = "1.*",
    opts = {
      follow_cursor = true,
      dependencies_bin = { tinymist = "tinymist" }, -- use the Mason/system binary
    },
  },
}
