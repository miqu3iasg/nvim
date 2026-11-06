-- lua/plugins/fzf.lua

-- This configuration requires fzf, grep, ripgrep and fd to be installed. fzf
-- provides the interactive fuzzy finder and ripgrep powers the text searches
-- used by fzf-lua (including the declaration search).
--
-- On Arch Linux, install them with:
--
-- $ sudo pacman -S fzf grep ripgrep fd
--
-- The `:StdSrc` command provides interactive, language-aware
-- searches for declarations such as functions, types, methods, imports and
-- macros, on the source code of the language itself (standard library / API),
-- no matter where the current file lives. The language comes from the current
-- buffer (or, in an Oil directory view, from the files shown) and the
-- directories are defined in the `sources` table of lua/features/stdsrc.lua,
-- which also defines the language-specific patterns, categories and file
-- filters. If the language cannot be detected it asks which one to explore,
-- and `Any` falls back to live grep. Opening a result jumps to the declaration
-- in the language's source; go back with <C-o> or <C-^>.
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
local stdsrc = require("features.stdsrc")

stdsrc.setup()

-- Directories that are never worth searching. Skipping them keeps the file
-- and grep pickers fast.
---@type string[]
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

-- fd: --exclude name (used by the detailed file picker)
local fd_excludes = {}

for _, dir in ipairs(ignored_dirs) do
	table.insert(rg_globs, string.format('-g "!%s"', dir))
	table.insert(fd_excludes, string.format("--exclude %s", dir))
end

rg_globs = table.concat(rg_globs, " ")
fd_excludes = table.concat(fd_excludes, " ")

--- Builds the options table passed to `fzf.setup()`: window layout, fzf
--- flags, previewers, actions, keymaps, and the file and grep commands.
---@return table<string, any> opts fzf-lua setup options
local function make_opts()
	local actions = fzf.actions

	return {
		winopts = {
			-- Remove window title
			on_create = function(e)
				if e.winid and vim.api.nvim_win_is_valid(e.winid) then
					vim.api.nvim_win_set_config(e.winid, { title = "" })
				end
			end,

			-- Bottom layout
			-- height = 0.22,
			-- width = 1.0,
			-- row = 1.0,
			-- col = 0.0,
			-- border = { "", "─", "", "", "", "", "", "" },
			-- backdrop = false,

			-- Popup layout
			height = 0.95,
			width = 0.90,
			row = 0.35,
			col = 0.50,
			border = "single",

			title = false,
			title_flags = false,
			preview = {
				default = "bat",
				hidden = true,
				layout = "horizontal",
				title = false,
				horizontal = "right:50%",
				wrap = true,
				scrollbar = false,
			},
		},

		fzf_opts = {
			["--ansi"] = true,
			["--layout"] = "default",
			["--highlight-line"] = true, -- background on the whole selected line
			["--info"] = "inline-right", -- match counter at the right of the prompt
			["--pointer"] = " ",
			["--no-scrollbar"] = true,
			["--no-separator"] = true,
		},

		fzf_colors = {
			["bg+"] = { "bg", "CursorLine" },
			["fg+"] = { "fg", "Normal" },
			-- Prompt in the default text color
			["prompt"] = { "fg", "Normal" },
			-- Gutter of the unselected lines, same color as the editor background
			["gutter"] = { "bg", "Normal" },
			-- Same color as the selected line background, so the pointer and
			-- the multi-select marker column become invisible
			["pointer"] = { "bg", "CursorLine" },
			["marker"] = { "bg", "CursorLine" },
			["hl"] = { "fg", "Special" },
			["hl+"] = { "fg", "Special" },
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

--- Sets the border highlight groups of the fzf-lua window and its preview.
--- It runs once at startup and again whenever the colorscheme changes,
--- because a colorscheme resets the highlight groups.
local function set_fzf_hl()
	vim.api.nvim_set_hl(0, "FzfLuaBorder", { fg = "#2a2a2a" })
	vim.api.nvim_set_hl(0, "FzfLuaPreviewBorder", { fg = "#2a2a2a" })
end

set_fzf_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("cg/fzf_hl", { clear = true }),
	callback = set_fzf_hl,
})

-- Keymaps

local km = vim.keymap.set

-- Files and directories
km("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "Fzf: find files in cwd (respects .gitignore)" })
km("n", "<leader>fd", "<cmd>FzfLua files cwd=%:p:h<cr>", { desc = "Fzf: find files in the current buffer's directory" })
km("n", "<leader>fz", "<cmd>FzfLua zoxide<cr>", { desc = "Fzf: jump to a frequent directory (zoxide)" })

km("n", "<leader>fr", function()
	fzf.files({ cwd = vim.fn.expand("~/repos") })
end, { desc = "Fzf: find files in ~/repos" })

km("n", "<leader>fn", function()
	fzf.files({ cwd = vim.fn.expand("~/.config/nvim") })
end, { desc = "Fzf: find files in ~/.config/nvim" })

-- Buffers and history
km("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "Fzf: switch between open buffers" })
km("n", "<leader>fo", "<cmd>FzfLua oldfiles<cr>", { desc = "Fzf: reopen recently edited files" })

-- Text search
km("n", "<leader>fg", function()
	fzf.live_grep({ rg_glob = true })
end, { desc = "Fzf: live grep in cwd" })

km("n", "<leader>fw", "<cmd>FzfLua grep_cword<cr>", { desc = "Fzf: grep the word under the cursor in cwd" })
km("v", "<leader>fw", fzf.grep_visual, { desc = "Fzf: grep the visual selection" })
km("n", "<leader>fl", "<cmd>FzfLua blines<cr>", { desc = "Fzf: search lines in the current buffer" })

-- Docs and API
km("n", "<leader>fa", stdsrc.search_source, { desc = "Fzf: search declarations in the language's source repository" })
km("n", "<leader>fh", "<cmd>FzfLua help_tags<cr>", { desc = "Fzf: search Neovim help tags" })
km("n", "<leader>fm", "<cmd>FzfLua man_pages<cr>", { desc = "Fzf: search man pages" })

-- Tasks
-- Search is provided by the native module in lua/features/todos.lua.
km("n", "<leader>ft", function()
	require("features.todos").fzf_search()
end, { desc = "Fzf: list tasks (TODO/FIXME/...)" })

-- Diagnostics
km("n", "<leader>fx", "<cmd>FzfLua diagnostics_document<cr>", { desc = "Fzf: list LSP diagnostics in current buffer" })
km("n", "<leader>fX", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "Fzf: list LSP diagnostics in workspace" })

-- Misc
km("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", { desc = "Fzf: search all keymaps" })
km("n", "<leader>fc", "<cmd>FzfLua resume<cr>", { desc = "Fzf: resume the last picker with its previous query" })
