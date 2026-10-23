-- lua/keymaps/terminal.lua

local km = vim.keymap.set

-- Terminal Creation
km("n", "<leader>tv", "<cmd>rightbelow vsplit | terminal<CR>", { desc = "Open terminal in vertical split (right)" })
km("n", "<leader>th", "<cmd>botright 15split | terminal<CR>", { desc = "Open terminal in horizontal split (bottom)" })
km("n", "<leader>tt", "<cmd>tabnew | terminal<CR>", { desc = "Open terminal in a new tab" })

-- Terminal Mode
km("t", "<C-b>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Close the terminal window without stopping its running job
km("t", "<C-d>", [[<C-\><C-n>:close<CR>]], { desc = "Close terminal window" })

-- Window Navigation

-- Mirror the <C-hjkl> mappings from windows.lua.
km("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Move to left window from terminal" })
km("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Move to lower window from terminal" })
km("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Move to upper window from terminal" })
km("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Move to right window from terminal" })
