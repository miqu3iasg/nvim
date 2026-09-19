-- lua/langs/latex/plugins/pairs.lua

-- Buffer-local mini.pairs overrides for .tex files.
--
-- mini.pairs normally prevents "(" and "[" from pairing when the
-- preceding character is a backslash (neigh_pattern = "[^\\].").
-- This is unsuitable for LaTeX, where "\(" and "\[" are math
-- delimiters rather than escaped brackets. Using ".." makes these
-- delimiters pair normally, producing "\)" and "\]" as expected.
--
-- "$" is not a default pair because it uses the same character to
-- open and close. A "closeopen" rule is therefore added so typing
-- the second "$" moves past the existing character instead of
-- creating a nested pair ("$$" -> "$$$$"). The backslash guard
-- remains to prevent escaped dollar signs (e.g. "\$5") from pairing.
--
-- Refs:
--     - https://github.com/echasnovski/mini.pairs
--     - :h MiniPairs.map_buf()
local M = {}

function M.setup(bufnr)
  local ok, pairs_mod = pcall(require, "mini.pairs")
  if not ok then
    return
  end

  -- "register.cr = false": a bare <CR> after the opening character
  -- does not close the pair, matching mini.pairs' default behavior;
  -- only the pairing pattern is overridden here.
  local always = { register = { cr = false }, neigh_pattern = ".." }

  pairs_mod.map_buf(bufnr, "i", "(", vim.tbl_extend("force", { action = "open", pair = "()" }, always))
  pairs_mod.map_buf(bufnr, "i", ")", vim.tbl_extend("force", { action = "close", pair = "()" }, always))
  pairs_mod.map_buf(bufnr, "i", "[", vim.tbl_extend("force", { action = "open", pair = "[]" }, always))
  pairs_mod.map_buf(bufnr, "i", "]", vim.tbl_extend("force", { action = "close", pair = "[]" }, always))

  pairs_mod.map_buf(bufnr, "i", "$", {
    action = "closeopen",
    pair = "$$",
    neigh_pattern = "[^\\].",
    register = { cr = false },
  })
end

return M
