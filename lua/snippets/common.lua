-- lua/snippets/common.lua

-- Language-agnostic LuaSnip snippets: file headers, license headers,
-- function doc comments, marker comments (TODO, FIXME, ...) and small
-- one-line helpers. Every snippet is a dynamic node that reads the current
-- filetype and adapts its comment syntax to it.

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local rep = require("luasnip.extras").rep

local function get_date()
	return os.date("%Y-%m-%d")
end
local function get_year()
	return os.date("%Y")
end

-- The helpers below fall back to "untitled" for unnamed buffers.
local function get_filename()
	local name = vim.fn.expand("%:t")
	return name ~= "" and name or "untitled"
end

-- Path relative to the working directory.
local function get_relpath()
	local path = vim.fn.expand("%:.")
	if path == "" then
		return "untitled"
	end
	return path
end

-- File name without its extension.
local function get_basename()
	local name = vim.fn.expand("%:t:r")
	return name ~= "" and name or "untitled"
end

---Describes how a header or inline comment is written for a filetype.
---A "line" style prefixes every line with `sym`. A "block" style wraps the
---content in `open` and `close`. A "docstring" style (Python only) is a
---list of opening lines followed by a closing delimiter.
---@class CommentStyle
---@field kind "line"|"block"|"docstring"
---@field sym? string Line comment symbol, for "line" styles.
---@field open? string|string[] Opener of a block or docstring style.
---@field close? string Closer of a block or docstring style.
---@field mid? string Prefix of each content line in a block style. Defaults to " * ".
---@field close_indent? string Whitespace before the block closer. Defaults to " ".

local C_BLOCK = { kind = "block", open = "/*", close = "*/" }
local HTML_BLOCK = { kind = "block", open = "<!--", close = "-->" }

-- File header comment style per filetype. Filetypes without a real block
-- comment stay on line comments, and lisp and scheme keep ";;;" because it
-- is the community convention for file metadata. The Lua opener and closer
-- are built by concatenation so this file does not contain a literal
-- long-bracket delimiter.
---@type table<string, CommentStyle>
local comment_styles = {
	lua = { kind = "block", open = "-" .. "-[" .. "[", close = "]" .. "]", mid = "  ", close_indent = "" },
	sh = { kind = "line", sym = "#" },
	bash = { kind = "line", sym = "#" },
	zsh = { kind = "line", sym = "#" },
	yaml = { kind = "line", sym = "#" },
	toml = { kind = "line", sym = "#" },
	vim = { kind = "line", sym = '"' },
	zig = { kind = "line", sym = "//" },
	scheme = { kind = "line", sym = ";;;" },
	lisp = { kind = "line", sym = ";;;" },
	c = C_BLOCK,
	cpp = C_BLOCK,
	cs = C_BLOCK,
	java = C_BLOCK,
	javascript = C_BLOCK,
	typescript = C_BLOCK,
	rust = C_BLOCK,
	go = C_BLOCK,
	php = C_BLOCK,
	sql = C_BLOCK,
	kotlin = C_BLOCK,
	haskell = { kind = "block", open = "{-", close = "-}", mid = "  ", close_indent = "" },
	html = HTML_BLOCK,
	xml = HTML_BLOCK,
	markdown = HTML_BLOCK,
	tex = { kind = "line", sym = "%" },
	latex = { kind = "line", sym = "%" },
	ruby = { kind = "block", open = "=begin", close = "=end", mid = "", close_indent = "" },
	perl = { kind = "line", sym = "#" },
	ps1 = { kind = "block", open = "<#", close = "#>", mid = "  ", close_indent = "" },
	python = {
		kind = "docstring",
		open = { "#!/usr/bin/env python3", "# -*- coding: utf-8 -*-", '"""' },
		close = '"""',
	},
}

---@type CommentStyle
local DEFAULT_STYLE = { kind = "line", sym = "#" }

