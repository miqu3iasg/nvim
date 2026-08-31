local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node

local function get_date()
  return os.date("%Y-%m-%d")
end

local function get_year()
  return os.date("%Y")
end

local function get_filename()
  local name = vim.fn.expand("%:t")
  return name ~= "" and name or "untitled.py"
end

local FIELD_WIDTH = 15

local function label(text)
  return text .. string.rep(" ", math.max(1, FIELD_WIDTH - #text))
end

local function build_header(_, _)
  local nodes = {
    t({ "#!/usr/bin/env python3", "# -*- coding: utf-8 -*-", '"""' }),
    t({ "", label("File:") }),
    f(get_filename, {}),
    t({ "", label("Author:") }),
    i(1, "Miquéias Medeiros"),
    t({ "", label("Created:") }),
    f(get_date, {}),
    t({ "", label("Modified:") }),
    f(get_date, {}),
    t({ "", "", "" }),
    t(label("Description:")),
    t({ "", "    " }),
    i(2, "Longer description, if needed."),
    t({ "", "", "" }),
    t(label("Problem Statement:")),
    t({ "", "    " }),
    i(3, "Paste the exercise/assignment text here."),
    t({ "", "", "" }),
    t(label("Usage:")),
    t({
      "",
      "    Run from the directory containing this file.",
      "",
      "    `$ python ",
    }),
    f(get_filename, {}),
    t({ "`", "", "" }),
    t(label("References:")),
    t({ "", "    - " }),
    i(4, "https://..."),
    t({ "", "", "" }),
    t("SPDX-License-Identifier: MIT"),
    t({ "", label("Copyright:") }),
    t("\194\169 "),
    f(get_year, {}),
    t(" All rights reserved."),
    t({ "", '"""', "", "" }),
    i(0),
  }

  return sn(nil, nodes)
end

return {
  -- Control flow

  s("if", {
    t("if "),
    i(1, "condition"),
    t({ ":", "" }),
    i(2),
  }),

  s("ife", {
    t("if "),
    i(1, "condition"),
    t({ ":", "" }),
    i(2),
    t({ "", "else:", "" }),
    i(3),
  }),

  s("ifel", {
    t("if "),
    i(1, "condition"),
    t({ ":", "" }),
    i(2),
    t({ "", "elif " }),
    i(3, "condition"),
    t({ ":", "" }),
    i(4),
    t({ "", "else:", "" }),
    i(5),
  }),

  s("for", {
    t("for "),
    i(1, "item"),
    t(" in "),
    i(2, "iterable"),
    t({ ":", "" }),
    i(3),
  }),

  s("fore", {
    t("for "),
    i(1, "item"),
    t(" in "),
    i(2, "iterable"),
    t({ ":", "" }),
    i(3),
    t({ "", "else:", "" }),
    i(4),
  }),

  s("forr", {
    t("for "),
    i(1, "i"),
    t(" in range("),
    i(2, "n"),
    t({ "):", "" }),
    i(3),
  }),

  s("forrr", {
    t("for "),
    i(1, "i"),
    t(" in range("),
    i(2, "start"),
    t(", "),
    i(3, "stop"),
    t({ "):", "" }),
    i(4),
  }),

  s("forstep", {
    t("for "),
    i(1, "i"),
    t(" in range("),
    i(2, "start"),
    t(", "),
    i(3, "stop"),
    t(", "),
    i(4, "step"),
    t({ "):", "" }),
    i(5),
  }),

  s("while", {
    t("while "),
    i(1, "condition"),
    t({ ":", "" }),
    i(2),
  }),

  s("break", {
    t("break"),
  }),

  s("continue", {
    t("continue"),
  }),

  s("match", {
    t("match "),
    i(1, "value"),
    t({ ":", "    case " }),
    i(2, "pattern"),
    t({ ":", "" }),
    i(3),
  }),

  s("matche", {
    t("match "),
    i(1, "value"),
    t({ ":", "    case " }),
    i(2, "pattern"),
    t({ ":", "" }),
    i(3),
    t({ "    case " }),
    i(4, "pattern"),
    t({ ":", "" }),
    i(5),
    t({ "    case _:", "" }),
    i(6),
  }),

  -- Error handling

  s("try", {
    t({ "try:", "" }),
    i(1),
    t({ "", "except " }),
    i(2, "Exception"),
    t({ ":", "" }),
    i(3),
  }),

  s("trye", {
    t({ "try:", "" }),
    i(1),
    t({ "", "except " }),
    i(2, "Exception"),
    t({ ":", "" }),
    i(3),
    t({ "", "else:", "" }),
    i(4),
  }),

  s("tryf", {
    t({ "try:", "" }),
    i(1),
    t({ "", "except " }),
    i(2, "Exception"),
    t({ ":", "" }),
    i(3),
    t({ "", "finally:", "" }),
    i(4),
  }),

  s("tryall", {
    t({ "try:", "" }),
    i(1),
    t({ "", "except " }),
    i(2, "Exception"),
    t({ ":", "" }),
    i(3),
    t({ "", "else:", "" }),
    i(4),
    t({ "", "finally:", "" }),
    i(5),
  }),

  s("raise", {
    t("raise "),
    i(1, "Exception"),
    t("("),
    i(2, "message"),
    t(")"),
  }),

  s("assert", {
    t("assert "),
    i(1, "condition"),
    t(", "),
    i(2, "message"),
  }),

  -- Context managers

  s("with", {
    t("with "),
    i(1, "expression"),
    t(" as "),
    i(2, "variable"),
    t({ ":", "" }),
    i(3),
  }),

  s("withs", {
    t("with "),
    i(1, "expression"),
    t(" as "),
    i(2, "variable"),
    t(", "),
    i(3, "expression"),
    t(" as "),
    i(4, "variable"),
    t({ ":", "" }),
    i(5),
  }),

  s("asyncwith", {
    t("async with "),
    i(1, "expression"),
    t(" as "),
    i(2, "variable"),
    t({ ":", "" }),
    i(3),
  }),

  -- Functions

  s("def", {
    t("def "),
    i(1, "function"),
    t("("),
    i(2),
    t({ "):", "" }),
    i(3),
  }),

  s("deft", {
    t("def "),
    i(1, "function"),
    t("("),
    i(2),
    t(") -> "),
    i(3, "None"),
    t({ ":", "" }),
    i(4),
  }),

  s("async", {
    t("async def "),
    i(1, "function"),
    t("("),
    i(2),
    t({ "):", "" }),
    i(3),
  }),

  s("asynct", {
    t("async def "),
    i(1, "function"),
    t("("),
    i(2),
    t(") -> "),
    i(3, "None"),
    t({ ":", "" }),
    i(4),
  }),

  s("asyncfor", {
    t("async for "),
    i(1, "item"),
    t(" in "),
    i(2, "iterable"),
    t({ ":", "" }),
    i(3),
  }),

  s("lambda", {
    t("lambda "),
    i(1, "x"),
    t(": "),
    i(2, "expression"),
  }),

  s("ret", {
    t("return "),
    i(1),
  }),

  -- Main

  s("main", {
    t({ 'if __name__ == "__main__":', "" }),
    i(1),
  }),

  s("mainfn", {
    t({
      "def main():",
      "    ",
    }),
    i(1),
    t({
      "",
      "",
      'if __name__ == "__main__":',
      "    main()",
    }),
  }),

  -- Classes

  s("class", {
    t("class "),
    i(1, "ClassName"),
    t({ ":", "" }),
    i(2),
  }),

  s("classe", {
    t("class "),
    i(1, "ClassName"),
    t("("),
    i(2, "BaseClass"),
    t({ "):", "" }),
    i(3),
  }),

  s("init", {
    t("def __init__(self"),
    i(1),
    t({ "):", "" }),
    i(2),
  }),

  -- Properties / decorators

  s("prop", {
    t("@property"),
    t({ "", "def " }),
    i(1, "name"),
    t({ "(self):", "" }),
    i(2),
  }),

  s("setter", {
    t("@"),
    i(1, "property"),
    t({ ".setter", "", "def " }),
    i(2, "property"),
    t({ "(self, value):", "" }),
    i(3),
  }),

  s("property", {
    t("@property"),
    t({ "", "def " }),
    i(1, "name"),
    t({ "(self):", "    return self._" }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t({
      "",
      "",
      "@",
    }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t({ ".setter", "", "def " }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t({ "(self, value):", "    self._" }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" = value"),
  }),

  s("static", {
    t({
      "@staticmethod",
      "def ",
    }),
    i(1, "function"),
    t("("),
    i(2),
    t({ "):", "" }),
    i(3),
  }),

  s("classmeth", {
    t({
      "@classmethod",
      "def ",
    }),
    i(1, "function"),
    t("(cls"),
    i(2),
    t({ "):", "" }),
    i(3),
  }),

  -- Comprehensions

  s("list", {
    t("["),
    i(1, "expression"),
    t(" for "),
    i(2, "item"),
    t(" in "),
    i(3, "iterable"),
    t("]"),
  }),

  s("dict", {
    t("{"),
    i(1, "key"),
    t(": "),
    i(2, "value"),
    t("}"),
  }),

  s("set", {
    t("{"),
    i(1, "value"),
    t(" for "),
    i(2, "item"),
    t(" in "),
    i(3, "iterable"),
    t("}"),
  }),

  s("enum", {
    t("for "),
    i(1, "index"),
    t(", "),
    i(2, "item"),
    t(" in enumerate("),
    i(3, "iterable"),
    t({ "):", "" }),
    i(4),
  }),

  s("zip", {
    t("for "),
    i(1, "a"),
    t(", "),
    i(2, "b"),
    t(" in zip("),
    i(3, "iterable1"),
    t(", "),
    i(4, "iterable2"),
    t({ "):", "" }),
    i(5),
  }),

  -- Built-in functional patterns

  s("any", {
    t("any("),
    i(1, "condition"),
    t(" for "),
    i(2, "item"),
    t(" in "),
    i(3, "iterable"),
    t(")"),
  }),

  s("all", {
    t("all("),
    i(1, "condition"),
    t(" for "),
    i(2, "item"),
    t(" in "),
    i(3, "iterable"),
    t(")"),
  }),

  s("sorted", {
    t("sorted("),
    i(1, "iterable"),
    t(")"),
  }),

  s("sortkey", {
    t("sorted("),
    i(1, "iterable"),
    t(", key="),
    i(2, "key"),
    t(")"),
  }),

  s("ternary", {
    i(1, "value"),
    t(" if "),
    i(2, "condition"),
    t(" else "),
    i(3, "other"),
  }),

  -- Type hints

  s("ann", {
    i(1, "variable"),
    t(": "),
    i(2, "type"),
  }),

  s("union", {
    i(1, "Type"),
    t(" | "),
    i(2, "None"),
  }),

  s("optional", {
    t("Optional["),
    i(1, "type"),
    t("]"),
  }),

  -- Imports

  s("imp", {
    t("import "),
    i(1, "module"),
  }),

  s("impa", {
    t("import "),
    i(1, "module"),
    t(" as "),
    i(2, "alias"),
  }),

  s("from", {
    t("from "),
    i(1, "module"),
    t(" import "),
    i(2, "name"),
  }),

  s("froma", {
    t("from "),
    i(1, "module"),
    t(" import "),
    i(2, "name"),
    t(" as "),
    i(3, "alias"),
  }),

  -- Debugging

  s("print", {
    t("print("),
    i(1),
    t(")"),
  }),

  s("pprint", {
    t("from pprint import pprint"),
    t({ "", "pprint(" }),
    i(1, "object"),
    t(")"),
  }),

  s("debug", {
    t('print(f"'),
    i(1, "variable"),
    t(" = {"),
    i(2, "variable"),
    t('}")'),
  }),

  -- Dataclasses

  s("dataclass", {
    t({
      "from dataclasses import dataclass",
      "",
      "",
      "@dataclass",
      "class ",
    }),
    i(1, "ClassName"),
    t({ ":", "" }),
    i(2),
  }),

  s("dc", {
    t({
      "from dataclasses import dataclass",
      "",
      "",
      "@dataclass",
      "class ",
    }),
    i(1, "ClassName"),
    t({ ":", "    " }),
    i(2, "name: str"),
    t({ "", "    " }),
    i(3, "value: int"),
  }),

  -- Testing

  s("test", {
    t("def test_"),
    i(1, "name"),
    t({ "():", "" }),
    i(2),
  }),

  s("pytest", {
    t("def test_"),
    i(1, "name"),
    t({ "():", "" }),
    i(2),
  }),

  -- TODO / FIXME

  s("todo", {
    t("# TODO: "),
    i(1, "implement this"),
  }),

  s("fixme", {
    t("# FIXME: "),
    i(1, "fix this"),
  }),

  -- File header

  s("exs", {
    d(1, build_header, {}),
  }),
}
