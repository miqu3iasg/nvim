-- lua/keymaps/terminal.lua

local km = vim.keymap.set

-- Split commands with a fixed size
local VSPLIT = "rightbelow vsplit"
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
