-- lua/keymaps/marks.lua

local km = vim.keymap.set

-- Mark Creation

-- Explicitly expose the native mapping for discoverability and consistency
km("n", "m", "m", { desc = "Set mark" })

-- Mark Navigation
km({ "n", "v", "o" }, "gm", "`", { desc = "Jump to mark (exact position)" })
km({ "n", "v", "o" }, "gM", "'", { desc = "Jump to mark (start of line)" })

km("n", "]m", "]`", { desc = "Jump to next mark" })
km("n", "[m", "[`", { desc = "Jump to previous mark" })

-- Mark Deletion

-- Delete a named mark using the `dm{a-zA-Z}` convention
km("n", "dm", function()
	local ok, char = pcall(vim.fn.getcharstr)

	if ok and char:match("^%a$") then
		pcall(vim.cmd.delmarks, char)
	end
end, { desc = "Delete mark" })

-- Delete all lowercase marks in the current buffer
km("n", "<leader>dm", "<cmd>silent! delmarks!<CR>", { desc = "Delete all marks in buffer" })
