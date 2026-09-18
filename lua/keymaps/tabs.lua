-- lua/keymaps/tabs.lua

local utils = require("utils")
local km = vim.keymap.set

-- Tab creation
km("n", "<leader>tn", ":tabnew<CR>", { desc = "New tab" })
km("n", "<leader>td", ":tab split<CR>", { desc = "Duplicate current buffer in new tab" })

-- Tab closing
km("n", "<leader>tc", function()
  if vim.fn.tabpagenr("$") == 1 then
    vim.notify("Cannot close the last tab", vim.log.levels.WARN)
    return
  end
  utils.save_if_modified()
  vim.cmd("tabclose")
end, { desc = "Save and close current tab" })

km("n", "<leader>to", function()
  utils.save_if_modified()
  vim.cmd("tabonly")
end, { desc = "Save and close other tabs" })

km("n", "<leader>tr", function()
  local current = vim.fn.tabpagenr()
  for i = vim.fn.tabpagenr("$"), current + 1, -1 do
    vim.cmd(i .. "tabclose")
  end
end, { desc = "Close tabs to the right" })

km("n", "<leader>tR", function()
  local current = vim.fn.tabpagenr()
  for _ = 1, current - 1 do
    vim.cmd("1tabclose")
  end
end, { desc = "Close tabs to the left" })

-- Tab navigation
km("n", "<leader>tl", ":tabnext<CR>", { desc = "Next tab" })
km("n", "<leader>tp", ":tabprevious<CR>", { desc = "Previous tab" })
km("n", "]t", ":tabnext<CR>", { desc = "Next tab" })
km("n", "[t", ":tabprevious<CR>", { desc = "Previous tab" })
km("n", "<leader>tH", ":tabfirst<CR>", { desc = "First tab" })
km("n", "<leader>tL", ":tablast<CR>", { desc = "Last tab" })
km("n", "<leader>t<Space>", "g<Tab>", { desc = "Toggle between last two tabs" })

-- Jump to tab by number (<leader>t1 ... <leader>t9)
for i = 1, 9 do
  km("n", "<leader>t" .. i, i .. "gt", { desc = "Go to tab " .. i })
end

-- Move tab position
km("n", "<leader>t<", ":tabmove -1<CR>", { desc = "Move tab left" })
km("n", "<leader>t>", ":tabmove +1<CR>", { desc = "Move tab right" })
km("n", "<leader>t0", ":tabmove 0<CR>", { desc = "Move tab to first position" })
km("n", "<leader>t$", ":tabmove $<CR>", { desc = "Move tab to last position" })

-- List tabs
km("n", "<leader>ti", ":tabs<CR>", { desc = "List tabs (info)" })
