-- lua/keymaps/buffers.lua

local utils = require("utils.buffers")

local function km(mode, lhs, rhs, opts)
	opts = vim.tbl_extend("keep", opts or {}, { silent = true })
	vim.keymap.set(mode, lhs, rhs, opts)
end

-- Buffers
km("n", "<leader>bn", "<cmd>enew<CR>", { desc = "New buffer" })
km("n", "<leader>bw", "<cmd>write<CR>", { desc = "Save buffer" })
km("n", "<leader>bs", "<cmd>noautocmd write<CR>", { desc = "Save buffer without auto-formatting" })

km("n", "<leader>bd", function()
	local buf = vim.api.nvim_get_current_buf()
	if utils.save_if_modified(buf) then
		utils.delete_keep_layout(buf)
	else
		vim.notify("Could not save buffer, not deleted", vim.log.levels.WARN)
	end
end, { desc = "Save and delete buffer" })

km("n", "<leader>bo", function()
	local current_win = vim.api.nvim_get_current_win()
	local current_buf = vim.api.nvim_get_current_buf()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if win ~= current_win and utils.is_normal_window(win) then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end
	utils.delete_where(function(info)
		return info.bufnr ~= current_buf
	end)
end, { desc = "Close other windows and buffers" })

-- Buffer navigation
km("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer" })
km("n", "[b", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
km("n", "<Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })
km("n", "<S-Tab>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
km("n", "<leader><Space>", "<C-^>", { desc = "Toggle between last two buffers" })
