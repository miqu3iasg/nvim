-- lua/plugins/git.lua

-- Git must be installed and configured for the commands in this file to work.
-- The current directory must belong to a Git repository (`git init` or a clone).
--
-- On Arch Linux, install Git with:
--
-- $ sudo pacman -S git
--
-- Global configuration lives in ~/.gitconfig (user.name, user.email, ...):
--
-- $ git config --global --list
--
-- $ cat ~/.gitconfig
--
-- The keymaps below use vim-fugitive, gitsigns.nvim and, optionally, fzf-lua.
-- fzf-lua keymaps are registered only when fzf-lua is available.
--
-- See: https://git-scm.com/doc
-- See: https://github.com/tpope/vim-fugitive
-- See: https://github.com/tpope/vim-rhubarb
-- See: https://github.com/lewis6991/gitsigns.nvim
-- See: https://github.com/ibhagwan/fzf-lua

local map = vim.keymap.set

local log_format = "--color=never --date=short --pretty=format:'%h %cd  %s (%an)%d'"

---Registers a keymap with a description.
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param desc string
local function gmap(mode, lhs, rhs, desc)
	map(mode, lhs, rhs, { desc = desc })
end

---Opens the history of the current file, the repository or the function under the cursor.
---Ported from bruhtus' `enable#fugitive_log`.
---See: https://github.com/bruhtus/dotfiles/blob/master/.vim/after/autoload/enable/fugitive_log.vim
local function git_log_normal()
	local choice = vim.fn.confirm(
		"Current file or All or Specific function git commit(s)?",
		"&NCancel\n&JCurrent\n&KAll\n&LFunction",
		1
	)

	if choice == 2 then
		-- `--follow` tracks the file across renames
		vim.cmd("-tab Git log " .. log_format .. " --follow %")
	elseif choice == 3 then
		vim.cmd("-tab Git log " .. log_format)
	elseif choice == 4 then
		-- Git must recognize functions for this filetype, otherwise nothing matches
		local func = vim.fn.expand("<cword>")
		local file = vim.fn.expand("%:p")
		vim.cmd(("-tab Git log %s -L :%s:%s"):format(log_format, func, file))
	end
end

---Opens the history of the selected line range.
local function git_log_visual()
	-- Leave visual mode so the '< and '> marks match the current selection
	vim.cmd("normal! \27")
	local first = vim.fn.line("'<")
	local last = vim.fn.line("'>")
	local file = vim.fn.expand("%:p")

	vim.cmd(("-tab Git log %s -L %d,%d:%s"):format(log_format, first, last, file))
	vim.cmd("redraw!")
end

---Returns the ordered visual selection range for partial hunk operations.
---@return integer[] range `{ first, last }`
local function visual_range()
	local a, b = vim.fn.line("."), vim.fn.line("v")
	return { math.min(a, b), math.max(a, b) }
end

-- Fugitive

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("GitFugitiveBlame", { clear = true }),
	pattern = "fugitiveblame",
	callback = function()
		vim.cmd("vertical resize 45")
	end,
})

-- See: lua/features/close_view.lua
require("features.close_view").setup()

-- Status and staging
gmap("n", "<leader>gg", "<cmd>silent tab Git<cr>", "Git status")
gmap("n", "<leader>ga", "<cmd>silent Gwrite<cr>", "Stage current file")
gmap("n", "<leader>gu", "<cmd>Gread<cr>", "Restore file from index (undoable)")

-- Commit (`:wq` confirms, `:q` aborts)
gmap("n", "<leader>gc", "<cmd>Git commit<cr>", "Commit")
gmap("n", "<leader>gC", "<cmd>Git commit --amend<cr>", "Amend last commit")

-- Remote and stash. Force push, rebase and similar are left to the terminal
gmap("n", "<leader>gp", "<cmd>Git push<cr>", "Push")
gmap("n", "<leader>gS", "<cmd>Git stash push --include-untracked<cr>", "Stash push (incl. untracked)")

-- Log
gmap("n", "<leader>gl", "<cmd>-tab Git log --color=never --oneline --graph --decorate<cr>", "Git log (oneline)")
gmap("n", "<leader>gL", "<cmd>-tab Git log --color=never --stat -p --decorate --date=short<cr>", "Git log (expanded)")
gmap("n", "<leader>go", git_log_normal, "Git log (file/all/function)")
gmap("x", "<leader>go", git_log_visual, "Git log (selection)")

-- Diff and blame
gmap("n", "<leader>gd", "<cmd>silent Gvdiffsplit<cr>", "Diff against index")
gmap("n", "<leader>gh", "<cmd>silent Gvdiffsplit HEAD<cr>", "Diff against HEAD")
gmap("n", "<leader>gb", "<cmd>silent Git blame<cr>", "Git blame")
gmap("n", "<leader>ge", "<cmd>.Git blame<cr>", "Git blame (line)")

