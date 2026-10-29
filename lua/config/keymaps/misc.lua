-- lua/keymaps/misc.lua

-- Helpers

local km = vim.keymap.set

-- Normal-mode mapping shorthand
local function map(lhs, rhs, desc)
	km("n", lhs, rhs, { desc = desc })
end

-- Toggles a boolean window option (vim.wo)
local function toggle_wo(lhs, opt, desc)
	map(lhs, function()
		vim.wo[opt] = not vim.wo[opt]
	end, desc)
end

-- Opens a file for editing
local function edit_file(lhs, path, desc)
	map(lhs, "<cmd>e " .. path .. "<cr>", desc)
end

-- Opens a directory with oil.nvim
local function open_dir(lhs, path, desc)
	map(lhs, function()
		require("oil").open(vim.fn.expand(path))
	end, desc)
end

-- View and appearance toggles

map("<leader>vt", "<cmd>FzfLua colorschemes<cr>", "Choose colorscheme")

toggle_wo("<leader>vw", "wrap", "Toggle line wrap")
toggle_wo("<leader>vl", "list", "Toggle whitespace characters")
toggle_wo("<leader>vs", "spell", "Toggle spell check")
toggle_wo("<leader>vc", "cursorline", "Toggle cursorline")

map("<leader>vg", function()
	vim.wo.signcolumn = vim.wo.signcolumn == "no" and "yes" or "no"
end, "Toggle sign column")

map("<leader>vb", function()
	vim.o.background = (vim.o.background == "dark") and "light" or "dark"
end, "Toggle light/dark")

map("<leader>vd", function()
	local enabled = not vim.diagnostic.is_enabled()
	vim.diagnostic.enable(enabled)
	vim.notify("Diagnostics " .. (enabled and "enabled" or "disabled"))
end, "Toggle diagnostics")

-- Line numbers

-- Toggle absolute and relative numbers together
map("<leader>vn", function()
	vim.wo.number = not vim.wo.number
	vim.wo.relativenumber = vim.wo.number
end, "Toggle line numbers")

-- Keep absolute numbers on and toggle only relative numbers
map("<leader>vr", function()
	vim.wo.number = true
	vim.wo.relativenumber = not vim.wo.relativenumber
end, "Toggle relative numbers")

-- Config files and bookmarked directories

-- Files
edit_file("<leader>zg", "~/.gitconfig", "Edit .gitconfig")
edit_file("<leader>zi", "~/.config/i3/config", "Edit i3 config")
edit_file("<leader>zz", "~/.zshrc", "Edit .zshrc")
edit_file("<leader>zt", "~/.config/tmux/tmux.conf", "Edit tmux.conf")
edit_file("<leader>zk", "~/.config/kitty/kitty.conf", "Edit kitty.conf")
edit_file("<leader>zs", "~/.config/starship.toml", "Edit starship.toml")

-- Directories
open_dir("<leader>zn", "~/.config/nvim", "Open nvim config dir")
open_dir("<leader>zr", "~/repos", "Open repos dir (workspace)")
open_dir("<leader>zc", "~/.config", "Open ~/.config directory")
open_dir("<leader>zb", "~/.local/bin", "Open ~/.local/bin directory (scripts)")

-- Save and quit

-- Explicit mappings to remind me that they exist and to use them.
map("ZZ", "<cmd>x<cr>", "Save and quit")
map("ZQ", "<cmd>q!<cr>", "Quit without saving")
map("ZX", "<cmd>w<cr>", "Save file")

-- Reload, restart and run
map("<leader>rl", "<cmd>source $MYVIMRC<cr>", "Reload nvim config")
map("<leader>re", "<cmd>restart<cr>", "Restart Neovim")
map("<leader>rs", "<cmd>luafile %<cr>", "Source lua files")
map("<leader>ru", "<cmd>update<bar>source %<cr>", "Save and source current file")
