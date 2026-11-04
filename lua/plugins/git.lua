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
-- See: https://github.com/lewis6991/gitsigns.nvim
-- See: https://github.com/ibhagwan/fzf-lua

local map = vim.keymap.set

-- Helpers

-- Registers a keymap whose description is prefixed by its plugin.
local function gmap(mode, lhs, rhs, desc)
	map(mode, lhs, rhs, { desc = desc })
end

-- Prompts for a branch name and creates + switches to it.
local function git_new_branch()
	vim.ui.input({ prompt = "New branch: " }, function(name)
		name = name and vim.trim(name) or ""
		if name ~= "" then
			vim.cmd("Git switch -c " .. name)
		end
	end)
end

-- Asks for confirmation before running a destructive action.
local function confirm_then(msg, fn)
	return function()
		if vim.fn.confirm(msg, "&Yes\n&No", 2) == 1 then
			fn()
		end
	end
end

-- Fugitive

-- Adjust the default blame view width to fit the author, timestamp and summary.
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("GitFugitiveBlame", { clear = true }),
	pattern = "fugitiveblame",
	callback = function()
		vim.cmd("vertical resize 45")
	end,
})

-- See: lua/features/close_view.lua
-- Registers the Fugitive close-view keymaps and autocmds
require("features.close_view").setup()

gmap("n", "<leader>gs", "<cmd>silent tab Git<cr>", "Git status")

-- Whole-file staging
gmap("n", "<leader>ga", "<cmd>silent Gwrite<cr>", "Stage current file")
gmap("n", "<leader>gA", "<cmd>silent Git reset -q -- %<cr>", "Unstage current file")
gmap("n", "<leader>gr", "<cmd>Gread<cr>", "Restore file from index (undoable)")

-- Commit (opens the message buffer; `:wq` confirms, `:q` aborts)
gmap("n", "<leader>gc", "<cmd>Git commit<cr>", "Commit")
gmap("n", "<leader>gC", "<cmd>Git commit --amend<cr>", "Amend last commit")

-- Remote. Anything fancier (force push, rebase, ...) is left to the terminal
gmap("n", "<leader>gp", "<cmd>Git push<cr>", "Push")
gmap("n", "<leader>gP", "<cmd>Git pull --rebase<cr>", "Pull (rebase)")
gmap("n", "<leader>gF", "<cmd>Git fetch --all --prune<cr>", "Fetch all + prune")

-- Branches and stash
gmap("n", "<leader>gn", git_new_branch, "New branch (switch -c)")
gmap("n", "<leader>gZ", "<cmd>Git stash push --include-untracked<cr>", "Stash push (incl. untracked)")

-- Diff, blame and merge conflicts
gmap("n", "<leader>gd", "<cmd>silent Gvdiffsplit<cr>", "Diff against index")
gmap("n", "<leader>gh", "<cmd>silent Gvdiffsplit HEAD<cr>", "Diff against HEAD")
gmap("n", "<leader>gb", "<cmd>silent Git blame<cr>", "Git blame")
gmap("n", "<leader>ge", "<cmd>.Git blame<cr>", "Git blame (line)")

-- Conflict resolution: open the 3-way diff, then pick a side per hunk.
-- Buffers: //2 = target (ours / HEAD), //3 = merge (theirs / incoming)
gmap("n", "<leader>gx", "<cmd>Gvdiffsplit!<cr>", "Resolve conflicts (3-way diff)")
gmap({ "n", "x" }, "<leader>g2", "<cmd>diffget //2<cr>", "Conflict: take ours (target)")
gmap({ "n", "x" }, "<leader>g3", "<cmd>diffget //3<cr>", "Conflict: take theirs (merge)")

-- Ported from the Vimscript `enable#fugitive_log` functions from bruhtus
-- <https://github.com/bruhtus> dotfiles. Both open the result in a new tab
-- through vim-fugitive's `:Git` command
-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/after/autoload/enable/fugitive_log.vim

local log_format = "--color=never --date=short --pretty=format:'%h %cd  %s (%an)%d'"

local function git_log_normal()
	local choice = vim.fn.confirm(
		"Current file or All or Specific function git commit(s)?",
		"&NCancel\n&JCurrent\n&KAll\n&LFunction",
		1
	)

	if choice == 2 then
		-- `--follow` keeps tracking the file across renames
		vim.cmd("-tab Git log " .. log_format .. " --follow %")
	elseif choice == 3 then
		-- Repository-wide history
		vim.cmd("-tab Git log " .. log_format)
	elseif choice == 4 then
		-- Uses the word under the cursor as the function name. Git must be able
		-- to recognize functions for this filetype, otherwise it reports no match
		local func = vim.fn.expand("<cword>")
		local file = vim.fn.expand("%:p")
		vim.cmd(("-tab Git log %s -L :%s:%s"):format(log_format, func, file))
	end
