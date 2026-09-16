-- lua/langs/python/keymaps.lua

local statement = require("langs.python.statement")

local M = {}

function M.setup(bufnr)
  -- ";;" in insert mode completes the current line as a Python block
  -- header (adds the ':' if missing, opens an indented line below)
  vim.keymap.set("i", ";;", statement.complete_statement, {
    buffer = bufnr,
    silent = true,
    desc = "Complete Python block statement (adds ':' and opens indented line)",
  })

  -- Run the current Python file
  vim.keymap.set("n", "<leader>pr", function()
    vim.cmd("write")
    vim.cmd("split | terminal python %")
  end, {
    buffer = bufnr,
    silent = true,
    desc = "Run Python file",
  })
end

return M