-- Browser
gmap("n", "<leader>gw", "<cmd>GBrowse<cr>", "Open file in browser")
gmap("x", "<leader>gw", ":GBrowse<cr>", "Open selection in browser")

-- Conflicts: //2 is the target (ours), //3 is the merge (theirs).
-- Only the entry point uses <leader>, picking a side stays quick
gmap("n", "<leader>gx", "<cmd>Gvdiffsplit!<cr>", "Resolve conflicts (3-way diff)")
gmap({ "n", "x" }, "dxo", "<cmd>diffget //2<cr>", "Conflict: take ours (target)")
gmap({ "n", "x" }, "dxt", "<cmd>diffget //3<cr>", "Conflict: take theirs (merge)")

-- Gitsigns

local diff_overlay = false

local signs = {
	add = { text = "+" },
	change = { text = "~" },
	delete = { text = "_" },
	topdelete = { text = "‾" },
	changedelete = { text = "~" },
}

require("gitsigns").setup({
	signcolumn = false,
	numhl = false,
	word_diff = false,
	current_line_blame = false,
	signs = vim.tbl_extend("force", signs, { untracked = { text = "+" } }),
	signs_staged = signs,

	-- Keymaps are buffer-local so the native `]c` / `[c` keep working outside
	-- tracked buffers and in diff mode (e.g. `Gvdiffsplit`)
	on_attach = function(bufnr)
		local gs = require("gitsigns")

		local function bmap(mode, lhs, rhs, desc)
			map(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		---Navigates hunks, falling back to the native diff motions in diff mode.
		---@param direction "next"|"prev"
		local function nav(direction)
			return function()
				if vim.wo.diff then
					vim.cmd.normal({ direction == "next" and "]c" or "[c", bang = true })
				else
					gs.nav_hunk(direction, { navigation_message = false })
				end
			end
		end

		bmap("n", "]c", nav("next"), "Next hunk")
		bmap("n", "[c", nav("prev"), "Prev hunk")

		bmap("n", "<leader>hs", gs.stage_hunk, "Stage/unstage hunk")
		bmap("x", "<leader>hs", function()
			gs.stage_hunk(visual_range())
		end, "Stage/unstage selection")

		bmap("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
		bmap("x", "<leader>hr", function()
			gs.reset_hunk(visual_range())
		end, "Reset selection")

		bmap("n", "<leader>hp", gs.preview_hunk_inline, "Preview hunk")
		bmap("n", "<leader>hb", gs.toggle_current_line_blame, "Toggle current line blame")
		bmap("n", "<leader>hg", gs.toggle_signs, "Toggle git signs")
		bmap("n", "<leader>hd", function()
			diff_overlay = not diff_overlay
			gs.toggle_deleted(diff_overlay)
			gs.toggle_linehl(diff_overlay)
		end, "Toggle diff overlay")

		-- Text object: `vih` selects a hunk, `dih` deletes it
		bmap({ "o", "x" }, "ih", "<cmd>Gitsigns select_hunk<cr>", "Select hunk")
	end,
})

-- Fzf Integration

if pcall(require, "fzf-lua") then
	-- <C-a> creates a branch named after the query and switches to it
	gmap("n", "<leader>gfb", function()
		require("fzf-lua").git_branches({
			-- Hint shown at the top of the fzf popup
			header = "<enter> checkout | <C-a> new branch from query | <C-x> delete | <C-d> force delete",
			actions = {
				["ctrl-a"] = {
					fn = function(selected)
						local name = vim.trim(selected[1] or "")
						if name ~= "" then
							vim.schedule(function()
								vim.cmd("Git switch -c " .. name)
							end)
						end
					end,
					field_index = "{q}",
				},
			},
		})
	end, "Git branches (checkout / <C-a> new)")

	gmap("n", "<leader>gfc", "<cmd>FzfLua git_commits<cr>", "Git commits (project)")
	gmap("n", "<leader>gfu", "<cmd>FzfLua git_bcommits<cr>", "Git commits (current file)")
	gmap("n", "<leader>gfs", "<cmd>FzfLua git_status<cr>", "Git status (modified files)")
	gmap("n", "<leader>gfh", "<cmd>FzfLua git_hunks<cr>", "Git hunks")
	gmap("n", "<leader>gfd", "<cmd>FzfLua git_diff<cr>", "Git diff")
	gmap("n", "<leader>gfa", "<cmd>FzfLua git_stash<cr>", "Git stash (apply/pop/drop)")
	gmap("n", "<leader>gff", function()
		require("fzf-lua").git_files({ cmd = "git ls-files --cached --others --exclude-standard" })
	end, "Git files")
end
