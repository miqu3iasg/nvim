-- lua/config/options.lua

-- Side-effect-only file: sets global editor options at startup.
-- All options can be inspected with :options or :set all, and an individual
-- option's docs with :help 'name'. Options are grouped by topic; choices that
-- are not self-explanatory carry their own comment. Note that some plugins
-- override a few of these per-buffer (e.g. vim-sleuth adjusts indentation).

-- General behavior
vim.opt.hidden = true
vim.opt.history = 10000
vim.opt.timeoutlen = 500
vim.opt.showtabline = 0
vim.opt.ttimeoutlen = 30
-- Jump into the window that last showed a buffer instead of overwriting some other split
vim.opt.switchbuf = "uselast"
-- Hide the partly-typed command/count shown in the bottom-right corner
vim.opt.showcmd = false
-- Disable mouse support entirely
vim.opt.mouse = ""
vim.opt.wrap = false
-- Cursor keeps its column instead of jumping to line start on moves like gg/G
vim.opt.startofline = false
-- Show invisible characters (tuned below); this is toggled per-window by <leader>vl
vim.opt.list = true
vim.opt.listchars = { tab = "¬·", trail = "•", nbsp = "·", space = "·" }
vim.opt.diffopt:append({ "algorithm:histogram", "indent-heuristic", "linematch:60" })

-- Search and completion
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wildignorecase = true
vim.opt.wildignore:append({ "*/.git/*", "*/node_modules/*", "*/target/*", "*/dist/*" })
vim.opt.completeopt = "menuone,noselect"

-- Native fuzzy file/buffer finding via command-line
vim.opt.path:append("**")
vim.opt.wildmenu = true
vim.opt.wildmode = "noselect:lastused,full"
vim.opt.wildoptions = "pum,fuzzy"
vim.opt.pumheight = 15

-- Editing
-- Backspace always works past auto-indent, line breaks, and <C-w>/<C-u> insertions
vim.opt.backspace = "indent,eol,start"
vim.opt.belloff = "all"
-- Add < > so <Tab> (mapped to %) can jump between angle-bracket pairs
vim.opt.matchpairs:append("<:>")
vim.opt.nrformats:remove("octal")
vim.opt.isfname:append("@-@")
-- Do not let o/O auto-continue comments from the previous line
vim.opt.formatoptions:remove("o")
-- Yanks go straight to the system clipboard
vim.opt.clipboard = "unnamedplus"
-- In blockwise visual mode the cursor may move past the end of short lines
vim.opt.virtualedit = "block"
-- Returning to a jump restores the window view (scroll position), not just the cursor
vim.opt.jumpoptions = "view"
-- Treat hyphenated words (kebab-case, --flags) as single words
vim.opt.iskeyword:append("-")

-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.softtabstop = 4

-- Window layout
vim.opt.splitright = true
vim.opt.splitbelow = false
-- Statusline always visible even with a single window
vim.opt.laststatus = 2
vim.opt.winborder = "single"

-- Display
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 5
vim.opt.cmdheight = 1
vim.opt.signcolumn = "no"
vim.opt.termguicolors = true
vim.opt.title = false
vim.opt.titlestring = "%t"
vim.opt.background = "dark"
vim.opt.display:append("lastline")
vim.opt.more = true

-- Messages
-- a: aggregate abbreviations, I: no intro screen, W: no "written" message,
-- s: no "N lines changed" message, F: no filename message on open
vim.opt.shortmess:append("aIWsF")
-- Keep S removed so the search count (1/123) is still displayed
vim.opt.shortmess:remove("S")

-- Folding: folds are created manually (zf) and always start open
vim.opt.foldmethod = "manual"
vim.opt.foldlevel = 99
-- Horizontal motions (left/right) never force closed folds open
vim.opt.foldopen:remove("hor")

-- Persistence
-- No swap or backup files; undo history is persisted across restarts instead
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undolevels = 10000
-- Matches what lua/features/sessions.lua saves and restores
vim.o.sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds,terminal"

-- Cursor
vim.opt.guicursor = "a:block"
