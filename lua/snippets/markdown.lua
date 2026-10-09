-- lua/snippets/markdown.lua

local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local c = ls.choice_node

-- Helpers

-- Date in ISO format (used in front matter and "date")
local function today()
  return os.date("%Y-%m-%d")
end

-- Current date and time (used in front matter timestamps)
local function now()
  return os.date("%Y-%m-%d %H:%M")
end

-- Name of the current file, including extension
local function get_filename()
  local name = vim.fn.expand("%:t")
  return name ~= "" and name or "Untitled"
end

-- Generates a heading snippet: h1 -> "# ", h2 -> "## ", etc.
local function heading(level)
  return s("h" .. level, {
    t(string.rep("#", level) .. " "),
    i(1, "Title"),
    i(0),
  })
end

-- Generates a fenced code block with a fixed language
local function codeblock(trig, lang)
  return s(trig, {
    t("```" .. lang),
    t({ "", "" }),
    i(1),
    t({ "", "```" }),
    i(0),
  })
end

-- Dynamic table: typing `tbl3x2` expands to a table with 3 columns
-- and 2 body rows. Placeholders are numbered so <Tab> walks the cells
local function dynamic_table(_, snip)
  local cols = tonumber(snip.captures[1])
  local rows = tonumber(snip.captures[2])
  local nodes = {}
  local idx = 1

  local function add_row(placeholder)
    nodes[#nodes + 1] = t("| ")
    for col = 1, cols do
      nodes[#nodes + 1] = i(idx, placeholder .. " " .. col)
      idx = idx + 1
      nodes[#nodes + 1] = t(col < cols and " | " or " |")
    end
  end

  -- Header
  add_row("Header")

  -- Separator
  local sep = { "", "|" }
  for _ = 1, cols do
    sep[2] = sep[2] .. " --- |"
  end
  nodes[#nodes + 1] = t(sep)

  -- Body rows
  for _ = 1, rows do
    nodes[#nodes + 1] = t({ "", "" })
    add_row("Cell")
  end

  nodes[#nodes + 1] = i(0)
  return sn(nil, nodes)
end

-- Snippets

local snippets = {

  -- Tables

  -- Default 3x2 table
  s("tbl", {
    t("| "), i(1, "Header 1"), t(" | "), i(2, "Header 2"), t(" | "), i(3, "Header 3"), t(" |"),
    t({ "", "| --- | --- | --- |" }),
    t({ "", "| " }), i(4, "Cell"), t(" | "), i(5, "Cell"), t(" | "), i(6, "Cell"), t(" |"),
    t({ "", "| " }), i(7, "Cell"), t(" | "), i(8, "Cell"), t(" | "), i(9, "Cell"), t(" |"),
    i(0),
  }),

  -- Custom size: tbl<cols>x<rows>, e.g. tbl4x5.
  s({ trig = "tbl(%d+)x(%d+)", regTrig = true, hidden = true }, {
    d(1, dynamic_table, {}),
  }),

  -- Code blocks

  -- Generic fenced block with a language placeholder
  s("cb", {
    t("```"),
    i(1, "lang"),
    t({ "", "" }),
    i(2),
    t({ "", "```" }),
    i(0),
  }),

  -- Inline code
  s("ic", { t("`"), i(1, "code"), t("`"), i(0) }),

  -- Language-specific blocks
  codeblock("cbbash", "bash"),
  codeblock("cbsh", "sh"),
  codeblock("cblua", "lua"),
  codeblock("cbc", "c"),
  codeblock("cbjava", "java"),
  codeblock("cbpy", "python"),
  codeblock("cbscm", "scheme"),
  codeblock("cbjson", "json"),
  codeblock("cbyaml", "yaml"),
  codeblock("cbsql", "sql"),
  codeblock("cbhtml", "html"),
  codeblock("cbcss", "css"),
  codeblock("cbdiff", "diff"),

  -- Mermaid diagram
  s("mermaid", {
    t({ "```mermaid", "" }),
    c(1, {
      t("flowchart TD"),
      t("sequenceDiagram"),
      t("classDiagram"),
      t("erDiagram"),
      t("gantt"),
    }),
    t({ "", "    " }),
    i(2),
    t({ "", "```" }),
    i(0),
  }),

  -- Comments

  -- Single-line HTML comment.
  s("cm", { t("<!-- "), i(1, "comment"), t(" -->"), i(0) }),

  -- Multi-line HTML comment.
  s("cmm", {
    t({ "<!--", "" }),
    i(1, "comment"),
    t({ "", "-->" }),
    i(0),
  }),

  -- Reference-style comment, never makes it into the rendered output,
  -- not even as an HTML comment in the source
  s("cmr", { t("[//]: # ("), i(1, "comment"), t(")"), i(0) }),

  -- Common annotation markers
  s("todoc", { t("<!-- TODO: "), i(1, "description"), t(" -->"), i(0) }),

  -- Text formatting
  s("bd", { t("**"), i(1, "text"), t("**"), i(0) }),
  s("it", { t("*"), i(1, "text"), t("*"), i(0) }),
  s("bi", { t("***"), i(1, "text"), t("***"), i(0) }),
  s("st", { t("~~"), i(1, "text"), t("~~"), i(0) }),
  s("kbd", { t("<kbd>"), i(1, "Ctrl"), t("</kbd>"), i(0) }),

  -- Links, images, references
  s("link", { t("["), i(1, "text"), t("]("), i(2, "https://"), t(")"), i(0) }),
  s("img", { t("!["), i(1, "alt text"), t("]("), i(2, "path/to/image.png"), t(")"), i(0) }),
  s("ref", { t("["), i(1, "text"), t("]["), i(2, "id"), t("]"), i(0) }),
  s("refdef", { t("["), i(1, "id"), t("]: "), i(2, "https://"), i(0) }),
  s("fn", {
    t("[^"), i(1, "1"), t("]"),
    t({ "", "", "[^" }), f(function(args) return args[1][1] end, { 1 }), t("]: "),
    i(2, "Footnote text."),
    i(0),
  }),

  -- Lists and quotes

  -- Task list with three items
  s("task", {
    t("- [ ] "), i(1, "Task"),
    t({ "", "- [ ] " }), i(2, "Task"),
    t({ "", "- [ ] " }), i(3, "Task"),
    i(0),
  }),

  -- Numbered list with three items
  s("ol", {
    t("1. "), i(1, "Item"),
    t({ "", "2. " }), i(2, "Item"),
    t({ "", "3. " }), i(3, "Item"),
    i(0),
  }),

  -- Bullet list with one nested level
  s("ul", {
    t("- "), i(1, "Item"),
    t({ "", "  - " }), i(2, "Sub-item"),
    t({ "", "- " }), i(3, "Item"),
    i(0),
  }),

  s("qt", { t("> "), i(1, "Quote"), i(0) }),
  s("hr", { t({ "---", "" }), i(0) }),

  -- GitHub-style callouts
  s("callout", {
    t("> [!"),
    c(1, {
      t("NOTE"),
      t("TIP"),
      t("IMPORTANT"),
      t("WARNING"),
      t("CAUTION"),
    }),
    t({ "]", "> " }),
    i(2, "Content."),
    i(0),
  }),

  -- Misc

  -- YAML front matter, file_name
  s("front", {
    t({ "---", "file_name: " }),
    f(get_filename, {}),
    t({ "", "summary: " }),
    i(1),
    t({ "", "authors: " }),
    i(2),
    t({ "", "source_title: " }),
    i(3),
    t({ "", "source_location: " }),
    i(4),
    t({ "", "source_url: " }),
    i(5),
    t({ "", "related: " }),
    i(6),
    t({ "", "" }),
    d(7, function()
      local ts = now()
      return sn(nil, {
        t({ "created_at: " .. ts, "modified_at: " .. ts, "---", "", "" }),
      })
    end, {}),
    i(0),
  }),

  -- Math blocks (KaTeX / MathJax)
  s("math", { t("$"), i(1, "x"), t("$"), i(0) }),
  s("mathb", {
    t({ "$$", "" }),
    i(1, "E = mc^2"),
    t({ "", "$$" }),
    i(0),
  }),

  -- Insert today's date
  s("date", { f(today, {}) }),
}

-- Headings h1..h6
for level = 1, 6 do
  table.insert(snippets, heading(level))
end

return snippets
