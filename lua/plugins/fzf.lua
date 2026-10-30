-- lua/plugins/fzf.lua

-- This configuration requires fzf, grep and ripgrep to be installed. fzf
-- provides the interactive fuzzy finder, while ripgrep powers the text
-- searches used by fzf-lua, including the declaration search.
--
-- On Arch Linux, install them with:
--
-- $ sudo pacman -S fzf grep ripgrep
--
-- The `:Declarations` command provides interactive, language-aware searches
-- for declarations such as functions, types, methods, imports and macros.
-- The implementation is in lua/infra/declarations.lua, which defines the
-- language-specific patterns, categories and file filters.
--
-- Search scope depends on the language and context: C and Java search
-- matching files in the current directory, while Python and Lua search
-- the current buffer. From an Oil directory view, the language is inferred
-- from the files and the directory is searched. If detection fails, or
-- `Any` is selected, the command falls back to live grep.
--
-- The `:Todo` command, also implemented in lua/infra/declarations.lua,
-- searches the current directory for pending comment markers: TODO, FIXME,
-- HACK, BUG and XXX. It is available through the defined mappings at the end
-- of the file.
--
-- These searches explore local source code, making it useful for studying
-- standard libraries and understanding implementations.
--
-- My local shell aliases in ~/.config/zsh/aliasesrc open language source
-- directories using the `std` + language convention:
--
-- $ stdc
-- $ stdjava
-- $ stdpython
--
-- These aliases and the fzf shell settings in ~/.zshrc are optional and
-- specific to my machine.
--
-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/after/autoload/enable/fzf.vim
-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/plugin/fzf.vim
-- See: https://github.com/james-orcales/james-orcales/blob/main/home/.config/nvim/init.lua

local fzf = require("fzf-lua")
local declarations = require("infra.declarations")

declarations.setup()

-- Directories that are never worth searching. Skipping them keeps the file
-- and grep pickers fast.
local ignored_dirs = {
	".git",
	"node_modules",
	".venv",
	"venv",
	"__pycache__",
	".mypy_cache",
	".pytest_cache",
	".cache",
	".gradle",
	".idea",
	".next",
	"target",
	"dist",
}

-- ripgrep: -g "!name" excludes a directory at any depth
local rg_globs = {}

-- fd: --exclude name (only used if you install fd later)
local fd_excludes = {}

for _, dir in ipairs(ignored_dirs) do
	table.insert(rg_globs, string.format('-g "!%s"', dir))
	table.insert(fd_excludes, string.format("--exclude %s", dir))
end

rg_globs = table.concat(rg_globs, " ")
fd_excludes = table.concat(fd_excludes, " ")

-- Plugin options and setup
local function make_opts()
	local actions = fzf.actions

	return {
		file_icons = false,
		git_icons = false,

		winopts = {
			on_create = function(e)
				if e.winid and vim.api.nvim_win_is_valid(e.winid) then
					vim.api.nvim_win_set_config(e.winid, { title = "" })
				end
			end,
			-- split = "botright 15new",
			-- border = "none",
			height = 0.95,
			width = 0.90,
			row = 0.35,
			col = 0.50,
			border = "single",
			fullscreen = false,
			title = false,
			title_flags = false,
			backdrop = 100,
			scrollbar = false,
			preview = {
				default = "bat",
				hidden = true,
				layout = "horizontal",
				title = false,
				horizontal = "right:50%",
				wrap = true,
				scrollbar = false,
				winopts = {
					number = false,
					relativenumber = false,
					cursorline = true,
					foldenable = false,
				},
			},
		},

		fzf_opts = {
			["--ansi"] = true,
			["--layout"] = "default",
			["--info"] = false,
			["--highlight-line"] = false,
			["--border"] = "none",
			["--no-scrollbar"] = true,
			["--no-footer"] = true,
		},

		previewers = {
			builtin = {
				title = false,
				treesitter = { enabled = true },
			},
		},

		actions = {
			files = {
				["enter"] = actions.file_edit_or_qf,
				["ctrl-t"] = actions.file_tabedit,
				["ctrl-x"] = actions.file_split,
			},
		},

		keymap = {
			builtin = {
				["<C-f>"] = "preview-page-down",
				["<C-b>"] = "preview-page-up",
			},
			fzf = {
				["ctrl-g"] = "execute(less -c -i --incsearch --search-options=W -g {})",
				["ctrl-z"] = "abort",
				["ctrl-u"] = "unix-line-discard",
				["ctrl-a"] = "beginning-of-line",
				["ctrl-e"] = "end-of-line",
				["ctrl-q"] = "select-all+accept",
			},
		},

		files = {
			-- fzf-lua defaults plus the extra ignores
			rg_opts = "--color=never --files --hidden --follow " .. rg_globs,
			fd_opts = "--color=never --hidden --type f --type l " .. fd_excludes,
		},

		-- Hide the line and column fields from grep results
		grep = {
			rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 "
				.. rg_globs
				.. " -e",
			fzf_opts = {
				["--delimiter"] = ":",
				["--with-nth"] = "1,4..",
			},
		},
	}
