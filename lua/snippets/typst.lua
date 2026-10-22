-- lua/snippets/typst.lua

local ls = require("luasnip")

local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local c = ls.choice_node
local fmta = require("luasnip.extras.fmt").fmta

-- Returns true or false based on the syntax tree, or nil when the parser is
-- not available so that the caller can fall back to a plain text heuristic
local function ts_in_math()
	local ok, result = pcall(function()
		local parser = vim.treesitter.get_parser(0, "typst")
		parser:parse(true)
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		row = row - 1
		local node = vim.treesitter.get_node({ bufnr = 0, pos = { row, math.max(col - 1, 0) } })
		while node do
			if node:type() == "formula" then
				local sr, sc, er, ec = node:range()
				local after_start = row > sr or (row == sr and col > sc)
				local before_end = row < er or (row == er and col < ec)
				return after_start and before_end
			end
			node = node:parent()
		end
		return false
	end)
	if ok then
		return result
	end
	return nil
end

-- An odd number of unescaped `$` before the cursor means we are in math. This
-- misses multi-line display math, which is why treesitter is preferred
local function count_in_math()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local before = (vim.api.nvim_get_current_line():sub(1, col):gsub("\\%$", ""))
	local n = select(2, before:gsub("%$", ""))
	return n % 2 == 1
end

local function in_math()
	local r = ts_in_math()
	if r ~= nil then
		return r
	end
	return count_in_math()
end

local function in_markup()
	return not in_math()
end

-- Autosnippet that only expands inside math. With `word` unset it also fires
-- in the middle of a word, which is what lets `xtd` become `x^()`
local function auto_math(trig, nodes, word)
	return s({
		trig = trig,
		snippetType = "autosnippet",
		wordTrig = word or false,
		condition = in_math,
		show_condition = in_math,
	}, nodes)
end

-- Regular snippet that only expands inside math
local function math_snip(trig, nodes)
	return s({ trig = trig, condition = in_math, show_condition = in_math }, nodes)
end

-- Typst headings: h1 -> "= ", h2 -> "== ", and so on
local function heading(level)
	return s("h" .. level, {
		t(string.rep("=", level) .. " "),
		i(1, "Title"),
		i(0),
	})
end

local function codeblock(trig, lang)
	return s(trig, {
		t("```" .. lang),
		t({ "", "" }),
		i(1),
		t({ "", "```" }),
		i(0),
	})
end

-- ctheorems environment such as #theorem("Name")[...], with an optional name
local function thmenv(trig, env)
	return s(trig, {
		t("#" .. env),
		c(1, {
			sn(nil, { t('("'), i(1, "Name"), t('")') }),
			t(""),
		}),
		t({ "[", "  " }),
		i(2),
		t({ "", "]" }),
		i(0),
	})
end

