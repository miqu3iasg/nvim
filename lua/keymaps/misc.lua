local km = vim.keymap.set

-- UI
km("n", "<leader>vt", ":Telescope colorscheme<CR>", { desc = "Choose colorscheme" })

km("n", "<leader>vn", function()
  vim.wo.number = not vim.wo.number
  vim.wo.relativenumber = vim.wo.number
end, { desc = "Toggle line numbers" })

km("n", "<leader>vw", function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle line wrap" })

km("n", "<leader>vc", function()
  vim.wo.cursorline = not vim.wo.cursorline
end, { desc = "Toggle cursorline" })

km("n", "<leader>vb", "<cmd>ToggleStatusline<CR>", { desc = "Toggle status bar" })

km("n", "<leader>vz", function()
  vim.o.background = vim.o.background == "dark" and "light" or "dark"
end, { desc = "Toggle background (dark/light)" })

-- Editing
km("n", "<leader>vs", function()
  vim.wo.spell = not vim.wo.spell
end, { desc = "Toggle spell check" })

km("n", "<leader>ts", ":setlocal spell spelllang=en_us<CR>", { desc = "Enable English spell check" })

-- Diagnostics
km("n", "<leader>vd", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

km("n", "<leader>vh", ":nohlsearch<CR>", { desc = "Clear search highlight" })

-- Misc
km("n", "<leader>rl", ":source $MYVIMRC<CR>", { desc = "Reload nvim config" })
km("n", "<leader>re", "<cmd>restart<cr>", { desc = "Restart Neovim (:restart)" })
