-- lua/snippets/python.lua

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

return {
  -- Solution scaffolding for practice problems (LeetCode, etc.).
  s("sol", {
    t({ "class Solution:", "    def " }),
    i(1, "solve"),
    t("(self, "),
    i(2, "n: int"),
    t(") -> "),
    i(3, "int"),
    t({ ":", "        " }),
    i(4, "# TODO: implement"),
    t({ "", "", "", 'if __name__ == "__main__":', "    sol = Solution()" }),
    t({ "", "    print(sol." }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("("),
    i(5, "args"),
    t("))"),
    i(0),
  }),

  s("dcc", {
    t('"""'),
    i(1, "Short description."),
    t({ "", "", "Args:", "    " }),
    i(2, "param"),
    t(": "),
    i(3, "Description."),
    t({ "", "    " }),
    i(4, "param"),
    t(": "),
    i(5, "Description."),
    t({ "", "", "Returns:", "    " }),
    i(6, "Description."),
    t({ "", '"""' }),
  }),
}
