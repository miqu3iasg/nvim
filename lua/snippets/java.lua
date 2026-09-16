-- lua/snippets/java.lua

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

local function get_classname()
  local name = vim.fn.expand("%:t:r")
  return name ~= "" and name or "Untitled"
end

return {
  -- Solution scaffolding for practice problems (LeetCode, Kattis, etc.).
  s("sol", {
    t("public class "),
    f(get_classname, {}),
    t({
      " {",
      "",
      "    public static void main(String[] args) {",
      "        Solution sol = new Solution();",
    }),
    t({ "", "        System.out.println(sol." }),
    f(function(args)
      return args[1][1]
    end, { 2 }),
    t("("),
    i(5, "/* args */"),
    t("));"),
    t({
      "",
      "    }",
      "}",
      "",
      "class Solution {",
      "    public ",
    }),
    i(1, "int"),
    t(" "),
    i(2, "solve"),
    t("("),
    i(3, "int[] nums"),
    t({ ") {", "        " }),
    i(4, "// TODO: implement"),
    t({ "", "    }", "}" }),
    i(0),
  }),

  -- Javadoc-style doc comment for classes and methods. For a class doc,
  -- just delete the @param/@return lines you don't need.
  s("dcc", {
    t({ "/**", " * " }),
    i(1, "Description."),
    t({ "", " *" }),
    t({ "", " * @param " }),
    i(2, "paramName"),
    t(" "),
    i(3, "Description."),
    t({ "", " * @param " }),
    i(4, "paramName"),
    t(" "),
    i(5, "Description."),
    t({ "", " * @return " }),
    i(6, "Description."),
    t({ "", " */" }),
  }),
}
