-- lua/keymaps/misc.lua

local km = vim.keymap.set

-- Select and apply a colorscheme
km("n", "<leader>vt", ":FzfLua colorschemes<CR>", { desc = "Choose colorscheme" })

-- Toggle absolute line numbers and relative line numbers together
km("n", "<leader>vn", function()
  vim.wo.number = not vim.wo.number
  vim.wo.relativenumber = vim.wo.number
end, { desc = "Toggle line numbers" })

-- Keep absolute line numbers enabled while toggling relative numbers
km("n", "<leader>vr", function()
  vim.wo.number = true
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle relative/absolute line numbers" })

-- Toggle line wrapping
km("n", "<leader>vw", function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle line wrap" })

-- Toggle highlighting of the current line
km("n", "<leader>vc", function()
  vim.wo.cursorline = not vim.wo.cursorline
end, { desc = "Toggle cursorline" })

-- Switch between dark and light background settings
km("n", "<leader>vz", function()
  vim.o.background = vim.o.background == "dark" and "light" or "dark"
end, { desc = "Toggle background (dark/light)" })

-- Toggle spell checking for the current buffer
km("n", "<leader>vs", function()
  vim.wo.spell = not vim.wo.spell
end, { desc = "Toggle spell check" })

-- Enable English spell checking for the current buffer
km("n", "<leader>ts", ":setlocal spell spelllang=en_us<CR>", { desc = "Enable English spell check" })

-- Toggle the display of diagnostics
km("n", "<leader>vd", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

-- Reload the current Neovim configuration
km("n", "<leader>rl", ":source $MYVIMRC<CR>", { desc = "Reload nvim config" })

-- Restart Neovim
km("n", "<leader>re", "<cmd>restart<cr>", { desc = "Restart Neovim" })
