-- lua/langs/sql/init.lua

local M = {}

local filetypes = { "sql", "mysql", "plsql" }

local function attach(buf)
  local repl = require("langs.sql.repl")
  local statement = require("langs.sql.statement")

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
  end

  local function eval_statement()
    local first, last = statement.under_cursor()
    if first then
      repl.send_lines(first, last)
    end
  end

  local function eval_selection()
    repl.send_lines(statement.selection())
  end

  map("n", "<localleader>ee", eval_statement, "REPL: eval statement")
  map("x", "<localleader>E", eval_selection, "REPL: eval selection")
  map("n", "<localleader>eb", function() repl.send_lines(1, vim.fn.line("$")) end, "REPL: eval buffer")
  map("n", "<localleader>ls", function() repl.open(true, false) end, "REPL: open in split")
  map("n", "<localleader>lv", function() repl.open(true, true) end, "REPL: open in vsplit")
  map("n", "<localleader>lg", repl.toggle, "REPL: toggle window")
  map("n", "<localleader>lq", repl.hide, "REPL: hide window")
  map("n", "<localleader>lR", repl.restart, "REPL: restart session")
  map("n", "<localleader>lx", repl.kill, "REPL: kill session")

  map("n", "<localleader>es", function()
    repl.send("SELECT * FROM " .. vim.fn.expand("<cword>") .. " LIMIT 100;")
  end, "REPL: select from word")
end

function M.setup()
  -- vim-dadbod-ui may open query buffers with the mysql and plsql filetypes.
  vim.treesitter.language.register("sql", { "mysql", "plsql" })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("sql_repl", { clear = true }),
    pattern = filetypes,
    callback = function(event)
      attach(event.buf)
    end,
  })
end

return M
