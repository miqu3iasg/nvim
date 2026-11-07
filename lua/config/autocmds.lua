-- lua/config/autocmds.lua

-- Side-effect-only file. Global autocommands that run alongside the rest of
-- the configuration. Each block names its group explicitly so it can be
-- inspected or cleared with :augroup.

-- Keep splits evenly sized after resizing the terminal
vim.api.nvim_create_autocmd("VimResized", {
	group = vim.api.nvim_create_augroup("cg/vim_resized", { clear = true }),
	callback = function()
		vim.cmd("wincmd =")
	end,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("cg/text_yank_post", { clear = true }),
	desc = "Highlight yanked text",
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Don't auto continue comments in new line
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("no_auto_comment", {}),
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- Turn off heavy features on big/minified files
-- A buffer counts as "big" based on file size and indents; the threshold and
-- the full heuristic live in lua/utils/bigfile.lua
local bigfile_group = vim.api.nvim_create_augroup("bigfile", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	group = bigfile_group,
	desc = "Disable heavy features on big files",
	callback = function(ev)
		if not require("utils.bigfile").is_big(ev.buf) then
			return
		end
		pcall(vim.treesitter.stop, ev.buf)
		vim.b[ev.buf].completion = false
		vim.diagnostic.disable(ev.buf)
		vim.opt_local.foldmethod = "manual"
		vim.opt_local.spell = false
		vim.opt_local.cursorline = false
		vim.opt_local.relativenumber = false
	end,
})

-- syntax highlighting for dotenv files
vim.api.nvim_create_autocmd("BufRead", {
	group = vim.api.nvim_create_augroup("dotenv_ft", { clear = true }),
	pattern = { ".env", ".env.*" },
	callback = function()
		vim.bo.filetype = "dosini"
	end,
})

-- On startup without file args, restore the tmux session, or open Oil.
-- "Without file args" means no arguments, or a single directory argument.
-- Session persistence (enabled() checks for tmux; load/save by directory) is
-- implemented in lua/features/sessions.lua.
-- `nested` lets the restored session fire its own autocmds (filetype, etc.)
-- and the work is scheduled so it runs after startup has finished.
vim.api.nvim_create_augroup("StartupBehavior", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
	group = "StartupBehavior",
	nested = true,
	callback = function()
		local argc = vim.fn.argc()
		local no_files = argc == 0 or (argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1)

		if not no_files then
			return
		end

		vim.schedule(function()
			-- Inside tmux, try to restore the session for this directory
			local sessions = require("features.sessions")
			if sessions.enabled() and sessions.load() then
				return
			end

			-- No session (or outside tmux), open Oil as before
			if argc == 0 then
				require("oil").open()
			else
				require("oil").open(vim.fn.argv(0))
			end
		end)
	end,
})

-- Save the session of the current directory on exit (inside tmux only).
-- Oil buffers are removed by sessions.save() before writing the session.
-- `pcall` so a failing save never blocks quitting.
vim.api.nvim_create_autocmd("VimLeavePre", {
	group = vim.api.nvim_create_augroup("SessionSave", { clear = true }),
	callback = function()
		local sessions = require("features.sessions")
		if sessions.enabled() then
			pcall(sessions.save)
		end
	end,
})

-- Auto-create parent directories on save (skips virtual buffers like oil://, fugitive://, term://, etc.)
vim.api.nvim_create_augroup("CreateDirs", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
	group = "CreateDirs",
	pattern = "*",
	callback = function(event)
		if event.match:match("^%w+://") then
			return
		end
		local file_path = vim.fn.expand("<afile>:p:h")
		if vim.fn.isdirectory(file_path) == 0 then
			vim.fn.mkdir(file_path, "p")
		end
	end,
})

-- Jump to last cursor position when opening a file
-- (only if the '" mark is inside the buffer, and not in a commit message)
-- The commit check uses the file name because on BufReadPost the FileType
-- event has not fired yet, so `vim.b.filetype` is still nil.
vim.api.nvim_create_autocmd("BufReadPost", {
	group = vim.api.nvim_create_augroup("LastCursorPos", { clear = true }),
	desc = "Jump to last cursor position when opening a file",
	callback = function(args)
		local valid_line = vim.fn.line([['"]]) >= 1 and vim.fn.line([['"]]) < vim.fn.line("$")
		local name = vim.api.nvim_buf_get_name(args.buf)
		local is_commit = name:match("/(COMMIT_EDITMSG|MERGE_MSG|TAG_EDITMSG|NOTES_EDITMSG)$") ~= nil
		if valid_line and not is_commit then
			vim.cmd([[normal! g`"]])
		end
	end,
})

-- Strip trailing whitespace when a buffer is written
-- Skips unmodifiable buffers and special ones ("nofile", "terminal", etc.)
-- with a nonempty 'buftype'; the view is saved/restored so the cursor and
-- scroll position do not move.
vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("cg/whitespace", {}),
	pattern = "*",
	callback = function(args)
		if not vim.bo[args.buf].modifiable or vim.bo[args.buf].buftype ~= "" then
			return
		end

		local view = vim.fn.winsaveview()
		vim.cmd([[keepjumps keeppatterns silent! %s/\s\+$//e]])
		vim.fn.winrestview(view)
	end,
})

-- Close utility buffers with q or Esc
-- These filetypes become unfocused scratch/help windows: they get unlisted and
-- a buffer-local q/<Esc> mapping that closes the window.
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("cg/close_utility_buffers", { clear = true }),
	pattern = {
		"checkhealth",
		"conform-info",
		"fugitive",
		"fugitiveblame",
		"help",
		"nvim-pack",
		"lspinfo",
		"man",
		"nvim-undotree",
		"qf",
	},
	callback = function(args)
		vim.bo[args.buf].buflisted = false
		for _, key in ipairs({ "q", "<Esc>" }) do
			vim.keymap.set("n", key, "<cmd>close<cr>", {
				buffer = args.buf,
				silent = true,
				nowait = true,
				desc = "close buffer",
			})
		end
	end,
})

-- Auto-enter insert mode on terminal open, and clean up its UI
vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("cg/term_open", { clear = true }),
	desc = "Clean UI in terminal mode",
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.opt_local.spell = false
		vim.cmd("startinsert")
	end,
})

-- Configuration for builtin undotree
-- Open the undotree on the far left with a fixed width so the file window keeps
-- its layout.
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("cg/undotree_layout", { clear = true }),
	pattern = "nvim-undotree",
	callback = function()
		vim.cmd.wincmd("H")
		vim.api.nvim_win_set_width(0, 40)
	end,
})
