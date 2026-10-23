-- lua/plugins/git.lua

-- Git must be installed and configured for the commands in this file to work.
-- These commands also require the current directory to belong to a Git repository
-- that has already been initialized with `git init` or cloned from a remote.
--
-- On Arch Linux, install Git with:
--
-- $ sudo pacman -S git
--
-- My global Git configuration is stored in ~/.gitconfig. Make sure it contains
-- the necessary settings, such as your user name and email. You can inspect it
-- with:
--
-- $ git config --global --list
-- $ cat ~/.gitconfig
--
-- The keymaps below use vim-fugitive, gitsigns.nvim and, optionally, fzf-lua.
-- fzf-lua keymaps are registered only when fzf-lua is available.
--
-- See: https://git-scm.com/doc
-- See: https://github.com/tpope/vim-fugitive
-- See: https://github.com/lewis6991/gitsigns.nvim
-- See: https://github.com/ibhagwan/fzf-lua

-- Adjust the default blame view width to fit the author, timestamp and summary.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "fugitiveblame",
	callback = function()
		vim.cmd("vertical resize 45")
	end,
})

-- See: lua/utils/close.lua
-- Registers the Fugitive close-view keymaps and autocmds
require("utils.close").setup()

local map = vim.keymap.set

-- vim-fugitive
map("n", "<leader>gs", "<cmd>silent tab Git<cr>", { desc = "Git status" })
map("n", "<leader>ga", "<cmd>silent Gwrite<cr>", { desc = "Stage current file" })
map("n", "<leader>gd", "<cmd>silent Gvdiffsplit<cr>", { desc = "Diff against index" })
map("n", "<leader>gh", "<cmd>silent Gvdiffsplit HEAD<cr>", { desc = "Diff against HEAD" })
map("n", "<leader>gb", "<cmd>silent Git blame<cr>", { desc = "Git blame" })
map("n", "<leader>ge", "<cmd>.Git blame<cr>", { desc = "Git blame (line)" })

-- gitsigns.nvim
require("gitsigns").setup({
	signcolumn = false,
	numhl = false,
	word_diff = false,
	current_line_blame = false,
})

map("n", "<leader>hs", function()
	require("gitsigns").stage_hunk()
end, { desc = "Stage/unstage hunk" })

map("x", "<leader>hs", function()
	require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, { desc = "Stage/unstage selection" })

map("n", "<leader>hr", function()
	require("gitsigns").reset_hunk()
end, { desc = "Reset hunk" })

map("n", "<leader>hp", function()
	require("gitsigns").preview_hunk_inline()
end, { desc = "Preview hunk" })

map(
	"n",
	"<leader>hd",
	(function()
		local on = false
		return function()
			on = not on
			local gs = require("gitsigns")
			gs.toggle_deleted(on)
			gs.toggle_linehl(on)
		end
	end)(),
	{ desc = "Toggle diff overlay" }
)

map("n", "]c", function()
	require("gitsigns").nav_hunk("next", { navigation_message = false })
end, { desc = "Next hunk" })

map("n", "[c", function()
	require("gitsigns").nav_hunk("prev", { navigation_message = false })
end, { desc = "Prev hunk" })

-- Merged into the existing fzf-lua setup; ignored if fzf-lua is absent
if pcall(require, "fzf-lua") then
	map("n", "<leader>gw", "<cmd>FzfLua git_branches<cr>", { desc = "Git branches (checkout)" })
	map("n", "<leader>gi", "<cmd>FzfLua git_commits<cr>", { desc = "Git commits" })
	map("n", "<leader>gl", "<cmd>FzfLua git_blame<cr>", { desc = "Git log" })
	map("n", "<leader>gm", "<cmd>FzfLua git_status<cr>", { desc = "Git status (modified files)" })
	map("n", "<leader>gu", "<cmd>FzfLua git_hunks<cr>", { desc = "Git hunks" })
	map("n", "<leader>gk", "<cmd>FzfLua git_diff<cr>", { desc = "Git diff" })

	map("n", "<leader>gf", function()
		require("fzf-lua").git_files({ cmd = "git ls-files --cached --others --exclude-standard" })
	end, { desc = "Git files" })
end
