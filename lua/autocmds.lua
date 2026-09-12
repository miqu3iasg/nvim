--/home/miqu3iasg/.config/nvim/lua/autocmds.lua

-- Update the location list when diagnostics change
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function()
    vim.diagnostic.setloclist({ open = false })
  end,
})

-- Keep splits evenly sized after resizing
vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    if not vim.g.no_neck_pain_enabled then
      vim.cmd("wincmd =")
    end
  end,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Open Oil automatically when nvim is launched with no file argument
vim.api.nvim_create_augroup("OilOnStartup", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
  group = "OilOnStartup",
  nested = true,
  callback = function()
    vim.schedule(function()
      local argc = vim.fn.argc()
      if argc == 0 then
        require("oil").open()
      elseif argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
        require("oil").open(vim.fn.argv(0))
      end
    end)
  end,
})

-- Auto-create parent directories on save (skips virtual buffers like oil://, fugitive://, term://, etc.)
vim.api.nvim_create_augroup("CreateDirs", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = "CreateDirs",
  pattern = "*",
  callback = function(event)
    if event.match:match("^%w+://") then
      return
    end
    local file_path = vim.fn.expand("<afile>:p:h")
    if vim.fn.isdirectory(file_path) == 0 then
      vim.fn.mkdir(file_path, "p")
    end
  end,
})

-- Jump to last cursor position when opening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Jump to last cursor position when opening a file",
  callback = function(args)
    local valid_line = vim.fn.line([['"]]) >= 1 and vim.fn.line([['"]]) < vim.fn.line("$")
    local not_commit = vim.b[args.buf].filetype ~= "commit"
    if valid_line and not_commit then
      vim.cmd([[normal! g`"]])
    end
  end,
})

-- Keymap 'q' to close help/quickfix/netrw/etc windows
vim.api.nvim_create_autocmd("FileType", {
  desc = "keymap 'q' to close help/quickfix/netrw/etc windows",
  pattern = "help,qf,netrw",
  callback = function()
    vim.keymap.set("n", "q", "<C-w>c", { buffer = true, desc = "Quit (or Close) help, quickfix, netrw, etc windows" })
  end,
})

-- Open help/man pages in a right-side vertical split
vim.api.nvim_create_autocmd("FileType", {
  desc = "Open help/man pages in a right-side vertical split",
  pattern = { "help", "man" },
  command = "wincmd L",
})

-- Markdown note-writing setup
vim.api.nvim_create_augroup("MarkdownWriting", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = "MarkdownWriting",
  pattern = { "markdown" },
  callback = function(event)
    -- Visual wrapping, respecting word boundaries
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.showbreak = "  "
    -- Spell check
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { "pt_br", "en_us" }
    -- Cleaner reading view: no line numbers or sign column
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    -- Move by visual line instead of physical line (better with wrap)
    vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { buffer = event.buf, expr = true })
    vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { buffer = event.buf, expr = true })
    -- Set shiftwidth to 2 for lists/nesting
    vim.opt_local.shiftwidth = 2

    -- Enables the limited column
    local ok, no_neck_pain = pcall(require, "no-neck-pain")
    if ok and not vim.g.no_neck_pain_enabled then
      no_neck_pain.enable()
      vim.g.no_neck_pain_enabled = true
    end
  end,
})

vim.api.nvim_create_autocmd("BufLeave", {
  group = "MarkdownWriting",
  pattern = { "*.md", "*.markdown" },
  callback = function()
    if vim.g.no_neck_pain_enabled then
      require("no-neck-pain").disable()
      vim.g.no_neck_pain_enabled = false
    end
  end,
})

-- LaTeX writing setup, mirroring MarkdownWriting above (wrap,
-- conceallevel, readable width via no-neck-pain, gj/gk movement).
-- Also replaces the old standalone "spell check for tex" autocmd,
-- since spell is set here now.
vim.api.nvim_create_augroup("LatexWriting", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = "LatexWriting",
  pattern = { "tex" },
  callback = function(event)
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.showbreak = "  "
    -- Spell check
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_us"
    -- Required for vimtex's own concealment (accents, greek, etc.)
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = "nc"
    -- Cleaner reading view: no line numbers or sign column
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    -- Move by visual line instead of physical line (better with wrap)
    vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { buffer = event.buf, expr = true })
    vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { buffer = event.buf, expr = true })

    -- LaTeX group under <leader>x: compile, view, TOC, stop, clean.
    -- Registered here (not in latex.lua) so which-key sees it as soon
    -- as the buffer's FileType fires, same as the other groups above.
    local wk_ok, wk = pcall(require, "which-key")
    if wk_ok then
      wk.add({ { "<leader>x", group = "LaTeX", buffer = event.buf } })
    end

    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = event.buf, silent = true, desc = desc })
    end
    map("<leader>xc", "<cmd>VimtexCompile<cr>", "Compile (continuous)")
    map("<leader>xv", "<cmd>VimtexView<cr>", "View PDF")
    map("<leader>xt", "<cmd>VimtexTocToggle<cr>", "Table of contents")
    map("<leader>xs", "<cmd>VimtexStop<cr>", "Stop compilation")
    map("<leader>xk", "<cmd>VimtexClean<cr>", "Clean aux files")
  end,
})

vim.api.nvim_create_autocmd("BufLeave", {
  group = "LatexWriting",
  pattern = { "*.tex" },
  callback = function()
    if vim.g.no_neck_pain_enabled then
      require("no-neck-pain").disable()
      vim.g.no_neck_pain_enabled = false
    end
  end,
})
