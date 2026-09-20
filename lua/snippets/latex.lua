-- lua/snippets/latex.lua

-- LaTeX snippets for LuaSnip, ported from my personal snippet set of the
-- Obsidian Plugin Latex Suite.
--
-- The `where` option of `snip()` determines where a snippet can expand and
-- how it is triggered: `"math"` expands only inside math environments and
-- triggers automatically; `"text"` expands only outside math environments
-- and also triggers automatically; `"any"` expands globally, both inside
-- and outside math, but is not automatic, so the trigger must be typed and
-- followed by `<Tab>`.
--
-- Refs:
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
local ls_events = require("luasnip.util.events")

-- Math zone detection
--
-- Treesitter is tried first: vimtex's in_mathzone relies on the classic Vim
-- syntax engine and always returns 0 when treesitter highlighting is used.
-- When the parser does not see a formula (typically an unclosed \[ or \(
-- while typing, which yields an ERROR node), a cheap text-based check of
-- the delimiters is used instead. vimtex is the last resort, for when no
-- parser is installed.

local MATH_NODES = {
  math_environment = true,
  inline_formula = true,
  displayed_equation = true,
  display_formula = true,
}

-- Returns true/false, or nil when the treesitter parser is unavailable.
-- The second return value is true when the cursor is inside \text{...}.
local function ts_in_mathzone(row, col)
  local ok_parser, parser = pcall(vim.treesitter.get_parser, 0, "latex")
  if not ok_parser or not parser then
    return nil
  end
  parser:parse()

  -- Use the character before the cursor, where the trigger was just typed.
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

-- Returns the position of the last unescaped occurrence of `needle` in
-- `str` (plain search).
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

-- Text-based fallback check for \[ ... \] and \( ... \): returns true when
-- the nearest delimiter before the cursor is an opening one. Looks back at
-- most 200 lines to stay cheap.
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

-- Per-buffer cache: several snippets can ask for the math-zone condition on
-- the same keystroke, and the check itself is not free.
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

-- Snippet builder and helpers

local M = {}

-- Registry of plain (non-regex) automatic triggers, used by :SnipAudit to
-- find collisions (one trigger being a prefix/suffix of another).
local PLAIN = {}

-- Usage counters, used by :SnipUsage. Loaded from disk on startup (if a
-- previous session saved data) and written back on exit, so counts
-- accumulate across restarts instead of resetting every session.
local usage_file = vim.fn.stdpath("data") .. "/latex_snippet_usage.json"

local function load_usage()
  local ok, lines = pcall(vim.fn.readfile, usage_file)
  if not ok then
    return {}
  end
  local ok2, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if ok2 and type(decoded) == "table" then
    return decoded
  end
  return {}
end

local usage = load_usage()

vim.api.nvim_create_autocmd("VimLeavePre", {
  desc = "Persist LaTeX snippet usage counters",
  callback = function()
    pcall(vim.fn.writefile, { vim.json.encode(usage) }, usage_file)
  end,
})

local function add(snippet)
  M[#M + 1] = snippet
  return snippet
end

local WHERE = { math = in_mathzone, text = in_text, any = false }

--- Builds and registers a snippet.
---@param trig string           trigger string, or a Lua pattern when opts.regex is true
---@param nodes table|userdata  snippet body (a node, or a list of nodes)
---@param opts table|nil
---   where    "math"|"text"|"any"  where the snippet expands (default "math").
---            "math" and "text" snippets are automatic; "any" snippets are
---            expanded with <Tab>.
---   word     boolean  require a non-word character before the trigger
---            (default: false for automatic snippets, true for <Tab> ones)
---   regex    boolean  treat `trig` as a Lua pattern
---   priority number   resolves conflicts between overlapping triggers
---                     (LuaSnip default is 1000; higher wins)
---   desc     string   snippet description
---   check    function(captures, line_to_cursor, matched_trigger) -> boolean
---            extra condition, evaluated before the math/text check
---
--- Alphanumeric plain triggers (e.g. "cdot") never expand when directly
--- preceded by a backslash, so typing `\cdot` or `\gcd` by hand is safe.
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

  if auto and not opts.regex then
    PLAIN[#PLAIN + 1] = { trig = trig, prio = opts.priority or 1000, where = where, word = word }
  end

  return add(s({
    trig = trig,
    wordTrig = word,
    trigEngine = opts.regex and "pattern" or "plain",
    priority = opts.priority,
    desc = opts.desc,
    snippetType = auto and "autosnippet" or "snippet",
    hidden = auto, -- keep autosnippets out of the completion menu
  }, nodes, {
    condition = cond,
    show_condition = base,
    callbacks = {
      [-1] = {
        [ls_events.pre_expand] = function()
          usage[trig] = (usage[trig] or 0) + 1
        end,
      },
    },
  }))
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

--- check(): the trigger must not be glued to a letter or a backslash.
local function on_boundary(_, line, matched)
  local before = line:sub(#line - #matched, #line - #matched)
  return not before:match("[%a\\]")
end

--- check(): the match must not follow ^ or _ (avoids x^2/ -> x^\frac{2}{}).
local function not_script(_, line, matched)
  local before = line:sub(#line - #matched, #line - #matched)
  return before ~= "^" and before ~= "_"
end

--- check(): the trigger must be the first thing on the line (only
--- whitespace before it). Keeps block-environment triggers from firing
--- inside \label{thm:...}, \ref{lma:...} and similar.
local function line_start(_, line, matched)
  return line:sub(1, #line - #matched):match("^%s*$") ~= nil
end

--- check(): the trigger must not come right after "\math" (blocks "bf"/"rm"
--- from re-firing in the middle of a hand-typed \mathbf{} or \mathrm{}; the
--- plain backslash guard above only catches a trigger glued directly to a
--- backslash, not one a few letters into "\math...").
local function not_after_math(_, line, matched)
  return not line:sub(1, #line - #matched):match("\\math$")
end

--- Renders "[" or "]" only when insert node 1 has text in it, so an empty
--- optional argument (e.g. the theorem title) doesn't leave stray brackets.
local function bracket(open)
  return f(function(args)
    return args[1][1] ~= "" and (open and "[" or "]") or ""
  end, { 1 })
end

-- Global snippets ("any"): not automatic, expanded with <Tab>

-- Theorem-like environments: { trigger, environment, Portuguese name, style }.
-- Ordered by style, because the preamble generator emits \theoremstyle
-- whenever the style changes. The first entry owns the shared counter.
local THEOREMS = {
  { "thm", "theorem",     "Teorema",    "plain" },
  { "lma", "lemma",       "Lema",       "plain" },
  { "prp", "proposition", "Proposição", "plain" },
  { "crl", "corollary",   "Corolário",  "plain" },
  { "clm", "claim",       "Afirmação",  "plain" },
  { "cnj", "conjecture",  "Conjectura", "plain" },
  { "hpt", "hypothesis",  "Hipótese",   "plain" },
  { "dfn", "definition",  "Definição",  "definition" },
  { "exm", "example",     "Exemplo",    "definition" },
  { "axm", "axiom",       "Axioma",     "definition" },
  { "asn", "assumption",  "Suposição",  "definition" },
  { "exr", "exercise",    "Exercício",  "definition" },
  { "rmk", "remark",      "Observação", "remark" },
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

-- Generic environment (also useful inside math: cases, matrices, ...).
snip("bg", fmta([[
\begin{<>}
<>
\end{<>}
]], { i(1), i(2), rep(1) }), { where = "any", desc = "begin/end environment" })

-- \label goes inside equation/align, which the detector classifies as math,
-- so it has to work in both places.
snip("lb", fmta("\\label{<>}", { i(1) }), { where = "any", desc = "label" })

-- Text snippets: automatic, only outside math

--- Block-level text snippet: must be the first thing on the line.
local function block(trig, nodes, desc)
  return snip(trig, nodes, { where = "text", word = true, check = line_start, desc = desc })
end

--- Inline text snippet: must start a word.
local function inline(trig, nodes, desc)
  return snip(trig, nodes, { where = "text", word = true, desc = desc })
end

-- Inline and display math (with visual selection support).
inline("mk", fmta("$<>$<>", { visual(), i(0) }), "inline math")
inline("dm", fmta("\\[\n  <>\n\\]<>", { visual(), i(0) }), "display math")
inline("pmk", fmta("\\(<>\\)<>", { visual(), i(0) }), "inline math with \\( \\)")

-- Environments and sectioning. They are block-level, so they only fire as
-- the first thing on a line.
block("fll", fmta("\\begin{flushleft}\n<>\n\\end{flushleft}", { i(1, "content") }),
  "flushleft environment")
block("eqn", fmta("\\begin{equation}\n  <>\n\\end{equation}", { i(1) }), "equation")
block("gtr", fmta("\\begin{gather*}\n  <>\n\\end{gather*}", { i(1) }), "gather*")
block("als", fmta("\\begin{align*}\n  <>\n\\end{align*}", { i(1) }), "align*")
block("aln", fmta("\\begin{align}\n  <>\n\\end{align}", { i(1) }), "align")
block("enm", fmta("\\begin{enumerate}\n  \\item <>\n\\end{enumerate}", { i(1) }), "enumerate")
block("blt", fmta("\\begin{itemize}\n  \\item <>\n\\end{itemize}", { i(1) }), "itemize")
block("itm", t("\\item "), "item")
block("fgr", fmta(
  "\\begin{figure}[<>]\n  \\centering\n  \\includegraphics[width=<>\\textwidth]{<>}\n"
  .. "  \\caption{<>}\n  \\label{fig:<>}\n\\end{figure}",
  { i(1, "htbp"), i(2, "0.8"), i(3), i(4), i(5) }
), "figure")

block("sct", fmta("\\section{<>}", { i(1) }), "section")
block("ssct", fmta("\\subsection{<>}", { i(1) }), "subsection")
block("sssct", fmta("\\subsubsection{<>}", { i(1) }), "subsubsection")

-- Theorem-like environments. The triggers are consonant clusters that are
-- not Portuguese/English words. They only fire as the first thing on a
-- line, so \label{thm:...} and \ref{lma:...} never trigger an environment.
-- The preamble generated by "head" declares every one of them. The title
-- brackets only render once you actually type a title (via bracket()), so
-- you no longer have to delete a placeholder to get an untitled theorem.
for _, th in ipairs(THEOREMS) do
  local env = th[2]
  block(th[1], fmta(
    "\\begin{" .. env .. "}<><><>\n  <>\n\\end{" .. env .. "}",
    { bracket(true), i(1), bracket(false), i(2) }
  ), env .. " environment")
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

-- Special letters (calligraphic and blackboard bold). In math they insert
-- just the command (\mathbb{R}); in text they wrap it in $...$.
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

-- Generic form of the letters above: any letter after "bb"/"cl"/"fk"
-- becomes \mathbb{}/\mathcal{}/\mathfrak{}, so you're not stuck with only
-- the ones that have their own two-letter shortcut.
for trig, cmd in pairs({ bb = "mathbb", cl = "mathcal", fk = "mathfrak" }) do
  snip(trig .. "(%a)", f(function(_, p) return "\\" .. cmd .. "{" .. p.captures[1] .. "}" end),
    { regex = true, check = on_boundary })
end

snip("...", t([[\dots]]), { where = "math" })
snip("...", t([[\dots]]), { where = "text", desc = "ellipsis (text)" })

snip("qed", t([[\tag*{\(\blacksquare\)}]]), { where = "math" })
snip("qed", t([[\hfill\(\blacksquare\)]]),
  { where = "text", word = true, desc = "end of proof (text)" })

-- Math snippets: automatic, only inside math

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
-- ("alpha", "sin", ...) prepends the backslash. A single snippet matches the
-- whole letter run and looks it up in a table, which is much cheaper than
-- one regex snippet per word. Because the whole run is compared,
-- "varepsilon" is never read as "var" + "epsilon", and "arcsin" is never
-- read as "sin". "xi" is intentionally absent: it would make the "xii"
-- (x_{i}) snippet unreachable; use "@x" for \xi. "sup", "inf" and "partial"
-- are intentionally absent too: they collide with "sup=", "infi" and the
-- "pa.." partial-derivative snippet. Words containing "dot" (ddots, vdots)
-- are absent as well, since the "dot" accent fires before the full word is
-- typed.
--
-- No other trigger in this file may be a prefix of one of these words,
-- because an automatic snippet fires as soon as its trigger is typed.
local BACKSLASH_WORDS = {}
for _, w in ipairs({
  -- Greek letters
  "alpha", "beta", "gamma", "Gamma", "delta", "Delta", "epsilon", "varepsilon",
  "zeta", "eta", "theta", "Theta", "vartheta", "iota", "kappa", "lambda",
  "Lambda", "mu", "nu", "Xi", "pi", "Pi", "rho", "varrho", "sigma",
  "Sigma", "tau", "upsilon", "Upsilon", "phi", "Phi", "varphi", "chi",
  "psi", "Psi", "omega", "Omega",
  -- functions
  "exp", "log", "ln", "det", "arcsin", "arccos", "arctan",
  "sin", "cos", "tan", "csc", "sec", "cot",
  "sinh", "cosh", "tanh", "coth",
  "max", "min", "arg",
  -- misc symbols and operators
  "hbar", "ell", "infty", "forall", "exists", "leq", "geq", "neq",
  "approx", "equiv", "times", "cup", "cap", "subset", "supset",
  "subseteq", "supseteq", "implies",
}) do
  BACKSLASH_WORDS[w] = true
end

snip("(%a+)", f(function(_, parent)
  return "\\" .. parent.captures[1]
end), {
  regex = true,
  desc = "backslash before Greek letters and function names",
  check = function(captures, line)
    local run = captures[1]
    if not run or not BACKSLASH_WORDS[run] then
      return false
    end
    return line:sub(#line - #run, #line - #run) ~= "\\"
  end,
})

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
snip("stx", fmta([[_\text{<>}]], { i(1) }))
snip("sq", fmta([[\sqrt{ <> }<>]], { visual(), i(0) }),
  { desc = "square root (wraps the selection)" })
snip("//", fmta([[\frac{<>}{<>}<>]], { i(1), i(2), i(0) }))
snip("ee", fmta([[e^{ <> }<>]], { i(1), i(0) }))
snip("bf", fmta([[\mathbf{<>}]], { i(1) }), { check = not_after_math })
snip("bxd", fmta([[\boxed{<>}<>]], { i(1), i(0) }))
snip("tag", fmta([[\tag{<>}<>]], { i(1), i(0) }))
snip("rm", fmta([[\mathrm{<>}<>]], { i(1), i(0) }), { check = not_after_math })

-- Smart fractions: typing "/" right after a numerator turns it into
-- \frac{numerator}{|}, with the cursor in the denominator.
--   2/  ->  \frac{2}{|}          3.5/  ->  \frac{3.5}{|}
--   x/  ->  \frac{x}{|}          \alpha/  ->  \frac{\alpha}{|}
--   x_{i}/  ->  \frac{x_{i}}{|}  (a+b)/  ->  \frac{a+b}{|}
local function frac(numerator)
  return { t([[\frac{]]), numerator, t("}{"), i(1), t("}"), i(0) }
end

snip([[(%d+%.?%d*)/]], frac(cap(1)),
  { regex = true, check = not_script, desc = "fraction from number" })
snip([[(%d*\?%a+)/]], frac(cap(1)),
  { regex = true, check = not_script, desc = "fraction from symbol" })
snip([[(%d*\?%a+[_^]%b{})/]], frac(cap(1)),
  { regex = true, desc = "fraction from symbol with script" })
snip([[(%b())/]], frac(f(function(_, parent)
  return parent.captures[1]:sub(2, -2)
end)), { regex = true, desc = "fraction from parenthesized expression" })

-- Fixes "_{1}0" (a digit typed right after a closed subscript) into
-- "_{10}", merging the trailing digit into the existing braces instead of
-- leaving it outside them.
snip([[_{(%d+)}(%d)]], f(function(_, p)
  return "_{" .. p.captures[1] .. p.captures[2] .. "}"
end), { regex = true, desc = "x_{1}0 -> x_{10}" })

-- Automatic subscripting: a letter directly followed by one digit becomes
-- letter_{digit} (e.g. "x1" -> "x_{1}"); negative priority lets more
-- specific rules win when they overlap. (Longer subscripts such as "x_12"
-- are handled by the "_" snippet above, which fires first.)
snip("([A-Za-z])(%d)", { cap(1), t("_{"), cap(2), t("}") }, {
  regex = true,
  priority = -1,
  desc = "automatic subscript",
})

-- \hat{x}1, \vec{x}1, \mathbf{x}1 -> \hat{x}_{1}, ...
local SUBSCRIPTABLE = { hat = true, vec = true, mathbf = true }
snip([[\(%a+){([A-Za-z])}(%d)]], f(function(_, parent)
  local c = parent.captures
  return "\\" .. c[1] .. "{" .. c[2] .. "}_{" .. c[3] .. "}"
end), {
  regex = true,
  desc = "subscript after accented letter",
  check = function(captures)
    return SUBSCRIPTABLE[captures[1]] == true
  end,
})

simple({
  { "xnn", [[x_{n}]] },
  { "xii", [[x_{i}]] },
  { "xjj", [[x_{j}]] },
  { "xp1", [[x_{n+1}]] },
  { "ynn", [[y_{n}]] },
  { "yii", [[y_{i}]] },
  { "yjj", [[y_{j}]] },
})

-- Accents
--
-- "xhat" -> \hat{x}, "ybar" -> \bar{y}, ... A single snippet matches the
-- whole letter run (one letter + accent name). "cdot" and "ddot" are
-- excluded from this rule: they are handled by their own snippets. "hbar"
-- is excluded too: it's a physics constant, not "h" + \bar, and is handled
-- by the BACKSLASH_WORDS rule above (priority 1000 beats this rule's -1).
local ACCENTS = {
  hat = "hat",
  bar = "bar",
  ddot = "ddot",
  tilde = "tilde",
  und = "underline",
  vec = "vec",
  dot = "dot",
}

snip("(%a)(%a+)", f(function(_, parent)
  local c = parent.captures
  return "\\" .. ACCENTS[c[2]] .. "{" .. c[1] .. "}"
end), {
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
})

-- Accent commands on their own (word start), wrapping a placeholder.
for name, cmd in pairs(ACCENTS) do
  snip(name, fmta("\\" .. cmd .. "{<>}<>", { i(1), i(0) }), { word = true })
end
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
-- ("...", "qed" and the special letters LL, HH, CC, ... are in the twins
-- section above. "exists" moved to BACKSLASH_WORDS: it collided with
-- "sts"/"stx".)
simple({
  { "ooo",   [[\infty]] },
  { "+-",    [[\pm]] },
  { "-+",    [[\mp]] },
  { "nabl",  [[\nabla]] },
  { "xx",    [[\times]] },
  { "**",    [[\cdot]] },
  { "prl",   [[\parallel]] },
  { "===",   [[\equiv]] },
  { "!=",    [[\neq]] },
  { ">=",    [[\geq]] },
  { "<=",    [[\leq]] },
  { ">>",    [[\gg]] },
  { "<<",    [[\ll]] },
  { "simm",  [[\sim]] },
  { "sim=",  [[\simeq]] },
  { "prop",  [[\propto]] },
  { "->",    [[\to]] },
  { "!>",    [[\mapsto]] },
  { "=>",    [[\implies]] },
  { "=<",    [[\impliedby]] },
  { "orr",   [[\cup]] },
  { "inn",   [[\in]] },
  { "notin", [[\not\in]] },
  -- three literal backslashes
  { [[\\\]], [[\setminus]] },
  { "sub=",  [[\subseteq]] },
  { "sup=",  [[\supseteq]] },
  -- vector calculus and algebra
  { "dag",   [[^{\dagger}]] },
  { "o+",    [[\oplus ]] },
  { "div",   [[\nabla \cdot ]] },
  { "curl",  [[\nabla \times ]] },
  { "lap",   [[\nabla^{2} ]] },
})
-- "->" is a suffix of "<->": the longer trigger must win.
snip("<->", t([[\leftrightarrow ]]), { priority = 1100 })

-- Word-boundary triggers: they must not fire in the middle of a longer
-- command such as \land, \forall or \pmatrix typed by hand.
snip("andd", t([[\cap]]), { word = true })
snip("fal", t([[\forall]]), { word = true })
snip("ox", t([[\otimes ]]), { word = true })

snip("eset", t([[\emptyset]]), { priority = 1 })
snip("sett", fmta([[\{ <> \}<>]], { i(1), i(0) }), { word = true })

snip("sum", fmta([[\sum_{<>=<>}^{<>} <>]], { i(1, "i"), i(2, "1"), i(3, "N"), i(0) }),
  { desc = "sum with bounds" })
snip("prod", fmta([[\prod_{<>=<>}^{<>} <>]], { i(1, "i"), i(2, "1"), i(3, "N"), i(0) }),
  { desc = "product with bounds" })
snip("lim", fmta([[\lim_{ <> \to <> } <>]], { i(1, "n"), i(2, [[\infty]]), i(0) }))

-- Derivatives and integrals
--
-- Triggers whose tail is another trigger ("ddv" ends in "dv", "ppd" and
-- "mpd" end in "pd", "iiint" ends in "iint") get a higher priority so the
-- longer one wins.
snip("apl", fmta([[\left. <> \right|_{<>}^{<>} <>]], { i(1), i(2, "a"), i(3, "b"), i(0) }))
snip("ev", fmta([[\left. <> \right|_{<> = <>}]], { i(1), i(2, "x"), i(3, "a") }))
snip("pd", fmta([[\frac{ \partial <> }{ \partial <> } <>]], { i(1, "y"), i(2, "x"), i(0) }))
snip("pa([A-Za-z])([A-Za-z])",
  { t([[\frac{ \partial ]]), cap(1), t([[ }{ \partial ]]), cap(2), t(" } ") },
  { regex = true, check = on_boundary })
snip("ddt", t([[\frac{d}{dt} ]]))
snip("dv", fmta([[\frac{d<>}{d<>} <>]], { i(1, "y"), i(2, "x"), i(0) }),
  { desc = "ordinary derivative (Leibniz notation)" })
snip("ddv", fmta([[\frac{d^{2}<>}{d<>^{2}} <>]], { i(1, "y"), i(2, "x"), i(0) }),
  { priority = 1100, desc = "second ordinary derivative" })
snip("ppd", fmta([[\frac{\partial^{2} <>}{\partial <>^{2}} <>]], { i(1, "f"), i(2, "x"), i(0) }),
  { priority = 1100, desc = "second partial derivative" })
snip("mpd", fmta([[\frac{\partial^{2} <>}{\partial <> \partial <>} <>]],
    { i(1, "f"), i(2, "x"), i(3, "y"), i(0) }),
  { priority = 1100, desc = "mixed partial derivative" })

-- A bare "int" (not preceded by a letter or backslash) expands directly
-- into the full template, with placeholders for the integrand and the
-- differential variable.
snip("([^%a\\])int", { cap(1), t([[\int ]]), i(1), t([[ \, d]]), i(2, "x"), t(" "), i(0) },
  { regex = true, priority = -1 })
snip("dint", fmta([[\int_{<>}^{<>} <> \, d<> <>]], { i(1, "0"), i(2, "1"), i(3), i(4, "x"), i(0) }))
snip("oinf", fmta([[\int_{0}^{\infty} <> \, d<> <>]], { i(1), i(2, "x"), i(0) }))
snip("infi", fmta([[\int_{-\infty}^{\infty} <> \, d<> <>]], { i(1), i(2, "x"), i(0) }))

simple({
  { "oint", [[\oint]] },
  { "iint", [[\iint]] },
})
snip("iiint", t([[\iiint]]), { priority = 1100 })

-- Visual operations
--
-- These wrap the current visual selection (or an empty placeholder, if
-- nothing was selected). Select the text, press <Tab> (store_selection_keys
-- in luasnip.setup()), then type the trigger.
snip("ubr", fmta([[\underbrace{ <> }_{ <> }]], { visual(), i(2) }),
  { desc = "underbrace" })
snip("obr", fmta([[\overbrace{ <> }^{ <> }]], { visual(), i(2) }),
  { desc = "overbrace" })
snip("ust", fmta([[\underset{ <> }{ <> }]], { i(2), visual() }),
  { desc = "underset" })
snip("cnc", fmta([[\cancel{ <> }]], { visual() }),
  { desc = "cancel" })
snip("cto", fmta([[\cancelto{ <> }{ <> }]], { i(2), visual() }),
  { desc = "cancelto" })

-- Math environments
local MATH_ENVS = {
  { "pmat",   "pmatrix" },
  { "bmat",   "bmatrix" },
  { "Bmat",   "Bmatrix" },
  { "vmat",   "vmatrix" },
  { "Vmat",   "Vmatrix" },
  { "matrix", "matrix" },
  { "cases",  "cases" },
  { "array",  "array" },
}
for _, e in ipairs(MATH_ENVS) do
  snip(e[1], fmta(
    "\\begin{" .. e[2] .. "}\n<>\n\\end{" .. e[2] .. "}",
    { i(1) }
  ), { word = true })
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
  { "span",     [[\operatorname{span}]] },
  { "cdts",     [[\cdots]] },
  { "vdts",     [[\vdots]] },
  { "dgts",     [[\ddots]] }, -- "ddts" would be shadowed by "ddt"
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
-- (EE, PP, FF, QQ are in the twins section above.) "Var" is capitalized
-- because "var" is a prefix of "varphi", "varrho", ... and would fire in
-- the middle of them.
simple({
  { "Var", [[\mathrm{Var}]] },
  { "Cov", [[\mathrm{Cov}]] },
})

-- Logic and mathematical prose
-- ("vee" moved out: it tied with "ee" at priority 1000 and needs to win.)
simple({
  { "iff",     [[\iff]] },
  { "tq",      [[\text{ tal que }]] },
  { "cong",    [[\cong]] },
  { "aprx",    [[\approx]] },
  { "perp",    [[\perp]] },
  { "top",     [[\top]] },
  { "bot",     [[\bot]] },
  { "neg",     [[\neg]] },
  { "wedge",   [[\wedge]] },
  { "ssub",    [[\subset]] },
  { "ssup",    [[\supset]] },
  { "because", [[\because]] },
  { "Rar",     [[\Rightarrow]] },
  { "Lar",     [[\Leftarrow]] }, -- "La" would fire in the middle of "Lambda"
})
snip("vee", t([[\vee]]), { priority = 1100 })

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

-- Maintenance commands

-- You can use the :SnipAudit and :SnipUsage commands to check the health status of the snippets.
vim.api.nvim_create_user_command("SnipAudit", function()
  local out = {}
  for _, a in ipairs(PLAIN) do
    for _, b in ipairs(PLAIN) do
      if a ~= b and a.where == b.where and #b.trig < #a.trig then
        local at = #a.trig - #b.trig
        -- b is a suffix of a: once you finish typing a, both match
        if a.trig:sub(at + 1) == b.trig and b.prio >= a.prio
            and not (b.word and a.trig:sub(at, at):match("[%w_]")) then
          out[#out + 1] = ("%q loses to %q (suffix, priority %d >= %d)"):format(a.trig, b.trig, b.prio, a.prio)
        end
        -- b is a prefix of a: b fires before you finish typing a
        if a.trig:sub(1, #b.trig) == b.trig then
          out[#out + 1] = ("%q is unreachable: %q fires first"):format(a.trig, b.trig)
        end
      end
    end
  end
  vim.notify(#out == 0 and "no collisions found" or table.concat(out, "\n"))
end, {})

vim.api.nvim_create_user_command("SnipUsage", function()
  local rows = {}
  for k, n in pairs(usage) do
    rows[#rows + 1] = { k, n }
  end
  table.sort(rows, function(a, b) return a[2] > b[2] end)
  local out = {}
  for _, r in ipairs(rows) do
    out[#out + 1] = ("%5d  %s"):format(r[2], r[1])
  end
  vim.notify(#out == 0 and "no usage data yet" or table.concat(out, "\n"))
end, {})

return M
