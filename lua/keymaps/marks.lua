-- keymaps/marks.lua
local km = vim.keymap.set

-- Marks
-- explicit, even though redundant with native `m` — kept visible here for
-- discoverability and as a diagnostic data point (just for redundancy, to reinforce)
km("n", "m", "m", { desc = "Set mark" })

-- jump to a named mark, mirrors the gi/gI (lowercase/uppercase variant)
-- convention used in lsp.lua
km({ "n", "v", "o" }, "gm", "`", { desc = "Jump to mark (exact position)" })
km({ "n", "v", "o" }, "gM", "'", { desc = "Jump to mark (start of line)" })

-- next/previous mark, matching the [e / ]e bracket convention used for diagnostics
km("n", "]m", "]`", { desc = "Jump to next mark" })
km("n", "[m", "[`", { desc = "Jump to previous mark" })
