-- keymaps/command_mode.lua

local km = vim.keymap.set

-- Command Mode
km({ "n", "v" }, ";", ":", { desc = "Enter command mode" })

-- Repeat Last Character-Search Motion
km({ "n", "x", "o" }, ":", ";", {
	desc = "Repeat last f/t/F/T motion (swap)",
})

km({ "n", "x", "o" }, "\\", ";", {
	desc = "Repeat last f/t/F/T motion (alt)",
})

-- Command-Line Editing
km("c", "<C-a>", "<Home>", { desc = "Go to beginning of command" })
km("c", "<C-e>", "<End>", { desc = "Go to end of command" })
km("c", "<C-b>", "<Left>", { desc = "Move char backward" })
km("c", "<C-f>", "<Right>", { desc = "Move char forward" })
km("c", "<C-h>", "<S-Left>", { desc = "Move word backward" })
km("c", "<C-l>", "<S-Right>", { desc = "Move word forward" })

-- Preserve the native <C-f> functionality, which opens the command-line
-- window, despite using it above to move one character forward.
km("c", "<C-o>", function()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-f>", true, false, true), "n", true)
end, { desc = "Open command-line window" })
