-- lua/keymaps/misc.lua

local km = vim.keymap.set

-- Appearance

-- Select and apply a colorscheme
km("n", "<leader>vt", ":FzfLua colorschemes<CR>", { desc = "Choose colorscheme" })

-- Switch between dark and light background settings
km("n", "<leader>vz", function()
  vim.o.background = vim.o.background == "dark" and "light" or "dark"
end, { desc = "Toggle background (dark/light)" })

-- Toggle highlighting of the current line
km("n", "<leader>vc", function()
  vim.wo.cursorline = not vim.wo.cursorline
end, { desc = "Toggle cursorline" })

-- Toggle line wrapping
km("n", "<leader>vw", function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle line wrap" })

-- Toggle the sign column (gutter); "no" by default in options.lua
km("n", "<leader>vg", function()
  vim.wo.signcolumn = vim.wo.signcolumn == "no" and "yes" or "no"
end, { desc = "Toggle sign column" })

-- Line numbers

-- Toggle absolute and relative line numbers together
km("n", "<leader>vn", function()
  vim.wo.number = not vim.wo.number
  vim.wo.relativenumber = vim.wo.number
end, { desc = "Toggle line numbers" })

-- Keep absolute line numbers enabled while toggling relative numbers
km("n", "<leader>vr", function()
  vim.wo.number = true
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle relative/absolute line numbers" })

-- Spell checking

-- Toggle spell checking for the current buffer
km("n", "<leader>vs", function()
  vim.wo.spell = not vim.wo.spell
end, { desc = "Toggle spell check" })

-- Diagnostics

-- Toggle the display of diagnostics
km("n", "<leader>vd", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

-- Toggle inline diagnostics (virtual text); off by default in options.lua
km("n", "<leader>vi", function()
  local enabled = vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = not enabled })
end, { desc = "Toggle inline diagnostics" })

-- Info and health

-- Show the message history
km("n", "<leader>vm", "<cmd>messages<cr>", { desc = "Show messages" })

-- Run the built-in health checks
km("n", "<leader>vh", "<cmd>checkhealth<cr>", { desc = "Check health" })

-- Config shortcuts

-- Open common config files and directories in Neovim
km("n", "<leader>zs", "<cmd>e ~/.zshrc<cr>", { desc = "Edit .zshrc" })
km("n", "<leader>zt", "<cmd>e ~/.config/tmux/tmux.conf<cr>", { desc = "Edit tmux.conf" })
km("n", "<leader>zn", function() require("oil").open("~/.config/nvim") end, { desc = "Edit nvim config directory (Oil)" })
km("n", "<leader>zi", "<cmd>e ~/.config/i3/config<cr>", { desc = "Edit i3 configuration" })

-- Save and quit

-- Native Z* commands, mapped explicitly for discoverability
km("n", "ZZ", "<cmd>x<cr>", { desc = "Save and quit (native)" })
km("n", "ZQ", "<cmd>q!<cr>", { desc = "Quit without saving (native)" })
km("n", "ZX", "<cmd>w<cr>", { desc = "Save file" })

-- Reload and run

-- Reload the current Neovim configuration
km("n", "<leader>rl", ":source $MYVIMRC<CR>", { desc = "Reload nvim config" })

-- Restart Neovim
km("n", "<leader>re", "<cmd>restart<cr>", { desc = "Restart Neovim" })

-- Source the current file
km("n", "<leader>rf", "<cmd>source %<cr>", { desc = "Source current file" })

-- Run the current line or the visual selection as Lua
km("n", "<leader>rx", "<cmd>.lua<cr>", { desc = "Run current Lua line" })
km("v", "<leader>rx", ":lua<cr>", { desc = "Run selected Lua" })
