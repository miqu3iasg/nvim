-- lua/snippets/scheme.lua

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

return {
  -- Top-level section header (3 semicolons).
  s("sec", {
    t(";;; "),
    i(1, "Section Name"),
    i(0),
  }),

  -- Code block documentation (2 semicolons).
  s("cm", {
    t(";; "),
    i(1, "Explanation of the block below"),
    i(0),
  }),

  -- Multi-line block comment using Scheme syntax (#| ... |#).
  s("bloc", {
    t({ "#|", "" }),
    i(1, "Long explanation or pseudocode"),
    t({ "", "|#" }),
    i(0),
  }),

  -- Datum comment - Manual typing.
  s("dat", {
    t("#; "),
    i(1, "expression-to-ignore"),
    i(0),
  }),

  -- Datum comment (#;).
  -- Smart selection: If triggered with a visual selection, it wraps it.
  -- If triggered without, it provides an insert node to type the expression.
  s("wdat", {
    t("#; "),
    f(function(_, parent)
      return parent.env.LS_SELECT_RAW or { "" }
    end, {}),
    i(0),
  }),

  -- Evaluation convention (=>).
  s("eval", {
    t(" ; => "),
    i(1, "result"),
    i(0),
  }),
}
