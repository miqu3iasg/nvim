local km = vim.keymap.set

-- Command mode
-- hit ";" instead of holding shift for ":"
km({ "n", "v" }, ";", ":", { desc = "Enter command mode" })

-- give back the repeat-last-f/t/F/T-motion functionality that ";" used to have
-- (rhs is noremap by default, so this "\" still resolves to the original ";" behavior)
km({ "n", "v" }, "\\", ";", { desc = "Repeat last f/t/F/T motion" })

-- command-line editing (readline-style, mirrors insert mode in editing.lua)
km("c", "<C-a>", "<Home>", { desc = "Go to beginning of command" })
km("c", "<C-e>", "<End>", { desc = "Go to end of command" })
km("c", "<C-b>", "<S-Left>", { desc = "Move word backward in command" })
km("c", "<C-f>", "<S-Right>", { desc = "Move word forward in command" })
km("c", "<C-BS>", "<C-w>", { desc = "Delete previous word in command" })
