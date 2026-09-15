-- lua/snippets/c.lua

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s("ivm", {
    t({
      "#include <stdio.h>",
      "",
      "int main(void) {",
      "    ",
    }),
    i(1),
    t({ "", "", "    return 0;", "}" }),
  }),

  -- Solution scaffolding for practice problems (LeetCode, Kattis, etc.).
  -- Just a `solve` function plus an `int main` that calls it and prints
  -- the result — trivial to strip the `main`/printf when pasting into a
  -- judge that provides its own driver code.
  s("sol", {
    t({ "#include <stdio.h>", "", "" }),
    i(1, "int"),
    t(" solve("),
    i(2, "int n"),
    t({ ") {", "\t" }),
    i(3, "// TODO: implement"),
    t({ "", "}", "", "int main(void) {" }),
    t({ "", "\tprintf(\"%d\\n\", solve(" }),
    i(4, "/* args */"),
    t({ "));", "\treturn 0;", "}" }),
    i(0),
  }),

  -- Linux kernel style doc comment for structs (and similarly for
  -- functions): one-line description followed by @field: description
  -- bullets. Delete unused @field lines, or duplicate one for more fields.
  s("dcc", {
    t("/* "),
    i(1, "Short description"),
    t({ "", " * @" }),
    i(2, "field"),
    t(": "),
    i(3, "Description."),
    t({ "", " * @" }),
    i(4, "field"),
    t(": "),
    i(5, "Description."),
    t({ "", " * @" }),
    i(6, "field"),
    t(": "),
    i(7, "Description."),
    t({ "", " */" }),
  }),
}
