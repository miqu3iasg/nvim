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

-- Buffer navigation: bound to both H/L and Tab/S-Tab intentionally.
-- H/L are fast, one-handed, and consistent with vim motion muscle memory.
-- Tab/S-Tab mirror the common editor convention (browser tabs, etc.)
-- and stay free of the Shift-chord H/L requires. Keeping both gives
-- flexibility depending on hand position/context, not an oversight.
km("n", "L", ":bnext<CR>", { desc = "Next buffer/tab" })
km("n", "H", ":bprevious<CR>", { desc = "Previous buffer/tab" })
km("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
km("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })

-- Buffer navigation
km("n", "<leader><Space>", "<C-6>", { desc = "Toggle between last two buffers" })

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