end

-- Show the history of the selected line range
local function git_log_visual()
	-- Leave visual mode first so the '< and '> marks reflect the current
	-- selection rather than the previous one
	vim.cmd("normal! \27")
	local first = vim.fn.line("'<")
	local last = vim.fn.line("'>")
	local file = vim.fn.expand("%:p")

	-- `-L start,end:file` lists every commit that touched those lines
	vim.cmd(("-tab Git log %s -L %d,%d:%s"):format(log_format, first, last, file))
	vim.cmd("redraw!")
end

gmap("n", "<leader>go", git_log_normal, "Git log (file/all/function)")
gmap("x", "<leader>go", git_log_visual, "Git log (selection)")

-- gitsigns.nvim

-- Keymaps are buffer-local (set in `on_attach`) so they exist only in tracked
-- buffers. This also keeps the native `]c` / `[c` working outside of git
-- buffers and inside diff mode (e.g. during `Gvdiffsplit`).

-- Shared state for the diff overlay toggle
local diff_overlay = false

require("gitsigns").setup({
	signcolumn = false,
	numhl = false,
	word_diff = false,
	current_line_blame = false,

	on_attach = function(bufnr)
		local gs = require("gitsigns")

		local function bmap(mode, lhs, rhs, desc)
			map(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		-- Navigation: falls back to the native diff motions when in diff mode
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

		-- Visual selection range, ordered, for partial hunk operations
		local function visual_range()
			local a, b = vim.fn.line("."), vim.fn.line("v")
			return { math.min(a, b), math.max(a, b) }
		end

		-- Stage / reset
		bmap("n", "<leader>hs", gs.stage_hunk, "Stage/unstage hunk")
		bmap("x", "<leader>hs", function()
			gs.stage_hunk(visual_range())
		end, "Stage/unstage selection")

		bmap("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
		bmap("x", "<leader>hr", function()
			gs.reset_hunk(visual_range())
		end, "Reset selection")

		-- Whole buffer
		bmap("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
		bmap("n", "<leader>hU", gs.reset_buffer_index, "Unstage buffer")
		bmap(
			"n",
			"<leader>hR",
			confirm_then("Discard ALL unstaged changes in this file?", gs.reset_buffer),
			"Reset buffer (discard changes)"
		)

		-- Inspect
		bmap("n", "<leader>hp", gs.preview_hunk_inline, "Preview hunk")

		bmap("n", "<leader>hd", function()
			diff_overlay = not diff_overlay
			gs.toggle_deleted(diff_overlay)
			gs.toggle_linehl(diff_overlay)
		end, "Toggle diff overlay")

		-- Review every changed hunk of the repository from the quickfix list
		bmap("n", "<leader>hq", function()
			gs.setqflist("all")
		end, "Hunks → quickfix (all files)")

		-- Text object: `vih` selects a hunk, `dih` deletes it, etc.
		bmap({ "o", "x" }, "ih", "<cmd>Gitsigns select_hunk<cr>", "Select hunk")
	end,
})

-- fzf-lua pickers

-- Merged into the existing fzf-lua setup; ignored if fzf-lua is absent

if pcall(require, "fzf-lua") then
	gmap("n", "<leader>gw", "<cmd>FzfLua git_branches<cr>", "Git branches (checkout)")
	gmap("n", "<leader>gi", "<cmd>FzfLua git_commits<cr>", "Git commits (project)")
	gmap("n", "<leader>gl", "<cmd>FzfLua git_bcommits<cr>", "Git commits (current file)")
	gmap("n", "<leader>gm", "<cmd>FzfLua git_status<cr>", "Git status (modified files)")
	gmap("n", "<leader>gu", "<cmd>FzfLua git_hunks<cr>", "Git hunks")
	gmap("n", "<leader>gk", "<cmd>FzfLua git_diff<cr>", "Git diff")
	gmap("n", "<leader>gz", "<cmd>FzfLua git_stash<cr>", "Git stash (apply/pop/drop)")

	gmap("n", "<leader>gf", function()
		require("fzf-lua").git_files({ cmd = "git ls-files --cached --others --exclude-standard" })
	end, "Git files")
end
