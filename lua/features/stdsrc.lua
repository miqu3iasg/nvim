-- lua/features/stdsrc.lua

-- Declaration search over the source repository of a language, such as its
-- standard library or API, so it can be explored without leaving the file being
-- edited. The language is detected from the current file, or from the shown
-- directory in an Oil view.
--
-- fzf-lua must be installed through the plugin manager. ripgrep must be
-- installed on the system. On Arch Linux:
--
-- $ sudo pacman -S ripgrep
--
-- The source directories of each language must already exist on the machine and
-- are listed in the `sources` table. The supported languages, declaration
-- patterns and file filters are defined in the `languages` table.
--
-- `setup()` registers the `:StdSrc` command and must be called once.
--
-- See: https://github.com/ibhagwan/fzf-lua
-- See: man:rg

local M = {}

local JAVA_TYPE_MODS = [=[(?:(?:abstract|final|sealed|non-sealed|static|strictfp)\s+)*]=]
local JAVA_TYPE_REF = [=[[\w.<>\[\],? ]+]=]
local JAVA_PUBLIC_TYPE = [=[^\s*public\s+]=] .. JAVA_TYPE_MODS

---One entry of the search menu.
---@class StdSrc.Pattern
---@field label string Text shown in the menu.
---@field re string Ripgrep regex that matches the declaration.
---@field globs? string Overrides the language's default `globs` for this entry.

---@class StdSrc.Language
---@field globs? string Default file filters, space separated, where `!` excludes. Applied to every pattern.
---@field patterns StdSrc.Pattern[] Menu entries, in menu order.

