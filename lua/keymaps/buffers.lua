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

-- Buffer navigation
km("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
km("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })
km("n", "<leader><Space>", "<C-6>", { desc = "Toggle between last two buffers" })
