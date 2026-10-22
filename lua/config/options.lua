-- lua/options.lua

-- General behavior
vim.opt.hidden = true
vim.opt.history = 10000
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.timeoutlen = 500
vim.opt.showtabline = 0
vim.opt.ttimeoutlen = 30
vim.opt.switchbuf = "uselast"
vim.opt.exrc = true
vim.opt.showcmd = false
vim.opt.secure = true
vim.opt.mouse = ""
vim.opt.wrap = false
vim.opt.startofline = false
vim.opt.list = false
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
vim.opt.backspace = "indent,eol,start"
vim.opt.belloff = "all"
vim.opt.matchpairs:append("<:>")
vim.opt.nrformats:remove("octal")
vim.opt.isfname:append("@-@")
vim.opt.formatoptions:remove("o")
vim.opt.clipboard = "unnamedplus"
vim.opt.virtualedit = "block"
vim.opt.jumpoptions = "view"

-- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2

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
vim.opt.display:append("lastline")
vim.opt.more = true

-- Messages
vim.opt.shortmess:append("aIWsF")
vim.opt.shortmess:remove("S")

-- Folding
vim.opt.foldmethod = "manual"
vim.opt.foldlevel = 99
vim.opt.foldopen:remove("hor")

-- Persistence
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.o.sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds,terminal"

-- Cursor
vim.opt.guicursor = "a:block"
