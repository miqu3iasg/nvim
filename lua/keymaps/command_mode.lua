-- keymaps/command_mode.lua
local km = vim.keymap.set

-- Command mode
km({ "n", "v" }, ";", ":", { desc = "Enter command mode" })

-- give back the repeat-last-f/t/F/T-motion functionality that ";" used to have
-- (rhs is noremap by default, so this "\" still resolves to the original ";" behavior)
km({ "n", "v" }, "\\", ";", { desc = "Repeat last f/t/F/T motion" })

-- Command-line editing mirrors insert mode (editing.lua) for muscle memory.
-- Different modes, so no conflict between them.
km("c", "<C-a>", "<Home>", { desc = "Go to beginning of command" })
km("c", "<C-e>", "<End>", { desc = "Go to end of command" })
km("c", "<C-b>", "<Left>", { desc = "Move char backward" })
km("c", "<C-f>", "<Right>", { desc = "Move char forward" })
km("c", "<C-h>", "<S-Left>", { desc = "Move word backward" })
km("c", "<C-l>", "<S-Right>", { desc = "Move word forward" })
km("c", "<C-BS>", "<C-w>", { desc = "Delete previous word" })

-- Native <C-f> (open command-line window) was overridden above by "move char
-- forward". Reassigning it here so the feature isn't lost.
km("c", "<C-o>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-f>", true, false, true), "n", true)
end, { desc = "Open command-line window" })
