-- lua/config/options.lua

-- Global editor options, set at startup.
-- See all options with :options or :set all, and an option's help with :help 'name'.

-- GREP is rg; :grep and the quickfix machinery use ripgrep when available
if vim.fn.executable("rg") == 1 then
	vim.opt.grepprg = "rg --vimgrep"
end

-- General behavior
vim.opt.hidden = true
vim.opt.history = 10000
-- vim.opt.timeoutlen = 1000
-- vim.opt.ttimeoutlen = 30
vim.opt.showtabline = 0
vim.opt.switchbuf = "uselast" -- Jump to the window that last showed the buffer
vim.opt.showcmd = false
vim.opt.mouse = ""
vim.opt.wrap = false
vim.opt.startofline = false -- Keep the cursor column on gg/G
vim.opt.list = true
vim.opt.listchars = { tab = "¬·", trail = "•", nbsp = "·", space = "·" }
vim.opt.diffopt:append({ "algorithm:histogram", "indent-heuristic", "linematch:60" })

-- Search and completion
vim.opt.ignorecase = true
vim.opt.smartcase = true -- Case-sensitive only if the pattern has uppercase
vim.opt.wildignorecase = true
vim.opt.wildignore:append({ "*/.git/*", "*/node_modules/*", "*/target/*", "*/dist/*" })
vim.opt.completeopt = "menuone,noselect"

-- Native fuzzy finding via command-line
vim.opt.path:append("**") -- Recursive :find and gf
vim.opt.wildmenu = true
vim.opt.wildmode = "noselect:lastused,full"
vim.opt.wildoptions = "pum,fuzzy"
vim.opt.pumheight = 15

-- Editing
vim.opt.backspace = "indent,eol,start"
vim.opt.belloff = "all"
vim.opt.matchpairs:append("<:>") -- Lets % jump between angle brackets
vim.opt.nrformats:remove("octal")
vim.opt.isfname:append("@-@")
vim.opt.formatoptions:remove("o") -- No comment continuation on o/O
vim.opt.clipboard = "unnamedplus" -- Yanks go to the system clipboard
vim.opt.virtualedit = "block" -- Cursor can pass line end in blockwise visual mode
vim.opt.jumpoptions = "view" -- Restore scroll position on jumps
vim.opt.iskeyword:append("-") -- Treat kebab-case as one word

-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

-- Window layout
vim.opt.splitright = true
vim.opt.splitbelow = true
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
-- a: abbreviations, I: no intro, W: no "written", s: no "N lines changed", F: no filename
vim.opt.shortmess:append("aIWsF")
vim.opt.shortmess:remove("S") -- Keep the search count (1/123)

-- Folding: manual (zf), always start open
vim.opt.foldmethod = "manual"
vim.opt.foldlevel = 99
vim.opt.foldopen:remove("hor") -- Horizontal motions don't open folds

-- Persistence: no swap/backup, persistent undo instead
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undolevels = 10000
-- Must match what lua/features/sessions.lua saves and restores
vim.o.sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds,terminal"

-- Cursor
vim.opt.guicursor = "a:block"
