-- lua/keymaps/inserts.lua

local km = vim.keymap.set

-- Insert current date/time via <C-r> register-insert combos. "!" mode stands for insert and command-line

-- Date
km("!", "<C-r><C-n>", "<C-r>=strftime('%F')<CR>", { desc = "Insert current date (YYYY-MM-DD)" })
km("!", "<C-r><C-d>", "<C-r>=strftime('%d%m%Y')<CR>", { desc = "Insert current date (DDMMYYYY)" })
km("!", "<C-r><C-b>", "<C-r>=strftime('%d/%m/%Y')<CR>", { desc = "Insert current date (DD/MM/YYYY)" })

-- Time
km("!", "<C-r><C-t>", "<C-r>=strftime('%H:%M')<CR>", { desc = "Insert current time (HH:MM)" })

-- Date and Time
km(
	"!",
	"<C-r><C-y>",
	"<C-r>=strftime('%Y-%m-%dT%H:%M')<CR>",
	{ desc = "Insert current date and time (YYYY-MM-DDTHH:MM)" }
)
km("!", "<C-r><C-g>", "<C-r>=strftime('%Y%m%d%H%M')<CR>", { desc = "Insert compact date+time (YYYYMMDDHHMM)" })

-- File Metadata
km("!", "<C-r><C-k>", "<C-r>=expand('%:t:r')<CR>", { desc = "Insert current filename without extension" })
km("!", "<C-r><C-e>", "<C-r>=expand('%:t')<CR>", { desc = "Insert current filename with extension" })

-- Generated Values
km("!", "<C-r><C-u>", "<C-r>=trim(system('uuidgen'))<CR>", { desc = "Insert UUID" })
