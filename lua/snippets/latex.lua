-- lua/snippets/latex.lua
--
-- LaTeX snippets for LuaSnip, ported from my personal snippet set
-- of the Obsidian Plugin Latex Suite.
--
-- Setup requirements in `lua/plugins/completions.lua`:
--
-- ```lua
--   require("luasnip").setup({
--     enable_autosnippets = true,
--     store_selection_keys = "<Tab>", -- Required by ${VISUAL}-style snippets.
--   })
-- ```
--
-- This file uses the following conventions to map Latex Suite options.
--
-- refs:
--     - https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md
--     - https://github.com/L3MON4D3/LuaSnip/blob/master/Examples/snippets.lua
--     - https://github.com/artisticat1/obsidian-latex-suite

local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local rep = require("luasnip.extras").rep
local fmta = require("luasnip.extras.fmt").fmta

-- Vimtex is used when present, since it correctly accounts
-- for LaTeX-specific constructs; the treesitter query is a
-- reasonable fallback for setups without vimtex.
local function in_mathzone()
  if vim.fn.exists("*vimtex#syntax#in_mathzone") == 1 then
    return vim.fn["vimtex#syntax#in_mathzone"]() == 1
  end
  local ok, node = pcall(vim.treesitter.get_node, { ignore_injections = false })
  if not ok or not node then
    return false
  end
  local math_nodes = {
    math_environment = true,
    inline_formula = true,
    displayed_equation = true,
    display_formula = true,
  }
  while node do
    if math_nodes[node:type()] then
      return true
    end
    node = node:parent()
  end
  return false
end

local function in_text()
  return not in_mathzone()
end

local M = {}

