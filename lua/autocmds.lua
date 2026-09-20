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

-- No auto continue comments on new line
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("no_auto_comment", {}),
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- syntax highlighting for dotenv files
vim.api.nvim_create_autocmd("BufRead", {
  group = vim.api.nvim_create_augroup("dotenv_ft", { clear = true }),
  pattern = { ".env", ".env.*" },
  callback = function()
    vim.bo.filetype = "dosini"
  end,
})

-- On startup without file args, restore the tmux session, or open Oil
vim.api.nvim_create_augroup("StartupBehavior", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
  group = "StartupBehavior",
  nested = true,
  callback = function()
    local argc = vim.fn.argc()
    local no_files = argc == 0
        or (argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1)

    if not no_files then
      return
    end

    vim.schedule(function()
      -- Inside tmux, try to restore the session for this directory
      local sessions = require("sessions")
      if sessions.enabled() and sessions.load() then
        return
      end

      -- No session (or outside tmux), open Oil as before
      if argc == 0 then
        require("oil").open()
      else
        require("oil").open(vim.fn.argv(0))
      end
    end)
  end,
})

-- Save the session of the current directory on exit (inside tmux only).
-- Oil buffers are removed by sessions.save() before writing the session.
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("SessionSave", { clear = true }),
  callback = function()
    local sessions = require("sessions")
    if sessions.enabled() then
      pcall(sessions.save)
    end
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
