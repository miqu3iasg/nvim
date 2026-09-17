-- ftplugin/tex.lua

-- This file MUST be named `tex.lua`, not `latex.lua`.
-- Neovim's ftplugin autoload is keyed off the buffer's `filetype`
-- value, and for .tex files that value is "tex" (not "latex");
-- see vimtex's `ft = { "tex" }`, lspconfig's `texlab`, conform's
-- `tex = { "latexindent" }`, and `load_snippets("tex", ...)` above.
--
-- Renaming this back to `latex.lua` will silently stop it from
-- being sourced when a .tex buffer is opened, and the langs.latex
-- keymaps/settings won't be applied (vimtex commands will still
-- work when typed manually, since the plugin itself loads fine,
-- only the buffer-local keymaps depend on this file running).
--
-- The `langs.latex` module name below is unrelated to this
-- constraint; it's just this project's own naming convention.

require("langs.latex").setup()
