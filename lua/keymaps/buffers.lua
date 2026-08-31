local utils = require("utils")

local km = vim.keymap.set

-- Buffers
km("n", "<leader>bn", ":enew<CR>", { desc = "New buffer" })

km("n", "<leader>bd", function()
  utils.save_if_modified()
  vim.cmd("bd")
end, { desc = "Save and delete buffer" })

km("n", "<leader>ba", ":%bd<CR>", { desc = "Delete all buffers" })

km("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  vim.cmd("only")
  for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if buf.bufnr ~= current and vim.api.nvim_buf_is_valid(buf.bufnr) then
      vim.api.nvim_buf_delete(buf.bufnr, { force = false })
    end
  end
end, { desc = "Close other windows and buffers" })

km("n", "L", ":bnext<CR>", { desc = "Next buffer/tab" })
km("n", "H", ":bprevious<CR>", { desc = "Previous buffer/tab" })

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