-- Single-line comment symbol, for inline snippets that must stay on one
-- comment line even when the file header is a block comment.
local line_comment_by_ft = {
	lua = "--",
	sh = "#",
	bash = "#",
	zsh = "#",
	yaml = "#",
	toml = "#",
	vim = '"',
	zig = "//",
	scheme = ";",
	lisp = ";",
	c = "//",
	cpp = "//",
	cs = "//",
	java = "//",
	javascript = "//",
	typescript = "//",
	rust = "//",
	go = "//",
	php = "//",
	sql = "--",
	haskell = "--",
	tex = "%",
	latex = "%",
	python = "#",
	ruby = "#",
	kotlin = "//",
	perl = "#",
	ps1 = "#",
}
local DEFAULT_LINE_COMMENT = "#"

local function line_comment_sym(ft)
	return line_comment_by_ft[ft] or DEFAULT_LINE_COMMENT
end

-- Filetypes whose multi-line inline snippets (refs, drefs) use a block
-- comment. All others use consecutive line comments.
local inline_block_fts = {
	c = true,
	cpp = true,
	cs = true,
	java = true,
	html = true,
	xml = true,
	markdown = true,
}

local shebang_by_ft = {
	sh = "#!/usr/bin/env sh",
	bash = "#!/usr/bin/env bash",
	zsh = "#!/usr/bin/env zsh",
	python = "#!/usr/bin/env python3",
	ruby = "#!/usr/bin/env ruby",
	perl = "#!/usr/bin/env perl",
	php = "#!/usr/bin/env php",
}

local FIELD_WIDTH = 15

