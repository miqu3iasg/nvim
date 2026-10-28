-- lua/keymaps/windows.lua

local km = vim.keymap.set

-- Window navigation
km("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
km("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
km("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
km("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Move window within layout
km("n", "<leader>mh", "<C-w>H", { desc = "Move window to far left" })
km("n", "<leader>mj", "<C-w>J", { desc = "Move window to bottom" })
km("n", "<leader>mk", "<C-w>K", { desc = "Move window to top" })
km("n", "<leader>ml", "<C-w>L", { desc = "Move window to far right" })

-- Swap or rotate windows
km("n", "<leader>mx", "<C-w>x", { desc = "Swap window with next" })
km("n", "<leader>mr", "<C-w>r", { desc = "Rotate windows" })

-- Window management
km("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split window vertically" })
km("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split window horizontally" })
km("n", "<leader>se", "<C-w>=", { desc = "Equalize window sizes" })
km("n", "<leader>sc", "<cmd>close<CR>", { desc = "Close current window" })
km("n", "<leader>so", "<cmd>only<CR>", { desc = "Close other windows" })

-- Window resizing
km("n", "+", "<cmd>resize +5<cr>", { desc = "Increase window height" })
km("n", "_", "<cmd>resize -5<cr>", { desc = "Decrease window height" })
km("n", "=", "<cmd>vertical resize +5<cr>", { desc = "Increase window width" })
km("n", "-", "<cmd>vertical resize -5<cr>", { desc = "Decrease window width" })

-- Maximize window (toggle between maximized and original size)
km("n", "<leader>sm", function()
	if vim.fn.tabpagenr("$") > 1 and vim.t.zoomed then
		vim.cmd("tabclose")
	elseif vim.fn.winnr("$") > 1 then
		vim.cmd("tab split")
		vim.t.zoomed = true
	end
end, { desc = "Toggle window zoom" })
