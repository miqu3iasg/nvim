-- lua/snippets/latex.lua

local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta

-- Math zone detection, treesitter first, then delimiter check, then vimtex

local MATH_NODES = {
	math_environment = true,
	inline_formula = true,
	displayed_equation = true,
	display_formula = true,
}

local function ts_in_mathzone(row, col)
	local ok_parser, parser = pcall(vim.treesitter.get_parser, 0, "latex")
	if not ok_parser or not parser then
		return nil
	end
	parser:parse()
	local ok, node = pcall(vim.treesitter.get_node, {
		pos = { row - 1, math.max(col - 1, 0) },
		ignore_injections = false,
	})
	if not ok or not node then
		return false
	end
	while node do
		local ty = node:type()
		if ty == "text_mode" then
			return false, true -- \text{...} inside math counts as text
		end
		if MATH_NODES[ty] then
			return true
		end
		node = node:parent()
	end
	return false
end

local function find_last(str, needle)
	local last
	local init = 1
	while true do
		local pos = str:find(needle, init, true)
		if not pos then
			break
		end
		if str:sub(pos - 1, pos - 1) ~= "\\" then -- skip "\\[" line-break spacing
			last = pos
		end
		init = pos + 1
	end
	return last
end

-- Text-based fallback check for \[ ... \] and \( ... \)
local function delimiters_in_mathzone(row, col)
	local lines = vim.api.nvim_buf_get_lines(0, math.max(row - 200, 0), row, false)
	if #lines == 0 then
		return false
	end
	lines[#lines] = lines[#lines]:sub(1, col)
	local text = table.concat(lines, "\n")
	for _, pair in ipairs({ { "\\[", "\\]" }, { "\\(", "\\)" } }) do
		local o = find_last(text, pair[1])
		local c = find_last(text, pair[2])
		if o and (not c or o > c) then
			return true
		end
	end
	return false
end

-- Per-buffer cache
local cache = { buf = -1, tick = -1, row = -1, col = -1, value = false }

local function in_mathzone()
	local buf = vim.api.nvim_get_current_buf()
	local tick = vim.api.nvim_buf_get_changedtick(buf)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	if cache.buf == buf and cache.tick == tick and cache.row == row and cache.col == col then
		return cache.value
	end
	local result, is_text = ts_in_mathzone(row, col)
	if result == nil then
		local ok, res = pcall(vim.fn["vimtex#syntax#in_mathzone"])
		result = (ok and res == 1) or delimiters_in_mathzone(row, col)
	elseif not result and not is_text then
		result = delimiters_in_mathzone(row, col)
	end
	cache = { buf = buf, tick = tick, row = row, col = col, value = result }
	return result
end

local function in_text()
	return not in_mathzone()
end

-- Snippet builder

local M = {}
local WHERE = { math = in_mathzone, text = in_text, any = false }

local function add(snippet)
	M[#M + 1] = snippet
	return snippet
end

--- Builds and registers a snippet
---@param trig string trigger string (or Lua pattern if opts.regex is true)
---@param nodes table snippet body
---@param opts table|nil  where/word/regex/priority/desc/check
local function snip(trig, nodes, opts)
	opts = opts or {}
	local where = opts.where or "math"
	assert(WHERE[where] ~= nil, "invalid `where`: " .. tostring(where))
	local base = WHERE[where] or nil -- false ("any") -> nil

	local auto = where ~= "any"
	local word = opts.word
	if word == nil then
		word = not auto
	end

	-- Backslash guard: alphanumeric plain triggers don't fire right after "\"
	local guard = (not opts.regex) and trig:match("^%w+$") ~= nil
	local check = opts.check
	local cond = base
	if guard or check then
		cond = function(line, matched, captures)
			if guard then
				local n = #(matched or trig)
				if line:sub(#line - n, #line - n) == "\\" then
					return false
				end
			end
			if check and not check(captures or {}, line, matched or trig) then
				return false
			end
			return base == nil or base()
		end
	end

	return add(s({
		trig = trig,
		wordTrig = word,
		trigEngine = opts.regex and "pattern" or "plain",
		priority = opts.priority,
		desc = opts.desc,
		snippetType = auto and "autosnippet" or "snippet",
		hidden = auto, -- keep autosnippets out of the completion menu
	}, nodes, { condition = cond, show_condition = base }))
end

--- Function node returning capture group `n` of a regex-triggered snippet.
local function cap(n)
	return f(function(_, parent)
		return parent.captures[n]
	end)
end

--- Registers a batch of fixed-text snippets from {trigger, text} pairs.
local function simple(list, opts)
	for _, pair in ipairs(list) do
		snip(pair[1], t(pair[2]), opts)
	end
end

--- Dynamic node resolving to the visual selection (or an empty placeholder).
local function get_visual(_, parent)
	local sel = parent.snippet.env.LS_SELECT_RAW
	if sel and #sel > 0 then
		return sn(nil, i(1, sel))
	end
	return sn(nil, i(1))
end

local function visual()
	return d(1, get_visual)
end

-- check() helpers
local function on_boundary(_, line, matched)
	local before = line:sub(#line - #matched, #line - #matched)
	return not before:match("[%a\\]")
end

local function not_script(_, line, matched)
	local before = line:sub(#line - #matched, #line - #matched)
	return before ~= "^" and before ~= "_"
end

local function line_start(_, line, matched)
	return line:sub(1, #line - #matched):match("^%s*$") ~= nil
end

local function not_after_math(_, line, matched)
	return not line:sub(1, #line - #matched):match("\\math$")
end

--- Renders "[" or "]" only when insert node 1 has text in it.
local function bracket(open)
	return f(function(args)
		return args[1][1] ~= "" and (open and "[" or "]") or ""
	end, { 1 })
end

-- Global snippets (expanded with <Tab>)

-- Theorem-like environments: { trigger, environment, Portuguese name, style }.
local THEOREMS = {
	{ "thm", "theorem", "Teorema", "plain" },
	{ "lma", "lemma", "Lema", "plain" },
	{ "prp", "proposition", "Proposição", "plain" },
	{ "crl", "corollary", "Corolário", "plain" },
	{ "clm", "claim", "Afirmação", "plain" },
	{ "cnj", "conjecture", "Conjectura", "plain" },
	{ "hpt", "hypothesis", "Hipótese", "plain" },
	{ "dfn", "definition", "Definição", "definition" },
	{ "exm", "example", "Exemplo", "definition" },
	{ "axm", "axiom", "Axioma", "definition" },
	{ "asn", "assumption", "Suposição", "definition" },
	{ "exr", "exercise", "Exercício", "definition" },
	{ "rmk", "remark", "Observação", "remark" },
}

local function theorem_preamble()
	local lines = {}
	local last_style
	for n, th in ipairs(THEOREMS) do
		local env, name, style = th[2], th[3], th[4]
		if style ~= last_style then
			lines[#lines + 1] = "\\theoremstyle{" .. style .. "}"
			last_style = style
		end
		if n == 1 then
			lines[#lines + 1] = "\\newtheorem{" .. env .. "}{" .. name .. "}"
		else
			lines[#lines + 1] = "\\newtheorem{" .. env .. "}[theorem]{" .. name .. "}"
		end
	end
	return lines
end

snip("head", {
	t({
		[[\documentclass[12pt]{article}]],
		"",
		[[\usepackage[T1]{fontenc}]],
		[[\usepackage[brazilian]{babel}]],
		[[\usepackage[a4paper, margin=2.5cm]{geometry}]],
		[[\usepackage{amsmath, amssymb, amsthm}]],
		[[\usepackage{cancel}]],
		[[\usepackage{graphicx}]],
		"",
	}),
	t(theorem_preamble()),
	t({ "", "", [[\title{]] }),
	i(1, "título"),
	t({ "}", [[\author{]] }),
	i(2, "Miquéias Alves Medeiros"),
	t({ "}", [[\date{\today}]], "", [[\begin{document}]], [[\maketitle]], "" }),
	i(0),
	t({ "", [[\end{document}]] }),
}, { where = "any", desc = "document preamble" })

snip(
	"bg",
	fmta(
		[[
\begin{<>}
<>
\end{<>}
]],
		{ i(1), i(2), rep(1) }
	),
	{ where = "any", desc = "begin/end environment" }
)

snip("lb", fmta("\\label{<>}", { i(1) }), { where = "any", desc = "label" })

-- Text snippets (automatic, only outside math)

local function block(trig, nodes, desc)
	return snip(trig, nodes, { where = "text", word = true, check = line_start, desc = desc })
end

local function inline(trig, nodes, desc)
	return snip(trig, nodes, { where = "text", word = true, desc = desc })
end

inline("mk", fmta("$<>$<>", { visual(), i(0) }), "inline math")
inline("dm", fmta("\\[\n  <>\n\\]<>", { visual(), i(0) }), "display math")
inline("pmk", fmta("\\(<>\\)<>", { visual(), i(0) }), "inline math with \\( \\)")

block("fll", fmta("\\begin{flushleft}\n<>\n\\end{flushleft}", { i(1, "content") }), "flushleft environment")
block("eqn", fmta("\\begin{equation}\n  <>\n\\end{equation}", { i(1) }), "equation")
block("gtr", fmta("\\begin{gather*}\n  <>\n\\end{gather*}", { i(1) }), "gather*")
block("als", fmta("\\begin{align*}\n  <>\n\\end{align*}", { i(1) }), "align*")
block("aln", fmta("\\begin{align}\n  <>\n\\end{align}", { i(1) }), "align")
block("enm", fmta("\\begin{enumerate}\n  \\item <>\n\\end{enumerate}", { i(1) }), "enumerate")
block("blt", fmta("\\begin{itemize}\n  \\item <>\n\\end{itemize}", { i(1) }), "itemize")
block("itm", t("\\item "), "item")
block(
	"fgr",
	fmta(
		"\\begin{figure}[<>]\n  \\centering\n  \\includegraphics[width=<>\\textwidth]{<>}\n"
			.. "  \\caption{<>}\n  \\label{fig:<>}\n\\end{figure}",
		{ i(1, "htbp"), i(2, "0.8"), i(3), i(4), i(5) }
	),
	"figure"
)

block("sct", fmta("\\section{<>}", { i(1) }), "section")
block("ssct", fmta("\\subsection{<>}", { i(1) }), "subsection")
block("sssct", fmta("\\subsubsection{<>}", { i(1) }), "subsubsection")

-- Theorem-like environments. The title brackets only render once you type a title.
for _, th in ipairs(THEOREMS) do
	local env = th[2]
	block(
		th[1],
		fmta("\\begin{" .. env .. "}<><><>\n  <>\n\\end{" .. env .. "}", { bracket(true), i(1), bracket(false), i(2) }),
		env .. " environment"
	)
end
block("prf", fmta("\\begin{proof}\n  <>\n\\end{proof}", { i(1) }), "proof environment")

-- References and emphasis
inline("rf", fmta("\\ref{<>}", { i(1) }), "ref")
inline("eqr", fmta("\\eqref{<>}", { i(1) }), "eqref")
inline("ct", fmta("\\cite{<>}", { i(1) }), "cite")
inline("emph", fmta("\\emph{<>}", { visual() }), "emphasis")
inline("tb", fmta("\\textbf{<>}", { visual() }), "bold")
inline("itl", fmta("\\textit{<>}", { visual() }), "italic")

-- Twins: same trigger in math and in text, different output

local SPECIAL_LETTERS = {
	{ "LL", [[\mathcal{L}]] },
	{ "HH", [[\mathcal{H}]] },
	{ "CC", [[\mathbb{C}]] },
	{ "RR", [[\mathbb{R}]] },
	{ "ZZ", [[\mathbb{Z}]] },
	{ "NN", [[\mathbb{N}]] },
	{ "EE", [[\mathbb{E}]] },
	{ "PP", [[\mathbb{P}]] },
	{ "FF", [[\mathbb{F}]] },
	{ "QQ", [[\mathbb{Q}]] },
}
for _, p in ipairs(SPECIAL_LETTERS) do
	snip(p[1], t(p[2]), { where = "math" })
	snip(p[1], t("$" .. p[2] .. "$"), { where = "text", word = true })
end

for trig, cmd in pairs({ bb = "mathbb", cl = "mathcal", fk = "mathfrak" }) do
	snip(
		trig .. "(%a)",
		f(function(_, p)
			return "\\" .. cmd .. "{" .. p.captures[1] .. "}"
		end),
		{ regex = true, check = on_boundary }
	)
end

snip("...", t([[\dots]]), { where = "math" })
snip("...", t([[\dots]]), { where = "text", desc = "ellipsis (text)" })

snip("qed", t([[\tag*{\(\blacksquare\)}]]), { where = "math" })
snip("qed", t([[\hfill\(\blacksquare\)]]), { where = "text", word = true, desc = "end of proof (text)" })

-- Math snippets (automatic, only inside math)

snip("tf", t([[\therefore]]))
snip("fn", fmta("<>(<>) = <>", { i(1, "fn_name"), i(2, "arg(s)"), i(3, "fn def.") }))

-- Greek letters (short forms)
simple({
	{ "@a", [[\alpha]] },
	{ "@b", [[\beta]] },
	{ "@g", [[\gamma]] },
	{ "@G", [[\Gamma]] },
	{ "@d", [[\delta]] },
	{ "@D", [[\Delta]] },
	{ "@e", [[\epsilon]] },
	{ ":e", [[\varepsilon]] },
	{ "@z", [[\zeta]] },
	{ "@t", [[\theta]] },
	{ "@T", [[\Theta]] },
	{ ":t", [[\vartheta]] },
	{ "@i", [[\iota]] },
	{ "@k", [[\kappa]] },
	{ "@l", [[\lambda]] },
	{ "@L", [[\Lambda]] },
	{ "@s", [[\sigma]] },
	{ "@S", [[\Sigma]] },
	{ "@u", [[\upsilon]] },
	{ "@U", [[\Upsilon]] },
	{ "@o", [[\omega]] },
	{ "@O", [[\Omega]] },
	{ "@f", [[\phi]] },
	{ "@p", [[\psi]] },
	{ "@h", [[\eta]] },
	{ "@m", [[\mu]] },
	{ "@n", [[\nu]] },
	{ "@x", [[\xi]] },
	{ "@X", [[\Xi]] },
	{ "@r", [[\rho]] },
	{ "@c", [[\chi]] },
	{ "@F", [[\Phi]] },
	{ "@P", [[\Psi]] },
})

-- Automatic backslash: typing a Greek letter or function name in full
-- ("alpha", "sin", ...) prepends the backslash.
local BACKSLASH_WORDS = {}
for _, w in ipairs({
	"alpha",
	"beta",
	"gamma",
	"Gamma",
	"delta",
	"Delta",
	"epsilon",
	"varepsilon",
	"zeta",
	"eta",
	"theta",
	"Theta",
	"vartheta",
	"iota",
	"kappa",
	"lambda",
	"Lambda",
	"mu",
	"nu",
	"Xi",
	"pi",
	"Pi",
	"rho",
	"varrho",
	"sigma",
	"Sigma",
	"tau",
	"upsilon",
	"Upsilon",
	"phi",
	"Phi",
	"varphi",
	"chi",
	"psi",
	"Psi",
	"omega",
	"Omega",
	"exp",
	"log",
	"ln",
	"det",
	"arcsin",
	"arccos",
	"arctan",
	"sin",
	"cos",
	"tan",
	"csc",
	"sec",
	"cot",
	"sinh",
	"cosh",
	"tanh",
	"coth",
	"max",
	"min",
	"arg",
	"hbar",
	"ell",
	"infty",
	"forall",
	"exists",
	"leq",
	"geq",
	"neq",
	"approx",
	"equiv",
	"times",
	"cup",
	"cap",
	"subset",
	"supset",
	"subseteq",
	"supseteq",
	"implies",
}) do
	BACKSLASH_WORDS[w] = true
end

snip(
	"(%a+)",
	f(function(_, parent)
		return "\\" .. parent.captures[1]
	end),
	{
		regex = true,
		desc = "backslash before Greek letters and function names",
		check = function(captures, line)
			local run = captures[1]
			if not run or not BACKSLASH_WORDS[run] then
				return false
			end
			return line:sub(#line - #run, #line - #run) ~= "\\"
		end,
	}
)

snip("text", fmta([[\text{<>}<>]], { i(1), i(0) }))
snip([["]], fmta([[\text{<>}<>]], { i(1), i(0) }))

-- Basic operators
simple({
	{ "sr", [[^{2}]] },
	{ "cb", [[^{3}]] },
	{ "invs", [[^{-1}]] },
	{ "conj", [[^{*}]] },
	{ "Re", [[\mathrm{Re}]] },
	{ "Im", [[\mathrm{Im}]] },
	{ "trace", [[\mathrm{Tr}]] },
})

snip("rd", fmta([[^{<>}<>]], { i(1), i(0) }))
snip("_", fmta([[_{<>}<>]], { i(1), i(0) }))
snip("stx", fmta([[_\text{<>}]], { i(1) }))
snip("sq", fmta([[\sqrt{ <> }<>]], { visual(), i(0) }), { desc = "square root (wraps the selection)" })
snip("//", fmta([[\frac{<>}{<>}<>]], { i(1), i(2), i(0) }))
snip("ee", fmta([[e^{ <> }<>]], { i(1), i(0) }))
snip("bf", fmta([[\mathbf{<>}]], { i(1) }), { check = not_after_math })
snip("bxd", fmta([[\boxed{<>}<>]], { i(1), i(0) }))
snip("tag", fmta([[\tag{<>}<>]], { i(1), i(0) }))
snip("rm", fmta([[\mathrm{<>}<>]], { i(1), i(0) }), { check = not_after_math })

-- Smart fractions: typing "/" right after a numerator turns it into \frac{numerator}{}.
local function frac(numerator)
	return { t([[\frac{]]), numerator, t("}{"), i(1), t("}"), i(0) }
end

snip([[(%d+%.?%d*)/]], frac(cap(1)), { regex = true, check = not_script, desc = "fraction from number" })
snip([[(%d*\?%a+)/]], frac(cap(1)), { regex = true, check = not_script, desc = "fraction from symbol" })
snip([[(%d*\?%a+[_^]%b{})/]], frac(cap(1)), { regex = true, desc = "fraction from symbol with script" })
snip(
	[[(%b())/]],
	frac(f(function(_, parent)
		return parent.captures[1]:sub(2, -2)
	end)),
	{ regex = true, desc = "fraction from parenthesized expression" }
)

-- Fixes "_{1}0" into "_{10}".
snip(
	[[_{(%d+)}(%d)]],
	f(function(_, p)
		return "_{" .. p.captures[1] .. p.captures[2] .. "}"
	end),
	{ regex = true, desc = "x_{1}0 -> x_{10}" }
)

-- Automatic subscripting: "x1" -> "x_{1}".
snip("([A-Za-z])(%d)", { cap(1), t("_{"), cap(2), t("}") }, {
	regex = true,
	priority = -1,
	desc = "automatic subscript",
})

-- \hat{x}1, \vec{x}1, \mathbf{x}1 -> \hat{x}_{1}, ...
local SUBSCRIPTABLE = { hat = true, vec = true, mathbf = true }
snip(
	[[\(%a+){([A-Za-z])}(%d)]],
	f(function(_, parent)
		local c = parent.captures
		return "\\" .. c[1] .. "{" .. c[2] .. "}_{" .. c[3] .. "}"
	end),
	{
		regex = true,
		desc = "subscript after accented letter",
		check = function(captures)
			return SUBSCRIPTABLE[captures[1]] == true
		end,
	}
)

simple({
	{ "xnn", [[x_{n}]] },
	{ "xii", [[x_{i}]] },
	{ "xjj", [[x_{j}]] },
	{ "xp1", [[x_{n+1}]] },
	{ "ynn", [[y_{n}]] },
	{ "yii", [[y_{i}]] },
	{ "yjj", [[y_{j}]] },
})

-- Accents: "xhat" -> \hat{x}, "ybar" -> \bar{y}, ...
local ACCENTS = {
	hat = "hat",
	bar = "bar",
	ddot = "ddot",
	tilde = "tilde",
	und = "underline",
	vec = "vec",
	dot = "dot",
}

snip(
	"(%a)(%a+)",
	f(function(_, parent)
		local c = parent.captures
		return "\\" .. ACCENTS[c[2]] .. "{" .. c[1] .. "}"
	end),
	{
		regex = true,
		priority = -1,
		desc = "accent after a single letter",
		check = function(captures, line, matched)
			local letter, name = captures[1], captures[2]
			if not (letter and name and ACCENTS[name]) then
				return false
			end
			local run = letter .. name
			if run == "cdot" or run == "ddot" then
				return false
			end
			return line:sub(#line - #matched, #line - #matched) ~= "\\"
		end,
	}
)

for name, cmd in pairs(ACCENTS) do
	snip(name, fmta("\\" .. cmd .. "{<>}<>", { i(1), i(0) }), { word = true })
end
snip("cdot", t([[\cdot]]))

-- Letter followed by ",." or ".," becomes bold; Greek letters produce \boldsymbol.
snip("([a-zA-Z]),%.", { t([[\mathbf{]]), cap(1), t("}") }, { regex = true })
snip("([a-zA-Z])%.,", { t([[\mathbf{]]), cap(1), t("}") }, { regex = true })
snip([[\(%a+),%.]], { t([[\boldsymbol{\]]), cap(1), t("}") }, { regex = true })
snip([[\(%a+)%.,]], { t([[\boldsymbol{\]]), cap(1), t("}") }, { regex = true })

snip("wh", fmta([[\widehat{<>}<>]], { i(1), i(0) }), { desc = "wide hat" })
snip("wt", fmta([[\widetilde{<>}<>]], { i(1), i(0) }), { desc = "wide tilde" })

-- Symbols
simple({
	{ "ooo", [[\infty]] },
	{ "+-", [[\pm]] },
	{ "-+", [[\mp]] },
	{ "nabl", [[\nabla]] },
	{ "xx", [[\times]] },
	{ "**", [[\cdot]] },
	{ "prl", [[\parallel]] },
	{ "===", [[\equiv]] },
	{ "!=", [[\neq]] },
	{ ">=", [[\geq]] },
	{ "<=", [[\leq]] },
	{ ">>", [[\gg]] },
	{ "<<", [[\ll]] },
	{ "simm", [[\sim]] },
	{ "sim=", [[\simeq]] },
	{ "prop", [[\propto]] },
	{ "->", [[\to]] },
	{ "!>", [[\mapsto]] },
	{ "=>", [[\implies]] },
	{ "=<", [[\impliedby]] },
	{ "orr", [[\cup]] },
	{ "inn", [[\in]] },
	{ "notin", [[\not\in]] },
	{ [[\\\]], [[\setminus]] },
	{ "sub=", [[\subseteq]] },
	{ "sup=", [[\supseteq]] },
	{ "dag", [[^{\dagger}]] },
	{ "o+", [[\oplus ]] },
	{ "div", [[\nabla \cdot ]] },
	{ "curl", [[\nabla \times ]] },
	{ "lap", [[\nabla^{2} ]] },
})
snip("<->", t([[\leftrightarrow ]]), { priority = 1100 })

-- Word-boundary triggers
snip("andd", t([[\cap]]), { word = true })
snip("fal", t([[\forall]]), { word = true })
snip("ox", t([[\otimes ]]), { word = true })

snip("eset", t([[\emptyset]]), { priority = 1 })
snip("sett", fmta([[\{ <> \}<>]], { i(1), i(0) }), { word = true })

snip("sum", fmta([[\sum_{<>=<>}^{<>} <>]], { i(1, "i"), i(2, "1"), i(3, "N"), i(0) }), { desc = "sum with bounds" })
snip(
	"prod",
	fmta([[\prod_{<>=<>}^{<>} <>]], { i(1, "i"), i(2, "1"), i(3, "N"), i(0) }),
	{ desc = "product with bounds" }
)
snip("lim", fmta([[\lim_{ <> \to <> } <>]], { i(1, "n"), i(2, [[\infty]]), i(0) }))

-- Derivatives and integrals
snip("apl", fmta([[\left. <> \right|_{<>}^{<>} <>]], { i(1), i(2, "a"), i(3, "b"), i(0) }))
snip("ev", fmta([[\left. <> \right|_{<> = <>}]], { i(1, "f"), i(2, "x"), i(3, "a") }))
snip("pd", fmta([[\frac{ \partial <> }{ \partial <> } <>]], { i(1, "y"), i(2, "x"), i(0) }))
snip(
	"pa([A-Za-z])([A-Za-z])",
	{ t([[\frac{ \partial ]]), cap(1), t([[ }{ \partial ]]), cap(2), t(" } ") },
	{ regex = true, check = on_boundary }
)
snip("ddt", t([[\frac{d}{dt} ]]))
snip("dv", fmta([[\frac{d<>}{d<>} <>]], { i(1, "y"), i(2, "x"), i(0) }), { desc = "ordinary derivative" })
snip(
	"ddv",
	fmta([[\frac{d^{2}<>}{d<>^{2}} <>]], { i(1, "y"), i(2, "x"), i(0) }),
	{ priority = 1100, desc = "second ordinary derivative" }
)
snip(
	"ppd",
	fmta([[\frac{\partial^{2} <>}{\partial <>^{2}} <>]], { i(1, "f"), i(2, "x"), i(0) }),
	{ priority = 1100, desc = "second partial derivative" }
)
snip(
	"mpd",
	fmta([[\frac{\partial^{2} <>}{\partial <> \partial <>} <>]], { i(1, "f"), i(2, "x"), i(3, "y"), i(0) }),
	{ priority = 1100, desc = "mixed partial derivative" }
)

snip(
	"([^%a\\])int",
	{ cap(1), t([[\int ]]), i(1), t([[ \, d]]), i(2, "x"), t(" "), i(0) },
	{ regex = true, priority = -1 }
)
snip("dint", fmta([[\int_{<>}^{<>} <> \, d<> <>]], { i(1, "0"), i(2, "1"), i(3), i(4, "x"), i(0) }))
snip("oinf", fmta([[\int_{0}^{\infty} <> \, d<> <>]], { i(1), i(2, "x"), i(0) }))
snip("infi", fmta([[\int_{-\infty}^{\infty} <> \, d<> <>]], { i(1), i(2, "x"), i(0) }))

simple({
	{ "oint", [[\oint]] },
	{ "iint", [[\iint]] },
})
snip("iiint", t([[\iiint]]), { priority = 1100 })

-- Visual operations (wrap the current selection)
snip("ubr", fmta([[\underbrace{ <> }_{ <> }]], { visual(), i(2) }), { desc = "underbrace" })
snip("obr", fmta([[\overbrace{ <> }^{ <> }]], { visual(), i(2) }), { desc = "overbrace" })
snip("ust", fmta([[\underset{ <> }{ <> }]], { i(2), visual() }), { desc = "underset" })
snip("cnc", fmta([[\cancel{ <> }]], { visual() }), { desc = "cancel" })
snip("cto", fmta([[\cancelto{ <> }{ <> }]], { i(2), visual() }), { desc = "cancelto" })

-- Math environments
local MATH_ENVS = {
	{ "pmat", "pmatrix" },
	{ "bmat", "bmatrix" },
	{ "Bmat", "Bmatrix" },
	{ "vmat", "vmatrix" },
	{ "Vmat", "Vmatrix" },
	{ "matrix", "matrix" },
	{ "cases", "cases" },
	{ "array", "array" },
}
for _, e in ipairs(MATH_ENVS) do
	snip(e[1], fmta("\\begin{" .. e[2] .. "}\n<>\n\\end{" .. e[2] .. "}", { i(1) }), { word = true })
end

-- Identity matrix generator: "iden3" -> 3x3 identity matrix.
snip(
	"iden(%d)",
	f(function(_, parent)
		local n = tonumber(parent.captures[1]) or 2
		local out = { [[\begin{pmatrix}]] }
		for r = 1, n do
			local row = {}
			for c = 1, n do
				row[c] = (r == c) and "1" or "0"
			end
			out[#out + 1] = table.concat(row, " & ") .. (r < n and [[ \\]] or "")
		end
		out[#out + 1] = [[\end{pmatrix}]]
		return out
	end),
	{ regex = true, desc = "N x N identity matrix" }
)

-- Delimiters
snip("avg", fmta([[\langle <> \rangle <>]], { i(1), i(0) }))
snip("norm", fmta([[\lvert <> \rvert <>]], { i(1), i(0) }), { priority = 1100 })
snip("Norm", fmta([[\lVert <> \rVert <>]], { i(1), i(0) }), { priority = 1100 })
snip("ceil", fmta([[\lceil <> \rceil <>]], { i(1), i(0) }), { word = true })
snip("floor", fmta([[\lfloor <> \rfloor <>]], { i(1), i(0) }), { word = true })
snip("mod", fmta([[|<>|<>]], { i(1), i(0) }), { word = true })
snip("lr(", fmta([[\left( <> \right) <>]], { i(1), i(0) }))
snip("lr{", fmta([[\left\{ <> \right\} <>]], { i(1), i(0) }))
snip("lr[", fmta([[\left[ <> \right] <>]], { i(1), i(0) }))
snip("lr|", fmta([[\left| <> \right| <>]], { i(1), i(0) }))
snip("lra", fmta([[\left<< <> \right>> <>]], { i(1), i(0) }))

-- Linear algebra and combinatorics
simple({
	{ "tp", [[^{T}]] },
	{ "rank", [[\mathrm{rank}]] },
	{ "ker", [[\ker]] },
	{ "span", [[\operatorname{span}]] },
	{ "cdts", [[\cdots]] },
	{ "vdts", [[\vdots]] },
	{ "dgts", [[\ddots]] },
	{ "gcd", [[\gcd]] },
	{ "lcm", [[\mathrm{lcm}]] },
	{ "dim", [[\dim]] },
	{ "deg", [[\deg]] },
	{ "bigcup", [[\bigcup]] },
	{ "bigcap", [[\bigcap]] },
	{ "bigplus", [[\bigoplus]] },
	{ "bigtimes", [[\bigotimes]] },
})

snip("xar", fmta([[\xrightarrow{ <> } <>]], { i(1), i(0) }), { desc = "labeled arrow" })
snip("xla", fmta([[\xleftarrow{ <> } <>]], { i(1), i(0) }), { desc = "labeled arrow (leftward)" })
snip("bino", fmta([[\binom{<>}{<>} <>]], { i(1, "n"), i(2, "k"), i(0) }))
snip("rt3", fmta([[\sqrt[3]{ <> }<>]], { i(1), i(0) }), { desc = "cube root" })
snip("nrt", fmta([[\sqrt[<>]{ <> }<>]], { i(1, "n"), i(2), i(0) }), { desc = "nth root" })
snip("sst", fmta([[\substack{ <> } <>]], { i(1), i(0) }))

-- Probability and statistics
simple({
	{ "Var", [[\mathrm{Var}]] },
	{ "Cov", [[\mathrm{Cov}]] },
})

-- Logic and mathematical prose
simple({
	{ "iff", [[\iff]] },
	{ "tq", [[\text{ tal que }]] },
	{ "cong", [[\cong]] },
	{ "aprx", [[\approx]] },
	{ "perp", [[\perp]] },
	{ "top", [[\top]] },
	{ "bot", [[\bot]] },
	{ "neg", [[\neg]] },
	{ "wedge", [[\wedge]] },
	{ "ssub", [[\subset]] },
	{ "ssup", [[\supset]] },
	{ "because", [[\because]] },
	{ "Rar", [[\Rightarrow]] },
	{ "Lar", [[\Leftarrow]] },
})
snip("vee", t([[\vee]]), { priority = 1100 })

snip("amax", fmta([[\underset{<>}{\mathrm{argmax}} \; <>]], { i(1), i(0) }))
snip("amin", fmta([[\underset{<>}{\mathrm{argmin}} \; <>]], { i(1), i(0) }))
snip("bigo", fmta([[\mathcal{O}( <> )<>]], { i(1), i(0) }), { desc = "big-O notation" })

-- Preset expansions
snip(
	"tayl",
	fmta([[<>(<> + <>) = <>(<>) + <>'(<>)<> + <>''(<>) \frac{<>^{2}}{2!} + \dots<>]], {
		i(1, "f"),
		i(2, "x"),
		i(3, "h"),
		rep(1),
		rep(2),
		rep(1),
		rep(2),
		rep(3),
		rep(1),
		rep(2),
		rep(3),
		i(0),
	}),
	{ desc = "Taylor expansion" }
)

return M
