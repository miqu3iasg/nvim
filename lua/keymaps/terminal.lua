local km = vim.keymap.set

-- Open terminal splits / in-place
km("n", "<leader>tv", function()
  vim.cmd("botright vsplit | terminal")
end, { desc = "Open terminal in vertical split (right)" })

km("n", "<leader>th", function()
  vim.cmd("botright split | terminal")
end, { desc = "Open terminal in horizontal split (bottom)" })

km("n", "<leader>tt", "<cmd>terminal<CR>", { desc = "Open terminal in current window" })

-- Toggle terminal: reopens the same buffer/process if hidden,
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
    vim.cmd("botright vsplit")
    vim.api.nvim_win_set_buf(0, term_buf)
    term_win = vim.api.nvim_get_current_win()
    vim.cmd("startinsert")
    return
  end

  vim.cmd("botright vsplit | terminal")
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

-- Exit terminal insert mode back to normal mode
km("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Close the terminal window (job keeps running in the background, same as
-- the toggle above) without having to hit <Esc> first. If you're already in
-- normal mode inside the terminal buffer (e.g. after pressing <Esc>), the
-- generic <leader>sc (windows.lua) closes it the exact same way.
km("t", "<C-d>", [[<C-\><C-n>:close<CR>]], { desc = "Close terminal window" })

-- Window navigation from inside terminal mode (mirrors <C-hjkl> in windows.lua)
km("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Move to left window from terminal" })
km("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Move to lower window from terminal" })
km("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Move to upper window from terminal" })
km("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Move to right window from terminal" })
