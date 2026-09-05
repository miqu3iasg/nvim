local utils = require("utils")
local km = vim.keymap.set

-- Window navigation
km("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
km("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
km("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
km("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Move window within layout
km("n", "<leader>mh", "<C-w>H", { desc = "Move window to far left" })
km("n", "<leader>mj", "<C-w>J", { desc = "Move window to bottom" })
km("n", "<leader>mk", "<C-w>K", { desc = "Move window to top" })
km("n", "<leader>ml", "<C-w>L", { desc = "Move window to far right" })

-- Move window to new tab
km("n", "<leader>mt", "<C-w>T", { desc = "Move window to new tab" })

-- Swap current window with the next one
km("n", "<leader>mx", "<C-w>x", { desc = "Swap window with next" })

-- Rotate all windows, keeping the current layout
km("n", "<leader>mr", "<C-w>r", { desc = "Rotate windows" })

-- Window management
km("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
km("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })
km("n", "<leader>se", "<C-w>=", { desc = "Equalize window sizes" })

km("n", "<leader>sc", function()
  utils.save_if_modified()
  vim.cmd("close")
end, { desc = "Save and close current window" })

km("n", "<leader>so", function()
  utils.save_if_modified()
  vim.cmd("only")
end, { desc = "Save and close other windows" })

-- Window resizing
km("n", "<C-Up>", "<cmd>resize +5<cr>", { desc = "Increase Window Height" })
km("n", "<C-Down>", "<cmd>resize -5<cr>", { desc = "Decrease Window Height" })
km("n", "<C-Left>", "<cmd>vertical resize -5<cr>", { desc = "Decrease Window Width" })
km("n", "<C-Right>", "<cmd>vertical resize +5<cr>", { desc = "Increase Window Width" })

km("n", "+", "<cmd>resize +5<cr>", { desc = "Increase window height" })
km("n", "-", "<cmd>resize -5<cr>", { desc = "Decrease window height" })
km("n", "<", "<cmd>vertical resize -5<cr>", { desc = "Decrease window width" })
km("n", ">", "<cmd>vertical resize +5<cr>", { desc = "Increase window width" })

-- Zoom window (toggle between maximized and original size)
km("n", "<leader>z", function()
  if vim.fn.winnr("$") == 1 then
    return
  end
  if vim.t.zoom then
    vim.cmd(vim.t.zoom)
    vim.t.zoom = nil
  else
    vim.t.zoom = vim.fn.winrestcmd()
    vim.cmd("resize")
    vim.cmd("vertical resize")
  end
end, { desc = "Toggle window zoom" })
