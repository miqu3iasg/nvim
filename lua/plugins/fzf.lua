-- lua/plugins/fzf.lua

-- Fuzzy finder for files, buffers, text, diagnostics and help, built on
-- fzf-lua. It gives a single interface for navigating a project and for
-- exploring the source code of a language's standard library through the
-- declaration search of the stdsrc feature.
--
-- fzf-lua must be installed through the plugin manager. The external tools must
-- be installed on the system, since fzf-lua only wraps them. On Arch Linux:
--
-- $ sudo pacman -S fzf grep ripgrep fd
--
-- The `:StdSrc` command is registered here, and the directories it searches are
-- defined in the stdsrc feature.
--
-- The shell aliases in `~/.config/zsh/aliasesrc` that open language source
-- directories, such as `stdc`, `stdjava` and `stdpython`, are optional and
-- specific to this machine.
--
-- See: lua/features/stdsrc.lua
-- See: lua/features/todos.lua
-- See: https://github.com/ibhagwan/fzf-lua
-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/after/autoload/enable/fzf.vim
-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/plugin/fzf.vim
-- See: https://github.com/james-orcales/james-orcales/blob/main/home/.config/nvim/init.lua

local fzf = require("fzf-lua")
local stdsrc = require("features.stdsrc")

stdsrc.setup()

-- Skipped by the file and grep pickers to keep them fast.
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

-- The ripgrep glob `-g "!name"` excludes a directory at any depth. The fd flag
-- `--exclude name` does the same for the detailed file picker.
local rg_globs = {}
local fd_excludes = {}

for _, dir in ipairs(ignored_dirs) do
	table.insert(rg_globs, string.format('-g "!%s"', dir))
	table.insert(fd_excludes, string.format("--exclude %s", dir))
end

rg_globs = table.concat(rg_globs, " ")
fd_excludes = table.concat(fd_excludes, " ")

---Build the options table passed to `fzf.setup()`.
---@return table<string, any>
local function make_opts()
	local actions = fzf.actions

	return {
		winopts = {
			on_create = function(e)
				if e.winid and vim.api.nvim_win_is_valid(e.winid) then
					vim.api.nvim_win_set_config(e.winid, { title = "" })
				end
			end,

			height = 0.95,
			width = 0.90,
			row = 0.35,
			col = 0.50,
			border = "single",

			-- height = 0.22,
			-- width = 1.0,
			-- row = 1.0,
			-- col = 0.0,
			-- border = { "", "─", "", "", "", "", "", "" },
			-- backdrop = false,

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
			["--highlight-line"] = true,
			["--info"] = "inline-right",
			["--pointer"] = " ",
			["--no-scrollbar"] = true,
			["--no-separator"] = true,
		},

		fzf_colors = {
			["bg+"] = { "bg", "CursorLine" },
			["fg+"] = { "fg", "Normal" },
			["prompt"] = { "fg", "Normal" },
			["gutter"] = { "bg", "Normal" },
			-- The pointer and the multi-select marker use the selected line
			-- background, which makes their column invisible.
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

		-- The fzf-lua defaults plus the extra ignores.
		files = {
			rg_opts = "--color=never --files --hidden --follow " .. rg_globs,
			fd_opts = "--color=never --hidden --type f --type l " .. fd_excludes,
		},

		-- The line and column fields are hidden from the results.
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

---Set the border highlights of the fzf-lua window and its preview. It also runs
---on every colorscheme change, because a colorscheme resets the highlight
---groups.
local function set_fzf_hl()
	vim.api.nvim_set_hl(0, "FzfLuaBorder", { fg = "#2a2a2a" })
	vim.api.nvim_set_hl(0, "FzfLuaPreviewBorder", { fg = "#2a2a2a" })
end

set_fzf_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("cg/fzf_hl", { clear = true }),
	callback = set_fzf_hl,
})

local km = vim.keymap.set

km("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "Fzf: find files in cwd (respects .gitignore)" })
km("n", "<leader>fd", "<cmd>FzfLua files cwd=%:p:h<cr>", { desc = "Fzf: find files in the current buffer's directory" })
km("n", "<leader>fz", "<cmd>FzfLua zoxide<cr>", { desc = "Fzf: jump to a frequent directory (zoxide)" })

km("n", "<leader>fr", function()
	fzf.files({ cwd = vim.fn.expand("~/repos") })
end, { desc = "Fzf: find files in ~/repos" })

km("n", "<leader>fn", function()
	fzf.files({ cwd = vim.fn.expand("~/.config/nvim") })
end, { desc = "Fzf: find files in ~/.config/nvim" })

km("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "Fzf: switch between open buffers" })
km("n", "<leader>fo", "<cmd>FzfLua oldfiles<cr>", { desc = "Fzf: reopen recently edited files" })

km("n", "<leader>fg", function()
	fzf.live_grep({ rg_glob = true })
end, { desc = "Fzf: live grep in cwd" })

km("n", "<leader>fw", "<cmd>FzfLua grep_cword<cr>", { desc = "Fzf: grep the word under the cursor in cwd" })
km("v", "<leader>fw", fzf.grep_visual, { desc = "Fzf: grep the visual selection" })
km("n", "<leader>fl", "<cmd>FzfLua blines<cr>", { desc = "Fzf: search lines in the current buffer" })

km("n", "<leader>fa", stdsrc.search_source, { desc = "Fzf: search declarations in the language's source repository" })
km("n", "<leader>fh", "<cmd>FzfLua help_tags<cr>", { desc = "Fzf: search Neovim help tags" })
km("n", "<leader>fm", "<cmd>FzfLua man_pages<cr>", { desc = "Fzf: search man pages" })

km("n", "<leader>ft", function()
	require("features.todos").fzf_search()
end, { desc = "Fzf: list tasks (TODO/FIXME/...)" })

km("n", "<leader>fx", "<cmd>FzfLua diagnostics_document<cr>", { desc = "Fzf: list LSP diagnostics in current buffer" })
km("n", "<leader>fX", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "Fzf: list LSP diagnostics in workspace" })

km("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", { desc = "Fzf: search all keymaps" })
km("n", "<leader>fc", "<cmd>FzfLua resume<cr>", { desc = "Fzf: resume the last picker with its previous query" })
