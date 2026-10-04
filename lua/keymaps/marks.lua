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

-- delete a mark by name (dm{a-zA-Z}), mirrors the `m{a-zA-Z}` set-mark
-- convention
km("n", "dm", function()
  local ok, char = pcall(vim.fn.getcharstr)

  if ok and char:match("^%a$") then
    pcall(vim.cmd.delmarks, char)
  end
end, { desc = "Delete mark" })

-- delete all lowercase marks in the current buffer
km("n", "<leader>dm", "<cmd>silent! delmarks!<cr>", { desc = "Delete all marks in buffer" })
