-- lua/autocmds.lua

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
