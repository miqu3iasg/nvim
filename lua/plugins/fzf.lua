-- lua/plugins/fzf.lua

-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/after/autoload/enable/fzf.vim
-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/plugin/fzf.vim
-- See: https://github.com/james-orcales/james-orcales/blob/main/home/.config/nvim/init.lua

local function search_pending_comments()
	require("fzf-lua").grep({
		search = [[\b(TODO|FIXME|HACK|BUG|XXX)\b]],
		no_esc = true,
		prompt = "TODO/FIXME> ",
		rg_opts = "--column --line-number --no-heading --color=always --smart-case "
			.. "--max-columns=4096 --max-filesize=1M "
			.. "--glob '!**/{.git,node_modules,build,dist,target,vendor,.venv,__pycache__}/**' "
			.. "--glob '!*.{min.js,min.css,map,lock}' "
			.. "-e",
	})
end

-- Java modifiers shared by several patterns
local JAVA_TYPE_MODS = [=[(?:(?:abstract|final|sealed|non-sealed|static|strictfp)\s+)*]=]
local JAVA_TYPE_REF = [=[[\w.<>\[\],? ]+]=]

-- Per-language regexes (ripgrep syntax) used to explore a module's public API.
-- `patterns` is an ordered list: the order here is the order of the menu.
local languages = {
	C = {
		curbuf = false,
		patterns = {
			{
				label = "Package (#include)",
				re = [=[^\s*#\s*include\s+[<"][^>"]+[>"]]=],
				globs = "*.h *.c !*test*",
			},
			{
				label = "Function",
				re = [=[^[A-Za-z_][A-Za-z0-9_ \t\*]*[ \t\*][A-Za-z_][A-Za-z0-9_]*[ \t]*\(]=],
				globs = "*.h *.c !*test*",
			},
			{
				label = "Macro (all)",
				re = [=[^\s*#\s*define\s+[A-Za-z_][A-Za-z0-9_]*]=],
				globs = "*.h *.c !*test*",
			},
			{
				label = "Macro (function-like)",
				re = [=[^\s*#\s*define\s+[A-Za-z_][A-Za-z0-9_]*\(]=],
				globs = "*.h *.c !*test*",
			},
			{
				label = "Macro (constant)",
				re = [=[^\s*#\s*define\s+[A-Za-z_][A-Za-z0-9_]*(\s|$)]=],
				globs = "*.h *.c !*test*",
			},
			{
				label = "Type (all)",
				re = [=[^(typedef +)?(struct|union|enum) +[A-Za-z_][A-Za-z0-9_]* *(\{|$)|^typedef .*;|^\} *[A-Za-z_][A-Za-z0-9_]* *;]=],
				globs = "*.h *.c !*test*",
			},
			{
				label = "Struct",
				re = [=[^\s*(typedef\s+)?struct\s+[A-Za-z_][A-Za-z0-9_]*\s*(\{|$)]=],
				globs = "*.h *.c !*test*",
			},
			{
				label = "Union",
				re = [=[^\s*(typedef\s+)?union\s+[A-Za-z_][A-Za-z0-9_]*\s*(\{|$)]=],
				globs = "*.h *.c !*test*",
			},
			{
				label = "Enum",
				re = [=[^\s*(typedef\s+)?enum\s+[A-Za-z_][A-Za-z0-9_]*\s*(\{|$)]=],
				globs = "*.h *.c !*test*",
			},
			{
				label = "Typedef",
				re = [=[^\s*typedef\s+.*;|^\} *[A-Za-z_][A-Za-z0-9_]* *;]=],
				globs = "*.h *.c !*test*",
			},
		},
	},

	Java = {
		curbuf = false,
		patterns = {
			{
				label = "Package",
				re = [=[^\s*package\s+[\w.]+\s*;]=],
				globs = "*.java !*Test*",
			},
			{
				label = "Import",
				re = [=[^\s*import\s+(static\s+)?[\w.*]+\s*;]=],
				globs = "*.java !*Test*",
			},
			{
				label = "Class",
				re = [=[^\s*public\s+]=] .. JAVA_TYPE_MODS .. [=[class\s+\w+]=],
				globs = "*.java !*Test*",
			},
			{
				label = "Interface",
				re = [=[^\s*public\s+]=] .. JAVA_TYPE_MODS .. [=[interface\s+\w+]=],
				globs = "*.java !*Test*",
			},
			{
				label = "Enum",
				re = [=[^\s*public\s+]=] .. JAVA_TYPE_MODS .. [=[enum\s+\w+]=],
				globs = "*.java !*Test*",
			},
			{
				label = "Record",
				re = [=[^\s*public\s+]=] .. JAVA_TYPE_MODS .. [=[record\s+\w+]=],
				globs = "*.java !*Test*",
			},
			{
				label = "Annotation",
				re = [=[^\s*public\s+]=] .. JAVA_TYPE_MODS .. [=[@interface\s+\w+]=],
				globs = "*.java !*Test*",
			},
			{
				label = "Type (all)",
				re = [=[^\s*public\s+]=] .. JAVA_TYPE_MODS .. [=[(?:class|interface|enum|record|@interface)\s+\w+]=],
				globs = "*.java !*Test*",
			},
			{
				label = "Method",
				re = [=[^\s*public\s+(?:(?:static|final|abstract|synchronized|native|default|strictfp)\s+)*(?:<[^>]+>\s+)?]=]
					.. JAVA_TYPE_REF
					.. [=[\s+\w+\s*\(]=],
				globs = "*.java !*Test*",
			},
			{
				label = "Constructor",
				re = [=[^\s*public\s+[A-Z]\w*\s*\(]=],
				globs = "*.java !*Test*",
			},
			{
				label = "Constant (static final)",
				re = [=[^\s*public\s+static\s+final\s+]=] .. JAVA_TYPE_REF .. [=[\s+\w+\s*(=|;)]=],
				globs = "*.java !*Test*",
			},
			{
				label = "Field (all)",
				re = [=[^\s*public\s+(?:(?:static|final|volatile|transient)\s+)*]=]
					.. JAVA_TYPE_REF
					.. [=[\s+\w+\s*(=|;)]=],
				globs = "*.java !*Test*",
			},
		},
	},

	Python = {
		curbuf = true,
		patterns = {
			{
				label = "Package (all imports)",
				re = [=[^\s*(from\s+[\w.]+\s+)?import\s+[\w.*, ()]+]=],
				globs = "*.py !*test*",
			},
			{
				label = "Import",
				re = [=[^\s*import\s+[\w.*, ()]+]=],
				globs = "*.py !*test*",
			},
			{
				label = "From-import",
				re = [=[^\s*from\s+[\w.]+\s+import\s+]=],
				globs = "*.py !*test*",
			},
			{
				label = "Function (top-level)",
				re = [=[^(async\s+)?def\s+[A-Za-z_]\w*]=],
				globs = "*.py !*test*",
			},
			{
				label = "Method",
				re = [=[^\s+(async\s+)?def\s+[A-Za-z_]\w*]=],
				globs = "*.py !*test*",
			},
			{
				label = "Function (all)",
				re = [=[^\s*(async\s+)?def\s+[A-Za-z_]\w*]=],
				globs = "*.py !*test*",
			},
			{
				label = "Async function",
				re = [=[^\s*async\s+def\s+[A-Za-z_]\w*]=],
				globs = "*.py !*test*",
			},
			{
				label = "Class",
				re = [=[^class\s+[A-Za-z_]\w*]=],
				globs = "*.py !*test*",
			},
			{
				label = "Class (nested)",
				re = [=[^\s+class\s+[A-Za-z_]\w*]=],
				globs = "*.py !*test*",
			},
			{
				label = "Decorator",
				re = [=[^\s*@[A-Za-z_][\w.]*]=],
				globs = "*.py !*test*",
			},
			{
				label = "Constant",
				re = [=[^[A-Z][A-Z0-9_]*\s*(:[^=]+)?=]=],
				globs = "*.py !*test*",
			},
		},
	},

	Lua = {
		curbuf = true,
		patterns = {
			{
				label = "Package (require)",
				re = [=[\brequire\s*\(?\s*["'][^"']+["']]=],
				globs = "*.lua",
			},
			{
				label = "Function (all)",
				re = [=[^\s*(local\s+)?function\s+[A-Za-z0-9_.:]+\s*\(|^\s*(local\s+)?[A-Za-z0-9_.]+\s*=\s*function\s*\(]=],
				globs = "*.lua",
			},
			{
				label = "Local function",
				re = [=[^\s*local\s+function\s+[A-Za-z0-9_]+\s*\(]=],
				globs = "*.lua",
			},
			{
				label = "Module/global function",
				re = [=[^\s*function\s+[A-Za-z0-9_.]+\s*\(]=],
				globs = "*.lua",
			},
			{
				label = "Method (obj:name)",
				re = [=[^\s*(local\s+)?function\s+[A-Za-z0-9_.]+:[A-Za-z0-9_]+\s*\(]=],
				globs = "*.lua",
			},
			{
				label = "Assigned function (x = function)",
				re = [=[^\s*(local\s+)?[A-Za-z0-9_.]+\s*=\s*function\s*\(]=],
				globs = "*.lua",
			},
		},
	},
}

-- Returns the key of `languages` for a path or file name, or nil if unknown
local function detect_language(path)
	if not path or path == "" then
		return nil
	end
	local name = vim.fs.basename(path):lower()
	if name:match("%.[ch]$") or name == "cmakelists.txt" then
		return "C"
	elseif name:match("%.java$") or name == "pom.xml" or name:match("^build%.gradle") then
		return "Java"
	elseif name:match("%.py$") or name == "pyproject.toml" or name == "setup.py" then
		return "Python"
	elseif name:match("%.lua$") then
		return "Lua"
	end
end

-- Returns the most frequent recognized language among the files in `dir`
local function detect_language_in_dir(dir)
	local handle = vim.uv.fs_scandir(dir)
	if not handle then
		return nil
	end
	local counts = {}
	while true do
		local name, kind = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end
		local lang = kind == "file" and detect_language(name) or nil
		if lang then
			counts[lang] = (counts[lang] or 0) + 1
		end
	end
	local best, best_n
	for lang, n in pairs(counts) do
		if not best_n or n > best_n or (n == best_n and lang < best) then
			best, best_n = lang, n
		end
	end
	return best
end

-- Picks a category for the current language and greps it. Falls back to live_grep
local function module_api_search()
	local fzf = require("fzf-lua")
	local path = vim.api.nvim_buf_get_name(0)
	local in_oil = vim.startswith(path, "oil://")

	-- Directory to search: the one oil is showing, otherwise the nvim cwd
	local dir = vim.uv.cwd()
	if in_oil then
		local ok, oil = pcall(require, "oil")
		local oil_dir = ok and oil.get_current_dir() or nil
		if oil_dir then
			dir = oil_dir
		end
	end

	local lang_name
	if in_oil then
		lang_name = detect_language_in_dir(dir)
	else
		lang_name = detect_language(path)
	end
	if not lang_name then
		fzf.live_grep({ cwd = dir })
		return
	end

	local lang = languages[lang_name]
	local use_curbuf = lang.curbuf and not in_oil

	-- Menu keeps the order defined in `languages` ("Any" always first)
	local entries = {}
	local labels = { "Any" }
	for _, p in ipairs(lang.patterns) do
		entries[p.label] = p
		table.insert(labels, p.label)
	end

	fzf.fzf_exec(labels, {
		prompt = string.format("Search Package (%s) > ", lang_name),
		actions = {
			default = function(selected)
				local label = selected and selected[1]
				if not label then
					return
				end
				if label == "Any" then
					fzf.live_grep({ cwd = dir })
					return
				end

				local entry = entries[label]
				if not entry then
					return
				end
				local search = entry.re
				local operation = fzf.grep
				if use_curbuf then
					operation = fzf.grep_curbuf
				elseif entry.globs then
					search = search .. " -- " .. entry.globs
				end

				-- silent, the previewer cannot convert every regex to a vim pattern and would
				-- otherwise report "unable to init vim,regex" (fzf-lua issue 1858)
				operation({ search = search, no_esc = true, silent = true, cwd = dir })
			end,
		},
	})
end

-- (lazy's `opts = function() ... end`, now called directly)
local function make_opts()
	local actions = require("fzf-lua").actions

	return {
		file_icons = false,
		git_icons = false,

		winopts = {
			on_create = function(e)
				if e.winid and vim.api.nvim_win_is_valid(e.winid) then
					vim.api.nvim_win_set_config(e.winid, { title = "" })
				end
			end,

			-- split       = "botright 10new",
			-- border      = "none",
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
		},

		previewers = {
			builtin = {
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

		-- Hide the line and column fields from grep results
		grep = {
			fzf_opts = {
				["--delimiter"] = ":",
				["--with-nth"] = "1,4..",
			},
		},
	}
end

require("fzf-lua").setup(make_opts())

local function set_fzf_hl()
	vim.api.nvim_set_hl(0, "FzfLuaBorder", { fg = "#2a2a2a" })
	vim.api.nvim_set_hl(0, "FzfLuaPreviewBorder", { fg = "#2a2a2a" })
end

set_fzf_hl()

vim.api.nvim_create_autocmd("ColorScheme", { callback = set_fzf_hl })

vim.api.nvim_create_user_command("Todo", search_pending_comments, {
	desc = "Fzf: search TODO/FIXME/HACK/BUG/XXX in the current directory",
})

vim.api.nvim_create_user_command("Api", module_api_search, {
	desc = "Fzf: explore the API of the current module via regex",
})

vim.keymap.set("n", "<leader>ff", "<cmd>FzfLua files<cr>", {
	desc = "Fzf: find files in cwd (respects .gitignore)",
})

vim.keymap.set("n", "<leader>fu", "<cmd>FzfLua files cwd=%:p:h<cr>", {
	desc = "Fzf: find files in the current buffer's directory",
})

vim.keymap.set("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "Fzf: switch between open buffers" })
vim.keymap.set("n", "<leader>fo", "<cmd>FzfLua oldfiles<cr>", { desc = "Fzf: reopen recently edited files" })
vim.keymap.set("n", "<leader>fp", "<cmd>FzfLua zoxide<cr>", { desc = "Fzf: jump to a frequent directory (zoxide)" })
vim.keymap.set("n", "<leader>fg", "<cmd>FzfLua live_grep<cr>", { desc = "Fzf: live grep across all files in cwd" })
vim.keymap.set("n", "<leader>fw", "<cmd>FzfLua grep_cword<cr>", { desc = "Fzf: grep the word under the cursor in cwd" })
vim.keymap.set("n", "<leader>fl", "<cmd>FzfLua blines<cr>", { desc = "Fzf: search lines in the current buffer" })
vim.keymap.set("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", { desc = "Fzf: search all keymaps" })
vim.keymap.set("n", "<leader>fz", "<cmd>FzfLua<cr>", { desc = "Fzf: open the full picker menu" })

vim.keymap.set("n", "<leader>fd", "<cmd>FzfLua diagnostics_workspace<cr>", {
	desc = "Fzf: list LSP diagnostics for the whole workspace",
})

vim.keymap.set("n", "<leader>fc", "<cmd>FzfLua resume<cr>", {
	desc = "Fzf: resume the last picker with its previous query",
})

vim.keymap.set("n", "<leader>fe", search_pending_comments, {
	desc = "Fzf: list TODO/FIXME/HACK/BUG/XXX in current directory",
})

vim.keymap.set("n", "<leader>fs", module_api_search, {
	desc = "Fzf: explore module API (functions/types) via regex",
})