-- `tbl3x2` expands to a table with 3 columns and 2 body rows
local function dynamic_table(_, snip)
	local cols = tonumber(snip.captures[1])
	local rows = tonumber(snip.captures[2])
	local nodes = { t({ "#table(", "  columns: " .. cols .. ",", "  table.header(" }) }
	local idx = 1

	local function cells(placeholder)
		for col = 1, cols do
			nodes[#nodes + 1] = t("[")
			nodes[#nodes + 1] = i(idx, placeholder .. " " .. col)
			idx = idx + 1
			nodes[#nodes + 1] = t(col < cols and "], " or "]")
		end
	end

	cells("Header")
	nodes[#nodes + 1] = t({ "),", "  " })
	for r = 1, rows do
		cells("Cell")
		nodes[#nodes + 1] = t(r < rows and { ",", "  " } or ",")
	end
	nodes[#nodes + 1] = t({ "", ")" })
	return sn(nil, nodes)
end

-- `mat3x2` expands to a matrix with 3 rows and 2 columns
local function dynamic_matrix(_, snip)
	local rows = tonumber(snip.captures[1])
	local cols = tonumber(snip.captures[2])
	local nodes = { t({ "mat(", "  " }) }
	local idx = 1
	for r = 1, rows do
		for col = 1, cols do
			nodes[#nodes + 1] = i(idx, "a_" .. r .. col)
			idx = idx + 1
			if col < cols then
				nodes[#nodes + 1] = t(", ")
			end
		end
		if r < rows then
			nodes[#nodes + 1] = t({ ";", "  " })
		end
	end
	nodes[#nodes + 1] = t({ "", ")" })
	return sn(nil, nodes)
end

-- `vec3` expands to a column vector with 3 components
local function dynamic_vector(_, snip)
	local n = tonumber(snip.captures[1])
	local nodes = { t("vec(") }
	for k = 1, n do
		nodes[#nodes + 1] = i(k, "a_" .. k)
		if k < n then
			nodes[#nodes + 1] = t(", ")
		end
	end
	nodes[#nodes + 1] = t(")")
	return sn(nil, nodes)
end

-- Greek letters typed as `;` plus a key, only inside math
local greek = {
	{ "a", "alpha" },
	{ "b", "beta" },
	{ "g", "gamma" },
	{ "d", "delta" },
	{ "e", "epsilon" },
	{ "ve", "epsilon.alt" },
	{ "z", "zeta" },
	{ "h", "eta" },
	{ "t", "theta" },
	{ "vt", "theta.alt" },
	{ "i", "iota" },
	{ "k", "kappa" },
	{ "l", "lambda" },
	{ "m", "mu" },
	{ "n", "nu" },
	{ "x", "xi" },
	{ "p", "pi" },
	{ "r", "rho" },
	{ "s", "sigma" },
	{ "f", "phi" },
	{ "vf", "phi.alt" },
	{ "c", "chi" },
	{ "y", "psi" },
	{ "w", "omega" },
	{ "D", "Delta" },
	{ "G", "Gamma" },
	{ "T", "Theta" },
	{ "L", "Lambda" },
	{ "X", "Xi" },
	{ "P", "Pi" },
	{ "S", "Sigma" },
	{ "F", "Phi" },
	{ "Y", "Psi" },
	{ "W", "Omega" },
}

local snippets = {

	-- Document setup

	s(
		"doc",
		fmta(
			[=[
#set document(title: "<>", author: "<>")
#set page(paper: "a4", margin: (x: 2.5cm, y: 2.5cm), numbering: "1")
#set text(font: "<>", size: <>pt, <>)
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1")
#set math.equation(numbering: "(1)")

<>
]=],
			{
				i(1, "Title"),
				i(2, "Author"),
				i(3, "New Computer Modern"),
				i(4, "11"),
				c(5, { t('lang: "en"'), t('lang: "pt", region: "br"') }),
				i(0),
			}
		)
	),

	s(
		"title",
		fmta(
			[=[
#align(center)[
  #text(size: 20pt, weight: "bold")[<>] \
  #v(0.5em)
  <> \
  #datetime.today().display("[day]/[month]/[year]")
]
<>]=],
			{ i(1, "Title"), i(2, "Author"), i(0) }
		)
	),

	s(
		"page",
		fmta(
			'#set page(paper: "<>", margin: <>, numbering: "<>")<>',
			{ c(1, { t("a4"), t("us-letter"), t("a5") }), i(2, "2.5cm"), i(3, "1"), i(0) }
		)
	),

	s(
		"text",
		fmta(
			'#set text(font: "<>", size: <>pt, lang: "<>")<>',
			{ i(1, "New Computer Modern"), i(2, "11"), c(3, { t("en"), t("pt") }), i(0) }
		)
	),

	s(
		"par",
		fmta("#set par(justify: true, leading: <>em, first-line-indent: <>)<>", { i(1, "0.65"), i(2, "1.8em"), i(0) })
	),

	s("headnum", { t('#set heading(numbering: "'), i(1, "1.1"), t('")'), i(0) }),
	s("eqnum", { t('#set math.equation(numbering: "'), i(1, "(1)"), t('")'), i(0) }),

	-- Rules, bindings and imports

	s("set", { t("#set "), i(1, "text"), t("("), i(2), t(")"), i(0) }),

	s("show", {
		t("#show "),
		i(1, "heading"),
		t(": it => "),
		i(2, "it"),
		i(0),
	}),

	s("shows", {
		t("#show "),
		i(1, "heading"),
		t(": set "),
		i(2, "text"),
		t("("),
		i(3, "fill: blue"),
		t(")"),
		i(0),
	}),

	s("showb", {
		t("#show "),
		i(1, "heading"),
		t({ ": it => {", "  " }),
		i(2, "it"),
		t({ "", "}" }),
		i(0),
	}),

	s("let", { t("#let "), i(1, "name"), t(" = "), i(2, "value"), i(0) }),

	s("letf", {
		t("#let "),
		i(1, "name"),
		t("("),
		i(2, "args"),
		t({ ") = {", "  " }),
		i(3),
		t({ "", "}" }),
		i(0),
	}),

	s("imp", {
		t('#import "@preview/'),
		i(1, "package"),
		t(":"),
		i(2, "0.1.0"),
		t('": '),
		i(3, "*"),
		i(0),
	}),

	s("impl", { t('#import "'), i(1, "file.typ"), t('": '), i(2, "*"), i(0) }),
	s("inc", { t('#include "'), i(1, "file.typ"), t('"'), i(0) }),

	-- Package versions are placeholders, check typst.app/universe for current ones
	s("cetz", {
		t('#import "@preview/cetz:'),
		i(1, "0.4.2"),
		t({ '": canvas, draw', "", "#canvas({", "  import draw: *", "  " }),
		i(2),
		t({ "", "})" }),
		i(0),
	}),

	s(
		"thmsetup",
		fmta(
			[=[
#import "@preview/ctheorems:<>": *
#show: thmrules.with(qed-symbol: $square$)

#let theorem = thmbox("theorem", "Theorem", fill: rgb("#e8f5e9"))
#let lemma = thmbox("lemma", "Lemma", base: "theorem", fill: rgb("#e8f5e9"))
#let corollary = thmbox("corollary", "Corollary", base: "theorem", fill: rgb("#e8f5e9"))
#let proposition = thmbox("proposition", "Proposition", base: "theorem", fill: rgb("#e8f5e9"))
#let definition = thmbox("definition", "Definition", fill: rgb("#e3f2fd"))
#let example = thmplain("example", "Example").with(numbering: none)
#let proof = thmproof("proof", "Proof")
<>]=],
			{ i(1, "1.1.3"), i(0) }
		)
	),

	thmenv("thm", "theorem"),
	thmenv("lem", "lemma"),
	thmenv("cor", "corollary"),
	thmenv("prop", "proposition"),
	thmenv("def", "definition"),
	thmenv("ex", "example"),
	thmenv("prf", "proof"),

	-- Structure and spacing

	s("toc", { t('#outline(title: "'), i(1, "Contents"), t('", indent: auto)'), i(0) }),

	s("bib", {
		t('#bibliography("'),
		i(1, "refs.bib"),
		t('", title: "'),
		i(2, "References"),
		t('", style: "'),
		c(3, { t("ieee"), t("apa"), t("chicago-author-date"), t("mla"), t("vancouver") }),
		t('")'),
		i(0),
	}),

	s("pb", { t("#pagebreak()"), i(0) }),
	s("vs", { t("#v("), i(1, "1em"), t(")"), i(0) }),
	s("hs", { t("#h("), i(1, "1em"), t(")"), i(0) }),
	s("hf", { t("#h(1fr)"), i(0) }),

	-- Text formatting

	s("bd", { t("*"), i(1, "text"), t("*"), i(0) }),
	s("it", { t("_"), i(1, "text"), t("_"), i(0) }),
	s("bi", { t("*_"), i(1, "text"), t("_*"), i(0) }),
	s("und", { t("#underline["), i(1, "text"), t("]"), i(0) }),
	s("hl", { t("#highlight["), i(1, "text"), t("]"), i(0) }),
	s("str", { t("#strike["), i(1, "text"), t("]"), i(0) }),
	s("sc", { t("#smallcaps["), i(1, "text"), t("]"), i(0) }),
	s("sup", { t("#super["), i(1, "text"), t("]"), i(0) }),
	s("sbs", { t("#sub["), i(1, "text"), t("]"), i(0) }),
	s("col", { t("#text(fill: "), i(1, "red"), t(")["), i(2, "text"), t("]"), i(0) }),
	s("sz", { t("#text(size: "), i(1, "14pt"), t(")["), i(2, "text"), t("]"), i(0) }),
	s("ic", { t("`"), i(1, "code"), t("`"), i(0) }),
	s("todo", { t("#text(fill: red)[*TODO:* "), i(1, "description"), t("]"), i(0) }),

	s("quote", {
		t("#quote(block: true, attribution: ["),
		i(1, "Author"),
		t({ "])[", "  " }),
		i(2, "Quote"),
		t({ "", "]" }),
		i(0),
	}),

	-- Links and references

	s("link", { t('#link("'), i(1, "https://"), t('")['), i(2, "text"), t("]"), i(0) }),
	s("url", { t('#link("'), i(1, "https://"), t('")'), i(0) }),
	s("lbl", { t("<"), i(1, "label"), t(">"), i(0) }),
	s("ref", { t("@"), i(1, "label"), i(0) }),
	s("cite", { t("#cite(<"), i(1, "key"), t(">)"), i(0) }),
	s("fn", { t("#footnote["), i(1, "Note."), t("]"), i(0) }),

	-- Lists

	s("ul", {
		t("- "),
		i(1, "Item"),
		t({ "", "  - " }),
		i(2, "Subitem"),
		t({ "", "- " }),
		i(3, "Item"),
		i(0),
	}),

	s("ol", {
		t("+ "),
		i(1, "Item"),
		t({ "", "+ " }),
		i(2, "Item"),
		t({ "", "+ " }),
		i(3, "Item"),
		i(0),
	}),

	s("term", {
		t("/ "),
		i(1, "Term"),
		t(": "),
		i(2, "Description"),
		t({ "", "/ " }),
		i(3, "Term"),
		t(": "),
		i(4, "Description"),
		i(0),
	}),

	-- Code blocks and comments

	s("cb", {
		t("```"),
		i(1, "lang"),
		t({ "", "" }),
		i(2),
		t({ "", "```" }),
		i(0),
	}),

	codeblock("cbpy", "python"),
	codeblock("cbc", "c"),
	codeblock("cbjava", "java"),
	codeblock("cblua", "lua"),
	codeblock("cbbash", "bash"),
	codeblock("cbsh", "sh"),
	codeblock("cbsql", "sql"),
	codeblock("cbjson", "json"),
	codeblock("cbyaml", "yaml"),
	codeblock("cbrs", "rust"),
	codeblock("cbgo", "go"),
	codeblock("cbts", "typescript"),

	s("cm", { t("// "), i(1, "comment"), i(0) }),
	s("cmm", { t({ "/*", "" }), i(1, "comment"), t({ "", "*/" }), i(0) }),

	-- Figures and tables

	s("img", { t('#image("'), i(1, "path/image.png"), t('", width: '), i(2, "80%"), t(")"), i(0) }),

	s("fig", {
		t({ "#figure(", '  image("' }),
		i(1, "path/image.png"),
		t('", width: '),
		i(2, "80%"),
		t({ "),", "  caption: [" }),
		i(3, "Caption"),
		t({ "],", ") <fig:" }),
		i(4, "label"),
		t(">"),
		i(0),
	}),

	s("tbl", {
		t({ "#table(", "  columns: " }),
		i(1, "3"),
		t({ ",", "  table.header([" }),
		i(2, "Header 1"),
		t("], ["),
		i(3, "Header 2"),
		t("], ["),
		i(4, "Header 3"),
		t({ "]),", "  [" }),
		i(5, "Cell"),
		t("], ["),
		i(6, "Cell"),
		t("], ["),
		i(7, "Cell"),
		t({ "],", "  [" }),
		i(8, "Cell"),
		t("], ["),
		i(9, "Cell"),
		t("], ["),
		i(10, "Cell"),
		t({ "],", ")" }),
		i(0),
	}),

	s({ trig = "tbl(%d+)x(%d+)", regTrig = true, hidden = true }, {
		d(1, dynamic_table, {}),
	}),

	s("figt", {
		t({ "#figure(", "  table(", "    columns: " }),
		i(1, "2"),
		t({ ",", "    table.header([" }),
		i(2, "Column 1"),
		t("], ["),
		i(3, "Column 2"),
		t({ "]),", "    [" }),
		i(4, "Cell"),
		t("], ["),
		i(5, "Cell"),
		t({ "],", "  ),", "  caption: [" }),
		i(6, "Caption"),
		t({ "],", ") <tbl:" }),
		i(7, "label"),
		t(">"),
		i(0),
	}),

	-- Layout

	s(
		"grid",
		fmta(
			[=[
#grid(
  columns: (<>),
  gutter: <>,
  [<>], [<>],
)<>]=],
			{ i(1, "1fr, 1fr"), i(2, "1em"), i(3), i(4), i(0) }
		)
	),

	s("cols", {
		t("#columns("),
		i(1, "2"),
		t({ ")[", "  " }),
		i(2),
		t({ "", "]" }),
		i(0),
	}),

	s("align", {
		t("#align("),
		c(1, { t("center"), t("right"), t("left"), t("center + horizon") }),
		t(")["),
		i(2, "content"),
		t("]"),
		i(0),
	}),

	s("box", { t("#box("), i(1, "width: 1em"), t(")["), i(2), t("]"), i(0) }),

	s("blk", {
		t("#block(fill: luma(240), inset: 10pt, radius: 4pt, width: 100%)["),
		t({ "", "  " }),
		i(1),
		t({ "", "]" }),
		i(0),
	}),

	s("callout", {
		t("#block(fill: "),
		c(1, {
			t('rgb("#e8f0ff")'),
			t('rgb("#fff4e5")'),
			t('rgb("#ffeaea")'),
			t('rgb("#e8f5e9")'),
			t("luma(240)"),
		}),
		t({ ", inset: 10pt, radius: 4pt, width: 100%)[", "  *" }),
		i(2, "Note:*"),
		t(" "),
		i(3, "Content."),
		t({ "", "]" }),
		i(0),
	}),

	-- Scripting

	s("for", {
		t("#for "),
		i(1, "x"),
		t(" in "),
		i(2, "range(n)"),
		t({ " {", "  " }),
		i(3),
		t({ "", "}" }),
		i(0),
	}),

	s("if", {
		t("#if "),
		i(1, "condition"),
		t({ " {", "  " }),
		i(2),
		t({ "", "}" }),
		i(0),
	}),

	s("ifel", {
		t("#if "),
		i(1, "condition"),
		t({ " {", "  " }),
		i(2),
		t({ "", "} else {", "  " }),
		i(3),
		t({ "", "}" }),
		i(0),
	}),

	s("ctx", { t("#context "), i(1, "counter(page).get().first()"), i(0) }),

	s("lorem", { t("#lorem("), i(1, "50"), t(")"), i(0) }),
	s("today", { t('#datetime.today().display("[day]/[month]/[year]")'), i(0) }),
	s("date", { f(function()
		return os.date("%d/%m/%Y")
	end, {}) }),

	-- Entering and structuring math

	-- `mk` opens inline math and `dm` opens a display block, both only in markup
	s({ trig = "mk", snippetType = "autosnippet", condition = in_markup, show_condition = in_markup }, {
		t("$"),
		i(1),
		t("$"),
		i(0),
	}),

	s({ trig = "dm", snippetType = "autosnippet", condition = in_markup, show_condition = in_markup }, {
		t({ "$", "  " }),
		i(1),
		t({ "", "$" }),
		i(0),
	}),

	-- Numbered equation with a label
	s("eq", {
		t({ "$", "  " }),
		i(1),
		t({ "", "$ <eq:" }),
		i(2, "label"),
		t(">"),
		i(0),
	}),

	-- Aligned equations, use & to align and \ to break the line
	s("aln", {
		t({ "$", "  " }),
		i(1, "a"),
		t(" &= "),
		i(2, "b"),
		t({ " \\", "  &= " }),
		i(3, "c"),
		t({ "", "$" }),
		i(0),
	}),

	-- Math autosnippets

	auto_math("//", { t("frac("), i(1, "a"), t(", "), i(2, "b"), t(")"), i(0) }),
	auto_math("td", { t("^("), i(1), t(")"), i(0) }),
	auto_math("__", { t("_("), i(1), t(")"), i(0) }),
	auto_math("sr", { t("^2"), i(0) }),
	auto_math("inv", { t("^(-1)"), i(0) }, true),
	auto_math("ooo", { t("infinity"), i(0) }, true),

	-- A lone letter followed by digits becomes a subscript: x1 -> x_1
	s({
		trig = "([%a])(%d)",
		regTrig = true,
		wordTrig = true,
		snippetType = "autosnippet",
		condition = in_math,
		show_condition = in_math,
	}, {
		f(function(_, snip)
			return snip.captures[1] .. "_" .. snip.captures[2]
		end),
	}),

	-- Math snippets expanded with <Tab>

	math_snip("frac", { t("frac("), i(1, "a"), t(", "), i(2, "b"), t(")"), i(0) }),
	math_snip("sq", { t("sqrt("), i(1), t(")"), i(0) }),
	math_snip("root", { t("root("), i(1, "3"), t(", "), i(2), t(")"), i(0) }),
	math_snip("sum", { t("sum_("), i(1, "i=1"), t(")^"), i(2, "n"), t(" "), i(0) }),
	math_snip("prod", { t("product_("), i(1, "i=1"), t(")^"), i(2, "n"), t(" "), i(0) }),

	math_snip("int", {
		t("integral_("),
		i(1, "a"),
		t(")^("),
		i(2, "b"),
		t(") "),
		i(3, "f(x)"),
		t(" dif "),
		i(4, "x"),
		i(0),
	}),

	math_snip("lim", { t("lim_("), i(1, "x"), t(" -> "), i(2, "infinity"), t(") "), i(0) }),

	math_snip("dd", { t("frac(dif "), i(1, "f"), t(", dif "), i(2, "x"), t(")"), i(0) }),
	math_snip("part", { t("frac(diff "), i(1, "f"), t(", diff "), i(2, "x"), t(")"), i(0) }),

	math_snip("abs", { t("abs("), i(1), t(")"), i(0) }),
	math_snip("norm", { t("norm("), i(1), t(")"), i(0) }),
	math_snip("ceil", { t("ceil("), i(1), t(")"), i(0) }),
	math_snip("floor", { t("floor("), i(1), t(")"), i(0) }),
	math_snip("binom", { t("binom("), i(1, "n"), t(", "), i(2, "k"), t(")"), i(0) }),

	math_snip("hat", { t("hat("), i(1, "x"), t(")"), i(0) }),
	math_snip("bar", { t("macron("), i(1, "x"), t(")"), i(0) }),
	math_snip("tilde", { t("tilde("), i(1, "x"), t(")"), i(0) }),
	math_snip("vv", { t("arrow("), i(1, "v"), t(")"), i(0) }),
	math_snip("ovl", { t("overline("), i(1), t(")"), i(0) }),
	math_snip("cancel", { t("cancel("), i(1), t(")"), i(0) }),
	math_snip("ubr", { t("underbrace("), i(1), t(", "), i(2, "text"), t(")"), i(0) }),
	math_snip("obr", { t("overbrace("), i(1), t(", "), i(2, "text"), t(")"), i(0) }),

	math_snip("tx", { t('"'), i(1, "text"), t('"'), i(0) }),
	math_snip("bf", { t("bold("), i(1, "x"), t(")"), i(0) }),
	math_snip("up", { t("upright("), i(1, "x"), t(")"), i(0) }),
	math_snip("bb", { t("bb("), i(1, "R"), t(")"), i(0) }),
	math_snip("cal", { t("cal("), i(1, "A"), t(")"), i(0) }),
	math_snip("lr", { t("lr("), i(1, "("), t(" "), i(2), t(" "), i(3, ")"), t(")"), i(0) }),

	math_snip("cases", {
		t({ "cases(", "  " }),
		i(1, "a"),
		t(' "if" '),
		i(2, "x > 0"),
		t({ ",", "  " }),
		i(3, "b"),
		t(' "otherwise"'),
		t({ ",", ")" }),
		i(0),
	}),

	math_snip("mat", {
		t({ "mat(", "  " }),
		i(1, "a"),
		t(", "),
		i(2, "b"),
		t({ ";", "  " }),
		i(3, "c"),
		t(", "),
		i(4, "d"),
		t({ "", ")" }),
		i(0),
	}),

	math_snip("matb", {
		t({ 'mat(delim: "[",', "  " }),
		i(1, "a"),
		t(", "),
		i(2, "b"),
		t({ ";", "  " }),
		i(3, "c"),
		t(", "),
		i(4, "d"),
		t({ "", ")" }),
		i(0),
	}),

	s({ trig = "mat(%d+)x(%d+)", regTrig = true, hidden = true, condition = in_math }, {
		d(1, dynamic_matrix, {}),
	}),

	s({ trig = "vec(%d+)", regTrig = true, hidden = true, condition = in_math }, {
		d(1, dynamic_vector, {}),
	}),

	math_snip("vec", { t("vec("), i(1, "a"), t(", "), i(2, "b"), t(")"), i(0) }),
}

for _, g in ipairs(greek) do
	table.insert(snippets, auto_math(";" .. g[1], { t(g[2]) }))
end

for level = 1, 6 do
	table.insert(snippets, heading(level))
end

return snippets
