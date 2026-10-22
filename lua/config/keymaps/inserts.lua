-- lua/keymaps/inserts.lua

local km = vim.keymap.set

-- Insert current date/time via <C-r> register-insert combos.
-- "!" mode = insert + command-line, mirrors the original noremap! behavior
km("!", "<C-r><C-n>", "<C-r>=strftime('%F')<CR>", { desc = "Insert current date (YYYY-MM-DD)" })
km("!", "<C-r><C-t>", "<C-r>=strftime('%T')<CR>", { desc = "Insert current time (HH:MM:SS)" })

-- Alternative date formats
km("!", "<C-r><C-d>", "<C-r>=strftime('%d%m%Y')<CR>", { desc = "Insert current date (DDMMYYYY)" })
km("!", "<C-r><C-b>", "<C-r>=strftime('%d/%m/%Y')<CR>", { desc = "Insert current date (DD/MM/YYYY)" })
km("!", "<C-r><C-g>", "<C-r>=strftime('%Y%m%d%H%M')<CR>", { desc = "Insert compact date+time (YYYYMMDDHHMM)" })

-- File metadata, environment info, and generated values useful for commit messages, logs, and templates
km("!", "<C-r><C-y>", "<C-r>=strftime('%F %T')<CR>", { desc = "Insert current date and time" })
km("!", "<C-r><C-k>", "<C-r>=expand('%:t:r')<CR>", { desc = "Insert current filename without extension" })
km("!", "<C-r><C-e>", "<C-r>=expand('%:t')<CR>", { desc = "Insert current filename with extension" })
km("!", "<C-r><C-u>", "<C-r>=trim(system('uuidgen'))<CR>", { desc = "Insert UUID" })
