-- lua/langs/latex/plugins/surround.lua

-- Buffer-local nvim-surround additions for .tex files:
-- "$" for inline math, "x" for \text{}, and "l" for \left...\right.
-- These are added via buffer_setup() without changing the global defaults.
--
-- Usage:
--   ysiw$   -> $x$
--   ds$     -> x
--   cs$x    -> \text{x}
--
--   ysiwx   -> \text{hello}
--   dsx     -> hello
--   csx$    -> $x$
--
--   ysiwl   -> \left(x+y\right)
--   dsl     -> x+y
--
-- "x" is used for \text{} instead of "t" to avoid overriding the
-- default HTML/XML tag surround.
--
-- Refs:
--     - https://github.com/kylechui/nvim-surround
--     - https://github.com/kylechui/nvim-surround/blob/main/README.md#surround-aliases
local M = {}

function M.setup(bufnr)
  local ok, surround = pcall(require, "nvim-surround")
  if not ok then
    return
  end

  surround.buffer_setup({
    surrounds = {
      ["$"] = {
        add = { "$", "$" },
        find = "%$[^%$]-%$",
        delete = "^(%$)().-(%$)()$",
      },
      ["x"] = {
        add = { "\\text{", "}" },
        find = "\\text%b{}",
        delete = "^(\\text{)().-(})()$",
      },
      ["l"] = {
        add = { "\\left(", "\\right)" },
        find = "\\left%(.-\\right%)",
        delete = "^(\\left%()().-(\\right%))()$",
      },
    },
  })
end

return M
