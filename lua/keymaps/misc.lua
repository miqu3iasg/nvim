-- lua/keymaps/misc.lua

local km = vim.keymap.set

-- Toggles a boolean window option (vim.wo)
local function toggle(lhs, opt, desc)
  km("n", lhs, function()
    vim.wo[opt] = not vim.wo[opt]
  end, { desc = desc })
end

-- Appearance

km("n", "<leader>vt", "<cmd>FzfLua colorschemes<cr>", { desc = "Choose colorscheme" })

toggle("<leader>vw", "wrap", "Toggle line wrap")
toggle("<leader>vl", "list", "Toggle whitespace characters")
toggle("<leader>vs", "spell", "Toggle spell check")
toggle("<leader>vc", "cursorline", "Toggle cursorline")

km("n", "<leader>vg", function()
  vim.wo.signcolumn = vim.wo.signcolumn == "no" and "yes" or "no"
end, { desc = "Toggle sign column" })

-- Line numbers

-- Toggle absolute and relative numbers together
km("n", "<leader>vn", function()
  vim.wo.number = not vim.wo.number
  vim.wo.relativenumber = vim.wo.number
end, { desc = "Toggle line numbers" })

-- Keep absolute numbers on and toggle only relative numbers
km("n", "<leader>vr", function()
  vim.wo.number = true
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle relative numbers" })

-- Config files and bookmarked directories

km("n", "<leader>zg", "<cmd>e ~/.gitconfig<cr>", { desc = "Edit .gitconfig" })
km("n", "<leader>zi", "<cmd>e ~/.config/i3/config<cr>", { desc = "Edit i3 config" })
km("n", "<leader>zs", "<cmd>e ~/.zshrc<cr>", { desc = "Edit .zshrc" })
km("n", "<leader>zt", "<cmd>e ~/.config/tmux/tmux.conf<cr>", { desc = "Edit tmux.conf" })

-- TODO: add more pinned bookmarked directories here
km("n", "<leader>zn", function() require("oil").open("~/.config/nvim") end, { desc = "Open nvim config dir (Oil)" })

-- Save and quit

-- Explicit mappings for Z* commands so they show up in which-key
km("n", "ZZ", "<cmd>x<cr>", { desc = "Save and quit" })
km("n", "ZQ", "<cmd>q!<cr>", { desc = "Quit without saving" })
km("n", "ZX", "<cmd>w<cr>", { desc = "Save file" })

-- Reload, restart and run

km("n", "<leader>rl", "<cmd>source $MYVIMRC<cr>", { desc = "Reload nvim config" })
km("n", "<leader>re", "<cmd>restart<cr>", { desc = "Restart Neovim" })
km("n", "<leader>rs", "<cmd>source %<cr>", { desc = "Source current file" })
