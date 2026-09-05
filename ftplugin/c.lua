-- ftplugin/c.lua
-- Following the linux kernel coding style.
-- Ref: https://www.kernel.org/doc/html/v4.10/process/coding-style.html
--
-- Confirmed against Documentation/process/coding-style.rst and the
-- kernel's own .editorconfig: tabs are 8 characters, indentation is
-- always 8 characters, spaces are never used for indentation.

-- Indentation: 8-character tabs, never spaces
vim.opt_local.expandtab = false
vim.opt_local.smarttab = false
vim.opt_local.tabstop = 8
vim.opt_local.shiftwidth = 8
vim.opt_local.softtabstop = 8

-- 80-column preferred limit (coding-style.rst section 2: "preferred
-- limit", not a hard cap -- exceeding it is fine when it improves
-- readability)
vim.opt_local.textwidth = 80

-- Syntax-aware auto-indentation for C (braces, switch/case, etc.).
-- The kernel doc only ships an official Emacs config for this
-- (c-basic-offset 8, case-label 0, etc.) -- there's no equivalent
-- "official" Neovim config, so this is a reasonable approximation:
-- align switch/case in the same column, don't double-indent case.
vim.opt_local.cindent = true
vim.opt_local.cinoptions = ":0,l1,t0,g0,(0"

-- Keep multi-line comments formatted and indented on continuation
vim.opt_local.formatoptions:append("croql")

-- Flag trailing whitespace, which coding-style.rst explicitly calls out
vim.opt_local.list = false
vim.opt_local.listchars = "tab:> ,trail:-,extends:>,precedes:<"