end

fzf.setup(make_opts())

-- Border highlights, reapplied whenever the colorscheme changes
local function set_fzf_hl()
	vim.api.nvim_set_hl(0, "FzfLuaBorder", { fg = "#2a2a2a" })
	vim.api.nvim_set_hl(0, "FzfLuaPreviewBorder", { fg = "#2a2a2a" })
	vim.api.nvim_set_hl(0, "FzfLuaSearch", { fg = "#D6C17A", bg = "#3D3525" })
	vim.api.nvim_set_hl(0, "FzfLuaCursorLine", { bg = "#1c1c1c" })
end

set_fzf_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_fzf_hl })

local km = vim.keymap.set

-- Finding files, buffers and directories
km("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "Fzf: find files in cwd (respects .gitignore)" })
km("n", "<leader>fu", "<cmd>FzfLua files cwd=%:p:h<cr>", { desc = "Fzf: find files in the current buffer's directory" })
km("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "Fzf: switch between open buffers" })
km("n", "<leader>fo", "<cmd>FzfLua oldfiles<cr>", { desc = "Fzf: reopen recently edited files" })
km("n", "<leader>fp", "<cmd>FzfLua zoxide<cr>", { desc = "Fzf: jump to a frequent directory (zoxide)" })

km("n", "<leader>fr", function()
	fzf.files({ cwd = vim.fn.expand("~/repos") })
end, { desc = "Fzf: find files in ~/repos" })

km("n", "<leader>fn", function()
	fzf.files({ cwd = vim.fn.expand("~/.config/nvim") })
end, { desc = "Fzf: find files in ~/.config/nvim" })

-- Searching text
km("n", "<leader>fg", "<cmd>FzfLua live_grep<cr>", { desc = "Fzf: live grep across all files in cwd" })
km("n", "<leader>fw", "<cmd>FzfLua grep_cword<cr>", { desc = "Fzf: grep the word under the cursor in cwd" })
km("n", "<leader>fl", "<cmd>FzfLua blines<cr>", { desc = "Fzf: search lines in the current buffer" })
km("n", "<leader>fe", declarations.search_pending_comments, { desc = "Fzf: list tasks in current directory" })
km("n", "<leader>fs", declarations.search, { desc = "Fzf: search declarations (functions/types/imports)" })

-- Diagnostics, keymaps, resuming and the full picker menu
km("n", "<leader>fx", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "Fzf: list LSP diagnostics in workspace" })
km("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", { desc = "Fzf: search all keymaps" })
km("n", "<leader>fc", "<cmd>FzfLua resume<cr>", { desc = "Fzf: resume the last picker with its previous query" })
km("n", "<leader>fz", "<cmd>FzfLua<cr>", { desc = "Fzf: open the full picker menu" })
