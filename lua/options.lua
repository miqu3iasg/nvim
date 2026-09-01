-- General behavior
vim.g.netrw_banner = 0
vim.opt.hidden = true
vim.opt.autoread = true
vim.opt.history = 10000
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 30
vim.opt.updatetime = 300
vim.opt.switchbuf = "uselast"
vim.opt.exrc = true
vim.opt.secure = true

-- Search and completion
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wildignorecase = true
vim.opt.wildignore:append("*/.git/*")
vim.opt.completeopt = "menuone,noselect,preview"
vim.opt.inccommand = "split"

-- Native fuzzy file/buffer finding via command-line
vim.opt.path:append("**")
vim.opt.wildignore:append({
  "*/node_modules/*", "*/target/*", "*/dist/*",
})
vim.opt.wildmenu = true
vim.opt.wildmode = "noselect:lastused,full"
if vim.fn.has("nvim-0.11") == 1 then
  vim.opt.wildoptions = "pum,fuzzy"
else
  vim.opt.wildoptions = "pum"
end
vim.opt.pumheight = 15

-- Editing
vim.opt.backspace = "indent,eol,start"
vim.opt.belloff = "all"
vim.opt.matchpairs:append("<:>")
vim.opt.nrformats:remove("octal")
vim.opt.isfname:append("@-@")
vim.opt.clipboard:append("unnamedplus")

-- Indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.bo.softtabstop = 2

-- Window layout
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.winminwidth = 0
vim.opt.winminheight = 0
vim.opt.laststatus = 0

-- Display
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.scrolloff = 15
vim.opt.cmdheight = 0
vim.opt.signcolumn = "no"
vim.opt.termguicolors = true
vim.opt.fillchars = { eob = " " }
vim.opt.shortmess:append("acFWIS")
vim.opt.display:append("lastline")

-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldnestmax = 1
vim.opt.foldopen:remove("hor")

-- Persistence
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undofile = true

-- Mouse
vim.opt.mouse = ""
vim.opt.mousescroll = "ver:0,hor:0"

-- Cursor
vim.opt.guicursor = "n-v-c:block-blinkon1-CursorInsert,i:block-CursorInsert"

-- Shell
local ok, utils = pcall(require, "utils")
local os_name = ok and utils.get_os() or "linux"
if os_name == "windows" then
  vim.opt.shell = "powershell"
else
  vim.opt.shell = "/bin/zsh"
end
vim.opt.shellcmdflag = "-c"
vim.opt.shellquote = ""
vim.opt.shellxquote = ""

-- Language-specific settings
vim.g.zig_fmt_parse_errors = 0

-- Diagnostics
vim.diagnostic.config({
  virtual_text = false,
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  float = {
    border = "single",
    source = true,
  },
})

-- Keep diagnostic messages out of the buffer
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { link = "DiagnosticError" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { link = "DiagnosticWarn" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { link = "DiagnosticHint" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { link = "DiagnosticInfo" })
