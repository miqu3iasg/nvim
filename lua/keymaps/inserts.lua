-- lua/keymaps/inserts.lua

local km = vim.keymap.set

-- Insert current date/time/filename/path via <C-r> register-insert combos.
-- "!" mode = insert + command-line, mirrors the original noremap! behavior.
km("!", "<C-r><C-d>", "<C-r>=strftime('%F')<CR>", { desc = "Insert current date (YYYY-MM-DD)" })
km("!", "<C-r><C-t>", "<C-r>=strftime('%T')<CR>", { desc = "Insert current time (HH:MM:SS)" })
km("!", "<C-r><C-f>", "<C-r>=expand('%:t')<CR>", { desc = "Insert current filename" })
km("!", "<C-r><C-p>", "<C-r>=expand('%:p')<CR>", { desc = "Insert current file full path" })

-- File metadata, environment info, and generated values (git branch, UUID)
-- useful for commit messages, logs, and templates.
km("!", "<C-r><C-y>", "<C-r>=strftime('%F %T')<CR>", { desc = "Insert current date and time" })
km("!", "<C-r><C-e>", "<C-r>=expand('%:t:r')<CR>", { desc = "Insert current filename without extension" })
km("!", "<C-r><C-w>", "<C-r>=expand('%:p:h')<CR>", { desc = "Insert current file's directory" })
km("!", "<C-r><C-u>", "<C-r>=expand('$USER')<CR>", { desc = "Insert current username" })