-- Pads a field name so header values line up in a column.
local function label(text)
	return text .. string.rep(" ", math.max(1, FIELD_WIDTH - #text))
end

---Applies a comment style to one line of header content. An empty line
---becomes a bare comment prefix with no trailing whitespace.
---@param style CommentStyle
---@param line string
---@return string
local function wrap(style, line)
	if style.kind == "line" then
		if line == "" then
			return style.sym
		end
		return style.sym .. " " .. line
	elseif style.kind == "block" then
		local mid = style.mid or " * "
		if line == "" then
			return (mid:gsub("%s+$", ""))
		end
		return mid .. line
	else
		return line
	end
end

-- Comment prefix for a line that starts with a placeholder, not a label.
local function line_prefix(style)
	if style.kind == "line" then
		return style.sym .. " "
	elseif style.kind == "block" then
		return style.mid or " * "
	else
		return ""
	end
end

-- Compile/run instructions for the `ehead` and `shead` headers. Each entry
-- takes a comment style and returns the nodes for the lines that follow the
-- usage title.
local usage_by_ft = {
	c = function(style)
		return {
			t({ "", wrap(style, "    Compile:") }),
			t({ "", wrap(style, "    $ gcc -Wall -Wextra -Wpedantic -std=c23 ") }),
			f(get_filename, {}),
			t(" -o "),
			f(get_basename, {}),
			t({ "", wrap(style, ""), wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ ./") }),
			f(get_basename, {}),
		}
	end,
	cpp = function(style)
		return {
			t({ "", wrap(style, "    Compile:") }),
			t({ "", wrap(style, "    $ g++ -Wall -Wextra -Wpedantic -std=c++23 ") }),
			f(get_filename, {}),
			t(" -o "),
			f(get_basename, {}),
			t({ "", wrap(style, ""), wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ ./") }),
			f(get_basename, {}),
		}
	end,
	java = function(style)
		return {
			t({ "", wrap(style, label("Compilation:") .. "$ javac ") }),
			f(get_filename, {}),
			t({ "", wrap(style, label("Execution:") .. "$ java ") }),
			f(get_basename, {}),
		}
	end,
	python = function(style)
		return {
			t({ "", wrap(style, "    Run from the directory containing this file.") }),
			t({ "", wrap(style, ""), wrap(style, "    $ python ") }),
			f(get_filename, {}),
		}
	end,
	zig = function(style)
		return {
			t({ "", wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ zig run ") }),
			f(get_filename, {}),
		}
	end,
	scheme = function(style)
		return {
			t({ "", wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ mit-scheme --quiet --load ") }),
			f(get_filename, {}),
			t({ "", wrap(style, ""), wrap(style, "    To evaluate line by line, use ,ee and ,er in the REPL.") }),
		}
	end,
	javascript = function(style)
		return {
			t({ "", wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ node ") }),
			f(get_filename, {}),
		}
	end,
	typescript = function(style)
		return {
			t({ "", wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ npx ts-node ") }),
			f(get_filename, {}),
			t({ "", wrap(style, ""), wrap(style, "    Or compile then run:") }),
			t({ "", wrap(style, "    $ tsc ") }),
			f(get_filename, {}),
			t({ "", wrap(style, "    $ node ") }),
			f(get_basename, {}),
			t(".js"),
		}
	end,
	rust = function(style)
		return {
			t({ "", wrap(style, "    Compile:") }),
			t({ "", wrap(style, "    $ rustc ") }),
			f(get_filename, {}),
			t(" -o "),
			f(get_basename, {}),
			t({ "", wrap(style, ""), wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ ./") }),
			f(get_basename, {}),
		}
	end,
	go = function(style)
		return {
			t({ "", wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ go run ") }),
			f(get_filename, {}),
		}
	end,
	php = function(style)
		return {
			t({ "", wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ php ") }),
			f(get_filename, {}),
		}
	end,
	cs = function(style)
		return {
			t({ "", wrap(style, "    Run (single file, .NET 10+):") }),
			t({ "", wrap(style, "    $ dotnet run ") }),
			f(get_filename, {}),
		}
	end,
	haskell = function(style)
		return {
			t({ "", wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ runghc ") }),
			f(get_filename, {}),
			t({ "", wrap(style, ""), wrap(style, "    Or compile then run:") }),
			t({ "", wrap(style, "    $ ghc -o ") }),
			f(get_basename, {}),
			t(" "),
			f(get_filename, {}),
			t({ "", wrap(style, "    $ ./") }),
			f(get_basename, {}),
		}
	end,
	sh = function(style)
		return {
			t({ "", wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ chmod +x ") }),
			f(get_filename, {}),
			t({ "", wrap(style, "    $ ./") }),
			f(get_filename, {}),
		}
	end,
	ruby = function(style)
		return {
			t({ "", wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ ruby ") }),
			f(get_filename, {}),
		}
	end,
	kotlin = function(style)
		return {
			t({ "", wrap(style, "    Compile:") }),
			t({ "", wrap(style, "    $ kotlinc ") }),
			f(get_filename, {}),
			t(" -include-runtime -d "),
			f(get_basename, {}),
			t(".jar"),
			t({ "", wrap(style, ""), wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ java -jar ") }),
			f(get_basename, {}),
			t(".jar"),
		}
	end,
	perl = function(style)
		return {
			t({ "", wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ perl ") }),
			f(get_filename, {}),
		}
	end,
	ps1 = function(style)
		return {
			t({ "", wrap(style, "    Run:") }),
			t({ "", wrap(style, "    $ pwsh -File ") }),
			f(get_filename, {}),
		}
	end,
}
usage_by_ft.bash = usage_by_ft.sh
usage_by_ft.zsh = usage_by_ft.sh

-- Filetypes whose usage lines carry their own labels, so the "Usage:"
-- title is skipped.
local inline_usage_fts = { java = true }

---Adds a blank line and the usage block to a header. Falls back to a
---placeholder when the filetype has no entry in `usage_by_ft`.
---
---LuaSnip needs contiguous insert indices, so the caller passes the next
---free index and gets back the next one still free. An index is only
---consumed in the fallback case.
---@param add fun(...: table) Appends nodes to the snippet being built.
---@param style CommentStyle
---@param ft string
---@param idx integer Next free insert node index.
---@return integer idx Next free insert node index after this call.
local function add_usage(add, style, ft, idx)
	local usage_fn = usage_by_ft[ft]
	add(t({ "", wrap(style, "") }))
	if usage_fn then
		if not inline_usage_fts[ft] then
			add(t({ "", wrap(style, label("Usage:")) }))
		end
		for _, n in ipairs(usage_fn(style)) do
			add(n)
		end
		return idx
	end
	add(t({ "", wrap(style, label("Usage:")) }))
	add(t({ "", wrap(style, "    ") }))
	add(i(idx, "how to compile/run this file"))
	return idx + 1
end

-- Doc comments for `fnhead`, in each language's idiomatic format. These
-- build their own delimiters because the doc format dictates the syntax.
local doc_by_ft = {}

doc_by_ft.javascript = function()
	return {
		t({ "/**", " * " }),
		i(1, "Short description."),
		t({ "", " *", " * @param {" }),
		i(2, "type"),
		t("} "),
		i(3, "name"),
		t(" - "),
		i(4, "description"),
		t({ "", " * @returns {" }),
		i(5, "type"),
		t("} "),
		i(6, "description"),
		t({ "", " */" }),
	}
end
doc_by_ft.typescript = doc_by_ft.javascript

doc_by_ft.python = function()
	return {
		t('"""'),
		i(1, "Short description."),
		t({ "", "", "Args:" }),
		t({ "", "    " }),
		i(2, "name"),
		t(" ("),
		i(3, "type"),
		t("): "),
		i(4, "description."),
		t({ "", "", "Returns:" }),
		t({ "", "    " }),
		i(5, "type"),
		t(": "),
		i(6, "description."),
		t({ "", '"""' }),
	}
end

doc_by_ft.java = function()
	return {
		t({ "/**", " * " }),
		i(1, "Short description."),
		t({ "", " *", " * @param " }),
		i(2, "name"),
		t(" "),
		i(3, "description"),
		t({ "", " * @return " }),
		i(4, "description"),
		t({ "", " */" }),
	}
end
doc_by_ft.kotlin = doc_by_ft.java

doc_by_ft.c = function()
	return {
		t({ "/**", " * @brief " }),
		i(1, "Short description."),
		t({ "", " *", " * @param " }),
		i(2, "name"),
		t(" "),
		i(3, "description"),
		t({ "", " * @return " }),
		i(4, "description"),
		t({ "", " */" }),
	}
end
doc_by_ft.cpp = doc_by_ft.c

doc_by_ft.go = function()
	return {
		t("// "),
		i(1, "FuncName"),
		t(" "),
		i(2, "does X."),
		t({ "", "//", "// Parameters:" }),
		t({ "", "//   - " }),
		i(3, "name"),
		t(": "),
		i(4, "description"),
		t({ "", "//", "// Returns " }),
		i(5, "description."),
	}
end

doc_by_ft.rust = function()
	return {
		t("/// "),
		i(1, "Short description."),
		t({ "", "///", "/// # Arguments", "///", "/// * `" }),
		i(2, "name"),
		t("` - "),
		i(3, "description"),
		t({ "", "///", "/// # Returns", "///", "/// " }),
		i(4, "description"),
	}
end

doc_by_ft.php = function()
	return {
		t({ "/**", " * " }),
		i(1, "Short description."),
		t({ "", " *", " * @param " }),
		i(2, "type"),
		t(" $"),
		i(3, "name"),
		t(" "),
		i(4, "description"),
		t({ "", " * @return " }),
		i(5, "type"),
		t(" "),
		i(6, "description"),
		t({ "", " */" }),
	}
end

doc_by_ft.cs = function()
	return {
		t({ "/// <summary>", "/// " }),
		i(1, "Short description."),
		t({ "", "/// </summary>", '/// <param name="' }),
		i(2, "name"),
		t('">'),
		i(3, "description"),
		t("</param>"),
		t({ "", "/// <returns>" }),
		i(4, "description"),
		t("</returns>"),
	}
end

doc_by_ft.ruby = function()
	return {
		t("# "),
		i(1, "Short description."),
		t({ "", "#", "# @param " }),
		i(2, "name"),
		t(" ["),
		i(3, "Type"),
		t("] "),
		i(4, "description"),
		t({ "", "# @return [" }),
		i(5, "Type"),
		t("] "),
		i(6, "description"),
	}
end

-- `fnhead`: doc comment in the idiomatic format of the current filetype.
-- Falls back to a one-line comment for filetypes without a doc format.
local function build_fnhead(_, _)
	local doc = doc_by_ft[vim.bo.filetype]
	if doc then
		local nodes = doc()
		table.insert(nodes, i(0))
		return sn(nil, nodes)
	end
	return sn(nil, {
		t(line_comment_sym(vim.bo.filetype) .. " "),
		i(1, "Short description."),
		i(0),
	})
end

-- Block and docstring styles need a line break after the opener.
local function open_and_first_line(add, style, first_line)
	if style.kind == "block" or style.kind == "docstring" then
		add(t(style.open))
		add(t({ "", wrap(style, first_line) }))
	else
		add(t(wrap(style, first_line)))
	end
end

-- Closes the header and adds a blank line before the code.
local function close_header(add, style)
	if style.kind == "block" then
		local indent = style.close_indent or " "
		add(t({ "", indent .. style.close, "", "" }))
	elseif style.kind == "docstring" then
		add(t({ "", style.close, "", "" }))
	else
		add(t({ "", "" }))
	end
end

-- The `build_*` functions below are dynamic node functions: LuaSnip passes
-- two arguments, which they ignore, and each returns a snippet node. Every
-- one defines a local `add` that appends nodes to its own list.

-- `head`: File, Author, Created, Modified, Description. No license.
local function build_head(_, _)
	local ft = vim.bo.filetype
	local style = comment_styles[ft] or DEFAULT_STYLE
	local nodes = {}
	local function add(...)
		for _, n in ipairs({ ... }) do
			table.insert(nodes, n)
		end
	end

	open_and_first_line(add, style, label("File:"))
	add(f(get_filename, {}))
	add(t({ "", wrap(style, label("Author:")) }))
	add(i(1, "Miquéias Alves Medeiros <https://github.com/miqu3iasg>"))
	add(t({ "", wrap(style, label("Created:")) }))
	add(f(get_date, {}))
	add(t({ "", wrap(style, label("Modified:")) }))
	add(f(get_date, {}))
	add(t({ "", wrap(style, ""), line_prefix(style) }))
	add(i(2, "add description here"))
	close_header(add, style)
	add(i(0))

	return sn(nil, nodes)
end

-- `shead`: for code written while studying a book or article. Includes the
-- compile/run commands from `usage_by_ft`. The license is fixed to
-- AGPL-3.0-only.
local function build_study(_, _)
	local ft = vim.bo.filetype
	local style = comment_styles[ft] or DEFAULT_STYLE
	local nodes = {}
	local function add(...)
		for _, n in ipairs({ ... }) do
			table.insert(nodes, n)
		end
	end

	open_and_first_line(add, style, label("File:"))
	add(f(get_filename, {}))
	add(t({ "", wrap(style, label("Author:")) }))
	add(i(1, "Miquéias Alves Medeiros <https://github.com/miqu3iasg>"))
	add(t({ "", wrap(style, label("Created:")) }))
	add(f(get_date, {}))
	add(t({ "", wrap(style, label("Modified:")) }))
	add(f(get_date, {}))
	add(t({ "", wrap(style, label("Source:")) }))
	add(i(2, "title of the book/article"))
	add(t({ "", wrap(style, label("By:")) }))
	add(i(3, "actual author(s) of the source material"))
	add(t({ "", wrap(style, label("Location:")) }))
	add(i(4, "chapter / pages / section"))
	local idx = add_usage(add, style, ft, 5)
	add(t({ "", wrap(style, ""), line_prefix(style) }))
	add(i(idx, "what you implemented / learned here"))
	add(t({ "", wrap(style, ""), wrap(style, "SPDX-License-Identifier: AGPL-3.0-only") }))
	add(t({ "", wrap(style, label("Copyright:")) }))
	add(t("(c) "))
	add(f(get_year, {}))
	add(t(" "))
	add(rep(1))
	add(t("."))
	close_header(add, style)
	add(i(0))

	return sn(nil, nodes)
end

-- Trigger prefix -> SPDX identifier, for the `<prefix>head` snippets.
local licenses = {
	agpl = "AGPL-3.0-only",
	gpl3 = "GPL-3.0-only",
	mit = "MIT",
	apache2 = "Apache-2.0",
	bsd3 = "BSD-3-Clause",
	isc = "ISC",
	mpl2 = "MPL-2.0",
}

---Returns a dynamic node function for a `<prefix>head` snippet: the same
---fields as `head`, plus an SPDX line and a copyright notice.
---@param spdx string SPDX license identifier.
---@return fun(args: table, parent: table): table
local function build_licensed_head(spdx)
	return function(_, _)
		local ft = vim.bo.filetype
		local style = comment_styles[ft] or DEFAULT_STYLE
		local nodes = {}
		local function add(...)
			for _, n in ipairs({ ... }) do
				table.insert(nodes, n)
			end
		end

		open_and_first_line(add, style, label("File:"))
		add(f(get_filename, {}))
		add(t({ "", wrap(style, label("Author:")) }))
		add(i(1, "Miquéias Alves Medeiros <https://github.com/miqu3iasg>"))
		add(t({ "", wrap(style, label("Created:")) }))
		add(f(get_date, {}))
		add(t({ "", wrap(style, label("Modified:")) }))
		add(f(get_date, {}))
		add(t({ "", wrap(style, ""), line_prefix(style) }))
		add(i(2, "add description here"))
		add(t({ "", wrap(style, ""), wrap(style, "SPDX-License-Identifier: " .. spdx) }))
		add(t({ "", wrap(style, label("Copyright:")) }))
		add(t("(c) "))
		add(f(get_year, {}))
		add(t(" "))
		add(rep(1))
		add(t("."))
		close_header(add, style)
		add(i(0))

		return sn(nil, nodes)
	end
end

-- `ahead`: proprietary header with an "All rights reserved." notice.
local function build_allhead(_, _)
	local ft = vim.bo.filetype
	local style = comment_styles[ft] or DEFAULT_STYLE
	local nodes = {}
	local function add(...)
		for _, n in ipairs({ ... }) do
			table.insert(nodes, n)
		end
	end

	open_and_first_line(add, style, label("File:"))
	add(f(get_filename, {}))
	add(t({ "", wrap(style, label("Author:")) }))
	add(i(1, "Miquéias Alves Medeiros <https://github.com/miqu3iasg>"))
	add(t({ "", wrap(style, label("Created:")) }))
	add(f(get_date, {}))
	add(t({ "", wrap(style, label("Modified:")) }))
	add(f(get_date, {}))
	add(t({ "", wrap(style, ""), line_prefix(style) }))
	add(i(2, "add description here"))
	add(t({ "", wrap(style, ""), wrap(style, label("Copyright:")) }))
	add(t("(c) "))
	add(f(get_year, {}))
	add(t(" "))
	add(rep(1))
	add(t(". All rights reserved."))
	close_header(add, style)
	add(i(0))

	return sn(nil, nodes)
end

-- `ehead`: exercise header. `shead` fields plus a problem statement and a
-- reference list, with compile/run commands from `usage_by_ft`.
local function build_exs(_, _)
	local ft = vim.bo.filetype
	local style = comment_styles[ft] or DEFAULT_STYLE
	local nodes = {}
	local function add(...)
		for _, n in ipairs({ ... }) do
			table.insert(nodes, n)
		end
	end

	open_and_first_line(add, style, label("File:"))
	add(f(get_filename, {}))
	add(t({ "", wrap(style, label("Author:")) }))
	add(i(1, "Miquéias Medeiros <https://github.com/miqu3iasg>"))
	add(t({ "", wrap(style, label("Created:")) }))
	add(f(get_date, {}))
	add(t({ "", wrap(style, label("Modified:")) }))
	add(f(get_date, {}))
	add(t({ "", wrap(style, label("Source:")) }))
	add(i(2, "title of the book/article"))
	add(t({ "", wrap(style, label("By:")) }))
	add(i(3, "actual author(s) of the source material"))
	add(t({ "", wrap(style, label("Location:")) }))
	add(i(4, "chapter / pages / section"))
	local idx = add_usage(add, style, ft, 5)
	add(t({ "", wrap(style, ""), wrap(style, "Problem Statement:") }))
	add(t({ "", wrap(style, "    ") }))
	add(i(idx, "Paste the exercise/assignment text here."))
	add(t({ "", wrap(style, ""), line_prefix(style) }))
	add(i(idx + 1, "Longer description, if needed."))
	add(t({ "", wrap(style, ""), wrap(style, "References:") }))
	add(t({ "", wrap(style, "  - ") }))
	add(i(idx + 2, "https://..."))
	add(t({ "", wrap(style, ""), wrap(style, "SPDX-License-Identifier: AGPL-3.0-only") }))
	add(t({ "", wrap(style, label("Copyright:")) }))
	add(t("(c) "))
	add(f(get_year, {}))
	add(t(" "))
	add(rep(1))
	add(t("."))
	close_header(add, style)
	add(i(0))

	return sn(nil, nodes)
end

---Returns the style for multi-line inline snippets: the block style for
---filetypes in `inline_block_fts`, line comments for all others.
---@param ft string
---@return CommentStyle
local function inline_style(ft)
	local raw = comment_styles[ft]
	if raw and raw.kind == "block" and inline_block_fts[ft] then
		return raw
	end
	return { kind = "line", sym = line_comment_sym(ft) }
end

local function open_inline(add, style)
	if style.kind == "block" then
		add(t(style.open))
		add(t({ "", line_prefix(style) }))
	else
		add(t(line_prefix(style)))
	end
end

local function close_inline(add, style)
	if style.kind == "block" then
		add(t({ "", (style.close_indent or " ") .. style.close }))
	end
end

---Returns the opener and closer for a one-line comment. Languages with
---only a block form (html, xml, markdown) get `<!-- ... -->`. The closer
---is empty for line comments.
---@param ft string
---@return string opener
---@return string closer
local function oneline_delims(ft)
	local sym = line_comment_by_ft[ft]
	if sym then
		return sym .. " ", ""
	end
	local raw = comment_styles[ft]
	if raw and raw.kind == "block" then
		return raw.open .. " ", " " .. raw.close
	end
	return DEFAULT_LINE_COMMENT .. " ", ""
end

---Returns a dynamic node function for a bare marker comment such as
---`// TODO: `, with the cursor after the colon.
---@param text string Marker keyword, for example "TODO".
---@return fun(args: table, parent: table): table
local function build_marker(text)
	return function(_, _)
		local pre, post = oneline_delims(vim.bo.filetype)
		local nodes = { t(pre .. text .. ": "), i(1) }
		if post ~= "" then
			table.insert(nodes, t(post))
		end
		table.insert(nodes, i(0))
		return sn(nil, nodes)
	end
end

-- `spdx`: standalone SPDX line, without a full header.
local function build_spdx(_, _)
	local pre, post = oneline_delims(vim.bo.filetype)
	return sn(nil, {
		t(pre .. "SPDX-License-Identifier: "),
		i(1, "AGPL-3.0-only"),
		t(post),
		i(0),
	})
end

-- `chead`: smallest header (File, Created, Description) for scratch files.
local function build_scratch(_, _)
	local ft = vim.bo.filetype
	local style = comment_styles[ft] or DEFAULT_STYLE
	local nodes = {}
	local function add(...)
		for _, n in ipairs({ ... }) do
			table.insert(nodes, n)
		end
	end

	open_and_first_line(add, style, label("File:"))
	add(f(get_filename, {}))
	add(t({ "", wrap(style, label("Created:")) }))
	add(f(get_date, {}))
	add(t({ "", wrap(style, ""), line_prefix(style) }))
	add(i(1, "quick scratch / throwaway notes"))
	close_header(add, style)
	add(i(0))

	return sn(nil, nodes)
end

-- `shebang`: interpreter line for the current filetype, `sh` by default.
local function build_shebang(_, _)
	local ft = vim.bo.filetype
	local line = shebang_by_ft[ft] or "#!/usr/bin/env sh"
	return sn(nil, { t(line), i(0) })
end

-- `see`: one-line reference, cursor ready to paste the link.
local function build_see(_, _)
	local sym = line_comment_sym(vim.bo.filetype)
	return sn(nil, {
		t(sym .. " See: "),
		i(1),
	})
end

-- `file`: one-line comment with the file path relative to the cwd,
-- e.g. `-- lua/options.lua`.
local function build_filepath(_, _)
	local pre, post = oneline_delims(vim.bo.filetype)
	local nodes = { t(pre), f(get_relpath, {}) }
	if post ~= "" then
		table.insert(nodes, t(post))
	end
	table.insert(nodes, i(0))
	return sn(nil, nodes)
end

local function build_mail(_, _)
	return sn(nil, { i(1, "contatomiqueiasalvesdev@gmail.com") })
end

local function build_gh(_, _)
	return sn(nil, { i(1, "https://github.com/miqu3iasg") })
end

-- `refs`: list of references, one bullet per source.
local function build_refs(_, _)
	local style = inline_style(vim.bo.filetype)
	local nodes = {}
	local function add(...)
		for _, n in ipairs({ ... }) do
			table.insert(nodes, n)
		end
	end

	open_inline(add, style)
	add(t("References:"))
	add(t({ "", wrap(style, "  - ") }))
	add(i(1, "https://..."))
	close_inline(add, style)
	add(i(0))

	return sn(nil, nodes)
end

-- `drefs`: description plus references, for borrowed code where the reason
-- it was kept matters.
local function build_snip(_, _)
	local style = inline_style(vim.bo.filetype)
	local nodes = {}
	local function add(...)
		for _, n in ipairs({ ... }) do
			table.insert(nodes, n)
		end
	end

	open_inline(add, style)
	add(i(1, "what this snippet does / why it was kept"))
	add(t({ "", wrap(style, "References:") }))
	add(t({ "", wrap(style, "  - ") }))
	add(i(2, "https://..."))
	close_inline(add, style)
	add(i(0))

	return sn(nil, nodes)
end

local snippets = {
	s("head", { d(1, build_head, {}) }),
	s("shead", { d(1, build_study, {}) }),
	s("ahead", { d(1, build_allhead, {}) }),
	s("chead", { d(1, build_scratch, {}) }),
	s("ehead", { d(1, build_exs, {}) }),
	s("fnhead", { d(1, build_fnhead, {}) }),
	s("shebang", { d(1, build_shebang, {}) }),
	s("see", { d(1, build_see, {}) }),
	s("file", { d(1, build_filepath, {}) }),
	s("refs", { d(1, build_refs, {}) }),
	s("drefs", { d(1, build_snip, {}) }),
	s("spdx", { d(1, build_spdx, {}) }),
	s("mail", { d(1, build_mail, {}) }),
	s("gh", { d(1, build_gh, {}) }),
	s("author", { i(1, "Miquéias Alves Medeiros <https://github.com/miqu3iasg>") }),
}

-- Trigger -> keyword for the marker comment snippets.
local markers = {
	todo = "TODO",
	fixme = "FIXME",
	note = "NOTE",
	hack = "HACK",
	xxx = "XXX",
	bug = "BUG",
	warn = "WARNING",
	perf = "PERF",
	depr = "DEPRECATED",
}

for trigger, text in pairs(markers) do
	table.insert(snippets, s(trigger, { d(1, build_marker(text), {}) }))
end

for key, spdx in pairs(licenses) do
	table.insert(snippets, s(key .. "head", { d(1, build_licensed_head(spdx), {}) }))
end

return snippets
