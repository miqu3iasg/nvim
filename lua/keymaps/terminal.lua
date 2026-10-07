-- lua/keymaps/terminal.lua

local km = vim.keymap.set

-- Split commands with a fixed size
local VSPLIT = "botright 90vsplit"
local HSPLIT = "botright 15split"

-- Open a terminal using the given window command (split, tabnew, ...)
local function open_term(win_cmd)
  vim.cmd(win_cmd .. " | terminal")
end

-- Open terminal splits / in-place
km("n", "<leader>tv", function()
  open_term(VSPLIT)
end, { desc = "Open terminal in vertical split (right)" })

km("n", "<leader>th", function()
  open_term(HSPLIT)
end, { desc = "Open terminal in horizontal split (bottom)" })

km("n", "<leader>tt", function()
  open_term("tabnew")
end, { desc = "Open terminal in a new tab" })

-- Toggle terminal reopens the same buffer/process if hidden,
-- hides the window (without killing the process) if visible.
local term_buf = nil
local term_win = nil

local function toggle_terminal()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
    return
  end

  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    vim.cmd(VSPLIT)
    vim.api.nvim_win_set_buf(0, term_buf)
    term_win = vim.api.nvim_get_current_win()
    vim.cmd("startinsert")
    return
  end

  open_term(VSPLIT)
  term_buf = vim.api.nvim_get_current_buf()
  term_win = vim.api.nvim_get_current_win()
end

km("n", "<leader>tg", toggle_terminal, { desc = "Toggle terminal" })

-- Auto-enter insert mode on terminal open, and clean up its UI
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.spell = false
    vim.cmd("startinsert")
  end,
})

-- When the shell exits (e.g. `exit`), forget the toggle state and wipe the
-- dead buffer so the toggle never reopens a stopped terminal
vim.api.nvim_create_autocmd("TermClose", {
  callback = function(args)
    if args.buf == term_buf then
      term_buf, term_win = nil, nil
    end
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        vim.api.nvim_buf_delete(args.buf, { force = true })
      end
    end)
  end,
})

-- Exit terminal insert mode back to normal mode
km("t", "<C-b>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Close the terminal window (job keeps running in the background, same as
-- the toggle above) without having to leave terminal mode first (<C-b>).
km("t", "<C-d>", [[<C-\><C-n>:close<CR>]], { desc = "Close terminal window" })

-- Window navigation from inside terminal mode (mirrors <C-hjkl> in windows.lua)
km("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Move to left window from terminal" })
km("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Move to lower window from terminal" })
km("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Move to upper window from terminal" })
km("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Move to right window from terminal" })