---@type table<string, StdSrc.Language>
local languages = {
	C = {
		globs = "*.h *.c !*test*",
		patterns = {
			{ label = "Package (#include)", re = [=[^\s*#\s*include\s+[<"][^>"]+[>"]]=] },
			{ label = "Function", re = [=[^[A-Za-z_][A-Za-z0-9_ \t\*]*[ \t\*][A-Za-z_][A-Za-z0-9_]*[ \t]*\(]=] },
			{ label = "Macro (all)", re = [=[^\s*#\s*define\s+[A-Za-z_][A-Za-z0-9_]*]=] },
			{ label = "Macro (function-like)", re = [=[^\s*#\s*define\s+[A-Za-z_][A-Za-z0-9_]*\(]=] },
			{ label = "Macro (constant)", re = [=[^\s*#\s*define\s+[A-Za-z_][A-Za-z0-9_]*(\s|$)]=] },
			{
				label = "Type (all)",
				re = [=[^(typedef +)?(struct|union|enum) +[A-Za-z_][A-Za-z0-9_]* *(\{|$)|^typedef .*;|^\} *[A-Za-z_][A-Za-z0-9_]* *;]=],
			},
			{ label = "Struct", re = [=[^\s*(typedef\s+)?struct\s+[A-Za-z_][A-Za-z0-9_]*\s*(\{|$)]=] },
			{ label = "Union", re = [=[^\s*(typedef\s+)?union\s+[A-Za-z_][A-Za-z0-9_]*\s*(\{|$)]=] },
			{ label = "Enum", re = [=[^\s*(typedef\s+)?enum\s+[A-Za-z_][A-Za-z0-9_]*\s*(\{|$)]=] },
			{ label = "Typedef", re = [=[^\s*typedef\s+.*;|^\} *[A-Za-z_][A-Za-z0-9_]* *;]=] },
		},
	},

	Java = {
		globs = "*.java !*Test*",
		patterns = {
			{ label = "Package", re = [=[^\s*package\s+[\w.]+\s*;]=] },
			{ label = "Import", re = [=[^\s*import\s+(static\s+)?[\w.*]+\s*;]=] },
			{ label = "Class", re = JAVA_PUBLIC_TYPE .. [=[class\s+\w+]=] },
			{ label = "Interface", re = JAVA_PUBLIC_TYPE .. [=[interface\s+\w+]=] },
			{ label = "Enum", re = JAVA_PUBLIC_TYPE .. [=[enum\s+\w+]=] },
			{ label = "Record", re = JAVA_PUBLIC_TYPE .. [=[record\s+\w+]=] },
			{ label = "Annotation", re = JAVA_PUBLIC_TYPE .. [=[@interface\s+\w+]=] },
			{ label = "Type (all)", re = JAVA_PUBLIC_TYPE .. [=[(?:class|interface|enum|record|@interface)\s+\w+]=] },
			{
				label = "Method",
				re = [=[^\s*public\s+(?:(?:static|final|abstract|synchronized|native|default|strictfp)\s+)*(?:<[^>]+>\s+)?]=]
					.. JAVA_TYPE_REF
					.. [=[\s+\w+\s*\(]=],
			},
			{ label = "Constructor", re = [=[^\s*public\s+[A-Z]\w*\s*\(]=] },
			{
				label = "Constant (static final)",
				re = [=[^\s*public\s+static\s+final\s+]=] .. JAVA_TYPE_REF .. [=[\s+\w+\s*(=|;)]=],
			},
			{
				label = "Field (all)",
				re = [=[^\s*public\s+(?:(?:static|final|volatile|transient)\s+)*]=]
					.. JAVA_TYPE_REF
					.. [=[\s+\w+\s*(=|;)]=],
			},
		},
	},

	Python = {
		-- Excludes `test`, `tests` and `test_*` instead of `*test*`, which would
		-- also drop the `unittest` package of the standard library.
		globs = "*.py !test !tests !test_*",
		patterns = {
			{ label = "Package (all imports)", re = [=[^\s*(from\s+[\w.]+\s+)?import\s+[\w.*, ()]+]=] },
			{ label = "Import", re = [=[^\s*import\s+[\w.*, ()]+]=] },
			{ label = "From-import", re = [=[^\s*from\s+[\w.]+\s+import\s+]=] },
			{ label = "Function (top-level)", re = [=[^(async\s+)?def\s+[A-Za-z_]\w*]=] },
			{ label = "Method", re = [=[^\s+(async\s+)?def\s+[A-Za-z_]\w*]=] },
			{ label = "Function (all)", re = [=[^\s*(async\s+)?def\s+[A-Za-z_]\w*]=] },
			{ label = "Async function", re = [=[^\s*async\s+def\s+[A-Za-z_]\w*]=] },
			{ label = "Class", re = [=[^class\s+[A-Za-z_]\w*]=] },
			{ label = "Class (nested)", re = [=[^\s+class\s+[A-Za-z_]\w*]=] },
			{ label = "Decorator", re = [=[^\s*@[A-Za-z_][\w.]*]=] },
			{ label = "Constant", re = [=[^[A-Z][A-Z0-9_]*\s*(:[^=]+)?=]=] },
		},
	},

	Lua = {
		globs = "*.lua",
		patterns = {
			{ label = "Package (require)", re = [=[\brequire\s*\(?\s*["'][^"']+["']]=] },
			{
				label = "Function (all)",
				re = [=[^\s*(local\s+)?function\s+[A-Za-z0-9_.:]+\s*\(|^\s*(local\s+)?[A-Za-z0-9_.]+\s*=\s*function\s*\(]=],
			},
			{ label = "Local function", re = [=[^\s*local\s+function\s+[A-Za-z0-9_]+\s*\(]=] },
			{ label = "Module/global function", re = [=[^\s*function\s+[A-Za-z0-9_.]+\s*\(]=] },
			{ label = "Method (obj:name)", re = [=[^\s*(local\s+)?function\s+[A-Za-z0-9_.]+:[A-Za-z0-9_]+\s*\(]=] },
			{
				label = "Assigned function (x = function)",
				re = [=[^\s*(local\s+)?[A-Za-z0-9_.]+\s*=\s*function\s*\(]=],
			},
		},
	},
}

-- Candidate directories for each language. The first candidate that exists
-- wins, so the preferred one comes first. Entries accept `~`, `$VARS` and glob
-- wildcards. When several directories match, the last one in alphabetical order
-- is used, which is the newest version for `python3.*`.
---@type table<string, string[]>
local sources = {
	-- stdc (glibc clone) and stdch (headers only)
	C = { "~/.local/share/stdsrc/glibc", "/usr/include" },
	-- stdjava (src.zip extracted per JDK, e.g. ~/.cache/jdk-src/java-21-openjdk)
	Java = { "~/.cache/jdk-src/*" },
	-- stdpy (sysconfig stdlib, e.g. /usr/lib/python3.13)
	Python = { "/usr/lib/python3.*" },
	-- The Lua standard library is C code, so it does not fit the Lua patterns.
	-- The Neovim runtime is the Lua API worth exploring.
	Lua = { "$VIMRUNTIME/lua" },
}

---Return the key of `languages` for a path, judged by the file name only. The
---name is matched by extension or by a well-known project file such as
---`pom.xml`.
---@param path? string
---@return string?
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

---Return the most frequent recognized language among the regular files in
---`dir`, without recursing. Ties are broken alphabetically by language name.
---@param dir string
---@return string?
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

---Return the language of the current buffer. In an Oil view it is the most
---frequent language among the files of the shown directory.
---@return string?
local function detect_current_language()
	local path = vim.api.nvim_buf_get_name(0)
	if not vim.startswith(path, "oil://") then
		return detect_language(path)
	end

	local ok, oil = pcall(require, "oil")
	local oil_dir = ok and oil.get_current_dir() or nil
	return oil_dir and detect_language_in_dir(oil_dir) or nil
end

---Return the first existing source directory of a language.
---@param lang_name string
---@return string?
local function get_source_dir(lang_name)
	for _, candidate in ipairs(sources[lang_name] or {}) do
		local matches = vim.fn.glob(vim.fs.normalize(candidate), false, true)
		for i = #matches, 1, -1 do
			if vim.fn.isdirectory(matches[i]) == 1 then
				return matches[i]
			end
		end
	end
	return nil
end

---Grep one menu entry in `dir`, filtered by the entry's globs or the language
---default. Globs are appended as `<regex> -- <globs>`, which is the syntax
---fzf-lua uses for file filters.
---@param entry StdSrc.Pattern
---@param lang StdSrc.Language
---@param dir string
local function run_search(entry, lang, dir)
	local fzf = require("fzf-lua")
	local search = entry.re

	local globs = entry.globs or lang.globs
	if globs then
		search = search .. " -- " .. globs
	end

	-- Silent because the previewer cannot convert every regex to a vim pattern
	-- and would report "unable to init vim,regex" (fzf-lua issue 1858).
	fzf.grep({ search = search, no_esc = true, silent = true, cwd = dir })
end

---Show the category menu of a language and grep the chosen one in its source
---directory. The menu keeps the order defined in `languages`, with "Any" first.
---@param lang_name string
local function show_source_menu(lang_name)
	local fzf = require("fzf-lua")
	local lang = languages[lang_name]

	local dir = get_source_dir(lang_name)
	if not dir then
		vim.notify(
			string.format(
				"StdSrc: no source directory found for %s (tried: %s)",
				lang_name,
				table.concat(sources[lang_name] or {}, ", ")
			),
			vim.log.levels.WARN
		)
		return
	end

	local entries = {}
	local labels = { "Any" }
	for _, p in ipairs(lang.patterns) do
		entries[p.label] = p
		table.insert(labels, p.label)
	end

	fzf.fzf_exec(labels, {
		prompt = string.format("Search Source (%s) > ", lang_name),
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
				if entry then
					run_search(entry, lang, dir)
				end
			end,
		},
	})
end

---Pick a declaration category and grep it in the source repository of the
---current language, from wherever the current file lives.
---
---When the language cannot be detected, it asks which one to explore. The menu
---lists "Any", a plain live grep, followed by the language's patterns. Opening a
---result edits the file in the source repository, and `<C-o>` or `<C-^>` goes
---back.
function M.search_source()
	local lang_name = detect_current_language()
	if lang_name then
		show_source_menu(lang_name)
		return
	end

	local names = vim.tbl_keys(sources)
	table.sort(names)
	vim.ui.select(names, { prompt = "Source language > " }, function(choice)
		if choice then
			show_source_menu(choice)
		end
	end)
end

---Register the `:StdSrc` command.
function M.setup()
	-- Wrapped so the command's argument table is not forwarded to the function.
	vim.api.nvim_create_user_command("StdSrc", function()
		M.search_source()
	end, {
		desc = "Fzf: search declarations in the source repository of the current language",
	})
end

return M
