-- lua/infra/declarations.lua

-- Declaration search for the current language, built on fzf-lua and ripgrep.
--
-- Provides language-aware declaration and pending-comment searches using
-- fzf-lua and ripgrep. Supported languages, declaration patterns and file
-- filters are defined in the `languages` table below.
--
-- `M.search()` detects the current language or the language represented in
-- an Oil directory view, then presents the available search categories.
-- `M.search_pending_comments()` searches for TODO, FIXME, HACK, BUG and XXX
-- markers in the current directory.
--
-- `M.setup()` registers the `:Declarations` and `:Todo` commands.
-- The module can also be used directly:
--
-- Usage:
--   local declarations = require("infra.declarations")
--   declarations.setup()
--   vim.keymap.set("n", "<leader>fs", declarations.search)
--   vim.keymap.set("n", "<leader>fe", declarations.search_pending_comments)

local M = {}

-- Languages

-- Java fragments shared by several patterns
local JAVA_TYPE_MODS = [=[(?:(?:abstract|final|sealed|non-sealed|static|strictfp)\s+)*]=]
local JAVA_TYPE_REF = [=[[\w.<>\[\],? ]+]=]
local JAVA_PUBLIC_TYPE = [=[^\s*public\s+]=] .. JAVA_TYPE_MODS

-- Per-language regexes (ripgrep syntax) used to find declarations.
-- Each language has a `curbuf` flag (search only the current buffer), a default
-- `globs` string applied to every pattern, and an ordered `patterns` list whose
-- order is the order of the menu. A pattern may set its own `globs` to override
-- the language default.
local languages = {
	C = {
		curbuf = false,
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
		curbuf = false,
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
		curbuf = true,
		globs = "*.py !*test*",
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
		curbuf = true,
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

-- Detection

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

-- Search

-- Returns the directory to search: the one oil is showing, otherwise the nvim cwd
local function get_search_dir(in_oil)
	if in_oil then
		local ok, oil = pcall(require, "oil")
		local oil_dir = ok and oil.get_current_dir() or nil
		if oil_dir then
			return oil_dir
		end
	end
	return vim.uv.cwd()
end

-- Runs the grep for one menu entry, either on the current buffer or on the
-- files of `dir` filtered by the entry's globs (or the language default)
local function run_search(entry, lang, dir, use_curbuf)
	local fzf = require("fzf-lua")
	local search = entry.re
	local operation = fzf.grep

	if use_curbuf then
		operation = fzf.grep_curbuf
	else
		local globs = entry.globs or lang.globs
		if globs then
			search = search .. " -- " .. globs
		end
	end

	-- silent, the previewer cannot convert every regex to a vim pattern and would
	-- otherwise report "unable to init vim,regex" (fzf-lua issue 1858)
	operation({ search = search, no_esc = true, silent = true, cwd = dir })
end

-- Searches for pending comments in the current directory.
function M.search_pending_comments()
	local fzf = require("fzf-lua")

	fzf.grep({
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

-- Picks a category for the current language and greps it. Falls back to live_grep
function M.search()
	local fzf = require("fzf-lua")
	local path = vim.api.nvim_buf_get_name(0)
	local in_oil = vim.startswith(path, "oil://")
	local dir = get_search_dir(in_oil)

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
				if entry then
					run_search(entry, lang, dir, use_curbuf)
				end
			end,
		},
	})
end

-- Registers the :Declarations command
function M.setup()
	vim.api.nvim_create_user_command("Declarations", M.search, {
		desc = "Fzf: search declarations (functions/types/imports) of the current language",
	})

	vim.api.nvim_create_user_command("Todo", M.search_pending_comments, {
		desc = "Fzf: search TODO/FIXME/HACK/BUG/XXX in the current directory",
	})
end

return M