local function add(snip)
  M[#M + 1] = snip
  return snip
end

--- Builds and registers a snippet.
---@param trig string        trigger string, or a Lua pattern when opts.regex is true
---@param nodes table|userdata  snippet body (a node, or a list of nodes)
---@param opts table|nil
---   word     boolean  require a word boundary before the trigger (default false)
---   regex    boolean  treat `trig` as a Lua pattern (default false)
---   priority number    resolves conflicts between overlapping triggers
---   desc     string   snippet description
---   manual   boolean  expand on <Tab> instead of automatically (default false)
---   cond     function|false  condition to expand under; false removes the
---            condition entirely (the snippet is valid everywhere);
---            the default is in_mathzone
local function snip(trig, nodes, opts)
  opts = opts or {}
  local cond = opts.cond
  if cond == nil then
    cond = in_mathzone
  elseif cond == false then
    cond = nil
  end
  return add(s({
    trig = trig,
    wordTrig = opts.word or false,
    trigEngine = opts.regex and "pattern" or "plain",
    priority = opts.priority,
    desc = opts.desc,
    snippetType = opts.manual and "snippet" or "autosnippet",
  }, nodes, { condition = cond, show_condition = cond }))
end

--- Function node returning capture group `n` of a regex-triggered snippet.
local function cap(n)
  return f(function(_, parent)
    return parent.captures[n]
  end)
end

--- Registers a batch of fixed-text snippets from a list of {trigger, text} pairs.
local function simple(list, opts)
  for _, pair in ipairs(list) do
    snip(pair[1], t(pair[2]), opts)
  end
end

--- Resolves to the text that was visually selected before the snippet was
--- triggered (LuaSnip's equivalent of Latex Suite's ${VISUAL}), or to an
--- empty, editable insert node when nothing was selected.
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

-- User-defined snippets

-- Disabled: "int" would otherwise conflict with the automatic integral
-- rule further down (see the Integrals section). Use "ZZ" for \mathbb{Z}.
-- add(s("int", t("\\mathbb{Z}")))
-- add(s("intp", t("\\mathbb{Z}^{+}")))

add(s("tf", t("\\therefore")))

add(s("fll", {
  t({ "\\begin{flushleft}", "" }),
  i(1, "content"),
  t({ "", "\\end{flushleft}" }),
}))

add(s("ali", {
  t({ "\\begin{align*}", "" }),
  i(1, "content"),
  t({ "", "\\end{align*}" }),
}))

add(s("head", {
  t({ "\\documentclass{article}", "" }),
  t({ "\\usepackage{amsmath}", "" }),
  t({ "\\usepackage{amssymb}", "" }),
  t({ "\\usepackage{amsthm}", "", "" }),
  t({ "\\title{" }),
  i(1, "title"),
  t({ "}", "" }),
  t({ "\\author{Michael Williams}", "" }),
  t({ "\\date{\\today}", "", "" }),
  t({ "\\begin{document}", "" }),
  t({ "\\maketitle", "" }),
  i(2, "content"),
  t({ "", "\\end{document}" }),
}))

add(s("fn", {
  i(1, "fn_name"),
  t("("),
  i(2, "arg(s)"),
  t(") = "),
  i(3, "fn def."),
}))

-- Generic environment

snip("bg", fmta([[
\begin{<>}
<>
\end{<>}
]], { i(1), i(2), rep(1) }), { cond = false, desc = "begin/end environment" })

-- Greek letters

simple({
  { "@a",  [[\alpha]] },
  { "@b",  [[\beta]] },
  { "@g",  [[\gamma]] },
  { "@G",  [[\Gamma]] },
  { "@d",  [[\delta]] },
  { "@D",  [[\Delta]] },
  { "@e",  [[\epsilon]] },
  { ":e",  [[\varepsilon]] },
  { "@z",  [[\zeta]] },
  { "@t",  [[\theta]] },
  { "@T",  [[\Theta]] },
  { ":t",  [[\vartheta]] },
  { "@i",  [[\iota]] },
  { "@k",  [[\kappa]] },
  { "@l",  [[\lambda]] },
  { "@L",  [[\Lambda]] },
  { "@s",  [[\sigma]] },
  { "@S",  [[\Sigma]] },
  { "@u",  [[\upsilon]] },
  { "@U",  [[\Upsilon]] },
  { "@o",  [[\omega]] },
  { "@O",  [[\Omega]] },
  { "@f",  [[\phi]] },
  { "@p",  [[\psi]] },
  { "@h",  [[\eta]] },
  { "@m",  [[\mu]] },
  { "@n",  [[\nu]] },
  { "@x",  [[\xi]] },
  { "@X",  [[\Xi]] },
  { "@r",  [[\rho]] },
  { "@c",  [[\chi]] },
  { "@F",  [[\Phi]] },
  { "@P",  [[\Psi]] },
  { "ome", [[\omega]] },
  { "Ome", [[\Omega]] },
  { "tau", [[\tau]] },
})

-- Inserts a backslash automatically when a Greek letter name is typed out
-- in full (e.g. "alpha" -> "\alpha"). The "[^%a\\]" lookbehind requires a
-- non-letter, non-backslash character before the match, which keeps
-- "varepsilon" from being read as "var" + "epsilon".
local GREEK = {
  "alpha", "beta", "gamma", "Gamma", "delta", "Delta", "epsilon", "varepsilon",
  "zeta", "eta", "theta", "Theta", "vartheta", "iota", "kappa", "lambda",
  "Lambda", "mu", "nu", "xi", "Xi", "pi", "Pi", "rho", "varrho", "sigma",
  "Sigma", "tau", "upsilon", "Upsilon", "phi", "Phi", "varphi", "chi",
  "psi", "Psi", "omega", "Omega",
}
for _, g in ipairs(GREEK) do
  snip("([^%a\\])" .. g, { cap(1), t("\\" .. g) }, {
    regex = true,
    desc = "backslash before " .. g,
  })
end

-- Text environment

snip("text", fmta([[\text{<>}<>]], { i(1), i(0) }))
snip([["]], fmta([[\text{<>}<>]], { i(1), i(0) }))

-- Basic operators

simple({
  { "sr",    [[^{2}]] },
  { "cb",    [[^{3}]] },
  { "invs",  [[^{-1}]] },
  { "conj",  [[^{*}]] },
  { "Re",    [[\mathrm{Re}]] },
  { "Im",    [[\mathrm{Im}]] },
  { "trace", [[\mathrm{Tr}]] },
})

snip("rd", fmta([[^{<>}<>]], { i(1), i(0) }))
snip("_", fmta([[_{<>}<>]], { i(1), i(0) }))
snip("sts", fmta([[_\text{<>}]], { i(1) }))
snip("sq", fmta([[\sqrt{ <> }<>]], { i(1), i(0) }))
snip("//", fmta([[\frac{<>}{<>}<>]], { i(1), i(2), i(0) }))
snip("ee", fmta([[e^{ <> }<>]], { i(1), i(0) }))
snip("bf", fmta([[\mathbf{<>}]], { i(1) }))
snip("tb", fmta([[\textbf{<>}<>]], { i(1), i(0) }))
snip("box", fmta([[\boxed{<>}<>]], { i(1), i(0) }))
snip("tag", fmta([[\tag{<>}<>]], { i(1), i(0) }))
snip("qed", t([[\tag*{\(\blacksquare\)}]]))
snip("rm", fmta([[\mathrm{<>}<>]], { i(1), i(0) }))

-- Automatic subscripting: a letter directly followed by one digit becomes
-- letter_{digit} (e.g. "x1" -> "x_{1}"); negative priority lets more
-- specific rules (accents, function names) win when they overlap.
snip("([A-Za-z])(%d)", { cap(1), t("_{"), cap(2), t("}") }, {
  regex = true,
  priority = -1,
  desc = "automatic subscript",
})
snip("([A-Za-z])_(%d%d)", { cap(1), t("_{"), cap(2), t("}") }, { regex = true })
snip([[\hat{([A-Za-z])}(%d)]], { t([[\hat{]]), cap(1), t("}_{"), cap(2), t("}") }, { regex = true })
snip([[\vec{([A-Za-z])}(%d)]], { t([[\vec{]]), cap(1), t("}_{"), cap(2), t("}") }, { regex = true })
snip([[\mathbf{([A-Za-z])}(%d)]], { t([[\mathbf{]]), cap(1), t("}_{"), cap(2), t("}") }, { regex = true })

simple({
  { "xnn", [[x_{n}]] },
  { "xii", [[x_{i}]] },
  { "xjj", [[x_{j}]] },
  { "xp1", [[x_{n+1}]] },
  { "ynn", [[y_{n}]] },
  { "yii", [[y_{i}]] },
  { "yjj", [[y_{j}]] },
})

-- Inserts a backslash automatically before common function names.
local FUNCS = {
  "exp", "log", "ln", "det", "arcsin", "arccos", "arctan",
  "sin", "cos", "tan", "csc", "sec", "cot",
  "sinh", "cosh", "tanh", "coth",
}
for _, fname in ipairs(FUNCS) do
  snip("([^%a\\])" .. fname, { cap(1), t("\\" .. fname) }, {
    regex = true,
    desc = "backslash before " .. fname,
  })
end

-- Accents

local ACCENTS = {
  { "hat",   "hat" },
  { "bar",   "bar" },
  { "ddot",  "ddot" },
  { "tilde", "tilde" },
  { "und",   "underline" },
  { "vec",   "vec" },
}
for _, a in ipairs(ACCENTS) do
  snip("([a-zA-Z])" .. a[1], { t("\\" .. a[2] .. "{"), cap(1), t("}") }, {
    regex = true,
    priority = 1,
  })
  snip(a[1], fmta("\\" .. a[2] .. "{<>}<>", { i(1), i(0) }))
end

snip("([a-zA-Z])dot", { t([[\dot{]]), cap(1), t("}") }, { regex = true, priority = -1 })
snip("dot", fmta([[\dot{<>}<>]], { i(1), i(0) }), { priority = -1 })
snip("cdot", t([[\cdot]]))

-- Letter followed by ",." or ".," becomes bold (e.g. "x,." -> "\mathbf{x}");
-- the equivalent forms for Greek letters produce \boldsymbol instead.
snip("([a-zA-Z]),%.", { t([[\mathbf{]]), cap(1), t("}") }, { regex = true })
snip("([a-zA-Z])%.,", { t([[\mathbf{]]), cap(1), t("}") }, { regex = true })
snip([[\(%a+),%.]], { t([[\boldsymbol{\]]), cap(1), t("}") }, { regex = true })
snip([[\(%a+)%.,]], { t([[\boldsymbol{\]]), cap(1), t("}") }, { regex = true })

snip("wh", fmta([[\widehat{<>}<>]], { i(1), i(0) }), { desc = "wide hat" })
snip("wt", fmta([[\widetilde{<>}<>]], { i(1), i(0) }), { desc = "wide tilde" })

-- Symbols

simple({
  { "ooo",    [[\infty]] },
  { "+-",     [[\pm]] },
  { "-+",     [[\mp]] },
  { "...",    [[\dots]] },
  { "nabl",   [[\nabla]] },
  { "xx",     [[\times]] },
  { "**",     [[\cdot]] },
  { "para",   [[\parallel]] },
  { "===",    [[\equiv]] },
  { "!=",     [[\neq]] },
  { ">=",     [[\geq]] },
  { "<=",     [[\leq]] },
  { ">>",     [[\gg]] },
  { "<<",     [[\ll]] },
  { "simm",   [[\sim]] },
  { "sim=",   [[\simeq]] },
  { "prop",   [[\propto]] },
  { "<->",    [[\leftrightarrow ]] },
  { "->",     [[\to]] },
  { "!>",     [[\mapsto]] },
  { "=>",     [[\implies]] },
  { "=<",     [[\impliedby]] },
  { "and",    [[\cap]] },
  { "orr",    [[\cup]] },
  { "inn",    [[\in]] },
  { "notin",  [[\not\in]] },
  -- three literal backslashes
  { [[\\\]],  [[\setminus]] },
  { "sub=",   [[\subseteq]] },
  { "sup=",   [[\supseteq]] },
  { "exists", [[\exists]] },
  { "LL",     [[\mathcal{L}]] },
  { "HH",     [[\mathcal{H}]] },
  { "CC",     [[\mathbb{C}]] },
  { "RR",     [[\mathbb{R}]] },
  { "ZZ",     [[\mathbb{Z}]] },
  { "NN",     [[\mathbb{N}]] },
})

snip("eset", t([[\emptyset]]), { priority = 1 })
snip("set", fmta([[\{ <> \}<>]], { i(1), i(0) }), { word = true })

snip("sum", fmta([[\sum_{<>=<>}^{<>} <>]], { i(1, "i"), i(2, "1"), i(3, "N"), i(0) }),
  { desc = "sum with bounds" })
snip("prod", fmta([[\prod_{<>=<>}^{<>} <>]], { i(1, "i"), i(2, "1"), i(3, "N"), i(0) }),
  { desc = "product with bounds" })
snip("lim", fmta([[\lim_{ <> \to <> } <>]], { i(1, "n"), i(2, [[\infty]]), i(0) }))

-- Derivatives and integrals

snip("apl", fmta([[\left. <> \right|_{<>}^{<>} <>]], { i(1), i(2, "a"), i(3, "b"), i(0) }))
snip("ev", fmta([[\left. <> \right|_{<> = <>}]], { i(1), i(2, "x"), i(3, "a") }))
snip("pd", fmta([[\frac{ \partial <> }{ \partial <> } <>]], { i(1, "y"), i(2, "x"), i(0) }))
snip("pa([A-Za-z])([A-Za-z])",
  { t([[\frac{ \partial ]]), cap(1), t([[ }{ \partial ]]), cap(2), t(" } ") },
  { regex = true })
snip("ddt", t([[\frac{d}{dt} ]]))
snip("dv", fmta([[\frac{d<>}{d<>} <>]], { i(1, "y"), i(2, "x"), i(0) }),
  { desc = "ordinary derivative (Leibniz notation)" })
snip("d2v", fmta([[\frac{d^{2}<>}{d<>^{2}} <>]], { i(1, "y"), i(2, "x"), i(0) }),
  { desc = "second ordinary derivative" })
snip("p2d", fmta([[\frac{\partial^{2} <>}{\partial <>^{2}} <>]], { i(1, "f"), i(2, "x"), i(0) }),
  { desc = "second partial derivative" })
snip("mpd", fmta([[\frac{\partial^{2} <>}{\partial <> \partial <>} <>]],
  { i(1, "f"), i(2, "x"), i(3, "y"), i(0) }), { desc = "mixed partial derivative" })

-- A bare "int" (not preceded by a letter or backslash) expands directly
-- into the full template, with placeholders for the integrand and the
-- differential variable.
snip("([^%a\\])int", { cap(1), t([[\int ]]), i(1), t([[ \, d]]), i(2, "x"), t(" "), i(0) },
  { regex = true, priority = -1 })
snip("dint", fmta([[\int_{<>}^{<>} <> \, d<> <>]], { i(1, "0"), i(2, "1"), i(3), i(4, "x"), i(0) }))
snip("oinf", fmta([[\int_{0}^{\infty} <> \, d<> <>]], { i(1), i(2, "x"), i(0) }))
snip("infi", fmta([[\int_{-\infty}^{\infty} <> \, d<> <>]], { i(1), i(2, "x"), i(0) }))

simple({
  { "oint",  [[\oint]] },
  { "iint",  [[\iint]] },
  { "iiint", [[\iiint]] },
  { "dif",   [[\differential ]] },
})

-- Visual operations
--
-- These wrap the current visual selection (or an empty placeholder, if
-- nothing was selected) and require store_selection_keys to be set in
-- luasnip.setup().

snip("U", fmta([[\underbrace{ <> }_{ <> }]], { visual(), i(2) }))
snip("O", fmta([[\overbrace{ <> }^{ <> }]], { visual(), i(2) }))
snip("B", fmta([[\underset{ <> }{ <> }]], { i(2), visual() }))
snip("C", fmta([[\cancel{ <> }]], { visual() }))
snip("K", fmta([[\cancelto{ <> }{ <> }]], { i(2), visual() }))
snip("S", fmta([[\sqrt{ <> }]], { visual() }))

-- Physics and quantum mechanics

simple({
  { "kbt",  [[k_{B}T]] },
  { "msun", [[M_{\odot}]] },
  { "dag",  [[^{\dagger}]] },
  { "o+",   [[\oplus ]] },
  { "ox",   [[\otimes ]] },
  { "div",  [[\nabla \cdot ]] },
  { "curl", [[\nabla \times ]] },
  { "lap",  [[\nabla^{2} ]] },
})

-- priority 2 so this wins over the generic "([a-zA-Z])bar" accent rule
snip("hbar", t([[\hbar]]), { priority = 2, desc = "reduced Planck constant" })

snip("bra", fmta([[\bra{<>} <>]], { i(1), i(0) }))
snip("ket", fmta([[\ket{<>} <>]], { i(1), i(0) }))
snip("brk", fmta([[\braket{ <> | <> } <>]], { i(1), i(2), i(0) }))
snip("outer", fmta([[\ket{<>} \bra{<>} <>]], { i(1, "\\psi"), rep(1), i(0) }))
snip("comm", fmta([[\left[ <>, <> \right] <>]], { i(1, "A"), i(2, "B"), i(0) }), { desc = "commutator" })
snip("acomm", fmta([[\left\{ <>, <> \right\} <>]], { i(1, "A"), i(2, "B"), i(0) }),
  { desc = "anticommutator" })

-- Chemistry

snip("pu", fmta([[\pu{ <> }]], { i(1) }))
snip("cee", fmta([[\ce{ <> }]], { i(1) }))
snip("he4", t([[{}^{4}_{2}He ]]))
snip("he3", t([[{}^{3}_{2}He ]]))
snip("iso", fmta([[{}^{<>}_{<>}<>]], { i(1, "4"), i(2, "2"), i(3, "He") }))

-- Math environments

local ENVS = { "pmatrix", "bmatrix", "Bmatrix", "vmatrix", "Vmatrix", "matrix", "cases", "align", "array" }
local ENV_TRIGS = {
  pmatrix = "pmat",
  bmatrix = "bmat",
  Bmatrix = "Bmat",
  vmatrix = "vmat",
  Vmatrix = "Vmat",
  matrix = "matrix",
  cases = "cases",
  align = "align",
  array = "array",
}
for _, env in ipairs(ENVS) do
  snip(ENV_TRIGS[env], fmta(
    "\\begin{" .. env .. "}\n<>\n\\end{" .. env .. "}",
    { i(1) }
  ))
end

-- Identity matrix generator: "iden3" expands to a 3x3 identity matrix,
-- "iden5" to a 5x5 one, and so on.
snip("iden(%d)", f(function(_, parent)
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
end), { regex = true, desc = "N x N identity matrix" })

-- Theorem-like environments
--
-- These expand to amsthm environments (\begin{theorem}...\end{theorem},
-- etc.) rather than to Obsidian callouts. The document preamble must
-- declare each one, e.g. \newtheorem{theorem}{Theorem}; the "head"
-- snippet already loads the amsthm package but does not declare them,
-- since the numbering scheme (shared counters, per-section numbering,
-- theorem vs. definition style) is a per-document choice. Both a short
-- trigger (thm) and the full word (theorem) are provided for each kind.
-- Available outside math mode, since these are block-level constructs.
local THEOREMS = {
  { "thm", "theorem",     "theorem" },
  { "lem", "lemma",       "lemma" },
  { "prp", "proposition", "proposition" },
  { "cor", "corollary",   "corollary" },
  { "def", "definition",  "definition" },
  { "exm", "example",     "example" },
  { "rmk", "remark",      "remark" },
  { "clm", "claim",       "claim" },
  { "cnj", "conjecture",  "conjecture" },
  { "hyp", "hypothesis",  "hypothesis" },
  { "axm", "axiom",       "axiom" },
  { "asm", "assumption",  "assumption" },
  { "exr", "exercise",    "exercise" },
}
for _, entry in ipairs(THEOREMS) do
  local short, long, env = entry[1], entry[2], entry[3]
  local function body()
    return fmta(
      "\\begin{" .. env .. "}[<>]\n<>\n\\end{" .. env .. "}",
      { i(1, "title"), i(2) }
    )
  end
  snip(short, body(), { cond = false, desc = env .. " environment" })
  snip(long, body(), { cond = false, desc = env .. " environment" })
end

-- Delimiters

snip("avg", fmta([[\langle <> \rangle <>]], { i(1), i(0) }))
snip("norm", fmta([[\lvert <> \rvert <>]], { i(1), i(0) }), { priority = 1 })
snip("Norm", fmta([[\lVert <> \rVert <>]], { i(1), i(0) }), { priority = 1 })
snip("ceil", fmta([[\lceil <> \rceil <>]], { i(1), i(0) }))
snip("floor", fmta([[\lfloor <> \rfloor <>]], { i(1), i(0) }))
snip("mod", fmta([[|<>|<>]], { i(1), i(0) }))
snip("lr(", fmta([[\left( <> \right) <>]], { i(1), i(0) }))
snip("lr{", fmta([[\left\{ <> \right\} <>]], { i(1), i(0) }))
snip("lr[", fmta([[\left[ <> \right] <>]], { i(1), i(0) }))
snip("lr|", fmta([[\left| <> \right| <>]], { i(1), i(0) }))
snip("lra", fmta([[\left<< <> \right>> <>]], { i(1), i(0) }))

-- The bare "(", "[", "{" snippets from Latex Suite are omitted: they
-- conflict with any autopairs plugin (nvim-autopairs, mini.pairs).
-- Uncomment only if you don't use one.
-- snip("(", fmta([[(<>)]], { visual() }))
-- snip("[", fmta([[[<>]]], { visual() }))
-- snip("{", fmta([[{<>}]], { visual() }))

-- Linear algebra and combinatorics

simple({
  { "tp",       [[^{T}]] },
  { "rank",     [[\mathrm{rank}]] },
  { "ker",      [[\ker]] },
  { "span",     [[\span]] },
  { "cdts",     [[\cdots]] },
  { "vdts",     [[\vdots]] },
  { "diag",     [[\ddots]] },
  { "gcd",      [[\gcd]] },
  { "lcm",      [[\mathrm{lcm}]] },
  { "dim",      [[\dim]] },
  { "deg",      [[\deg]] },
  { "bigcup",   [[\bigcup]] },
  { "bigcap",   [[\bigcap]] },
  { "bigplus",  [[\bigoplus]] },
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
  { "EE",  [[\mathbb{E}]] },
  { "PP",  [[\mathbb{P}]] },
  { "FF",  [[\mathbb{F}]] },
  { "QQ",  [[\mathbb{Q}]] },
  { "var", [[\mathrm{Var}]] },
  { "cov", [[\mathrm{Cov}]] },
})

-- Logic and mathematical prose

simple({
  { "iff",       [[\iff]] },
  { "tq",        [[\text{ such that }]] },
  { "all",       [[\forall]] },
  { "cong",      [[\cong]] },
  { "aprx",      [[\approx]] },
  { "perp",      [[\perp]] },
  { "top",       [[\top]] },
  { "bot",       [[\bot]] },
  { "neg",       [[\neg]] },
  { "wedge",     [[\wedge]] },
  { "vee",       [[\vee]] },
  { "ssub",      [[\subset]] },
  { "ssup",      [[\supset]] },
  { "therefore", [[\therefore]] },
  { "because",   [[\because]] },
  { "Ra",        [[\Rightarrow]] },
  { "La",        [[\Leftarrow]] },
})

snip("amax", fmta([[\underset{<>}{\mathrm{argmax}} \; <>]], { i(1), i(0) }))
snip("amin", fmta([[\underset{<>}{\mathrm{argmin}} \; <>]], { i(1), i(0) }))
snip("bigo", fmta([[\mathcal{O}( <> )<>]], { i(1), i(0) }), { desc = "big-O notation" })

-- Preset expansions

snip("tayl", fmta(
  [[<>(<> + <>) = <>(<>) + <>'(<>)<> + <>''(<>) \frac{<>^{2}}{2!} + \dots<>]],
  {
    i(1, "f"), i(2, "x"), i(3, "h"),
    rep(1), rep(2),
    rep(1), rep(2), rep(3),
    rep(1), rep(2),
    rep(3),
    i(0),
  }
), { desc = "Taylor expansion" })

return M
