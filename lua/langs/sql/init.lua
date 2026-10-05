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
  map("x", "<localleader>e", eval_selection, "REPL: eval selection")
  map("n", "<localleader>eb", function() repl.send_lines(1, vim.fn.line("$")) end, "REPL: eval buffer")
  map("n", "<localleader>ls", function() repl.open(true, false) end, "REPL: open in split")
  map("n", "<localleader>lv", function() repl.open(true, true) end, "REPL: open in vsplit")
  map("n", "<localleader>lg", repl.toggle, "REPL: toggle window")
  map("n", "<localleader>lq", repl.hide, "REPL: hide window")
  map("n", "<localleader>lr", repl.restart, "REPL: restart session")
  map("n", "<localleader>lx", repl.kill, "REPL: kill session")

  map("n", "<localleader>es", function()
    repl.send("SELECT * FROM " .. vim.fn.expand("<cword>") .. " LIMIT 100;")
  end, "REPL: select from word")
end

local function has_connection(buf)
  local b = vim.b[buf]
  return (b.db and b.db ~= "") or vim.w.db or vim.t.db or vim.g.db
      or (vim.env.DATABASE_URL and vim.env.DATABASE_URL ~= "")
end

local function direnv_url(dir)
  if vim.fn.executable("direnv") == 0 then return nil end
  local res = vim.system({ "direnv", "export", "json" }, { cwd = dir, text = true }):wait()
  if res.code ~= 0 or res.stdout == "" then return nil end
  local ok, env = pcall(vim.json.decode, res.stdout)
  return ok and env and env.DATABASE_URL or nil
end

function M.setup()
  -- mysql and plsql filetypes have no parser of their own, so they reuse sql
  vim.treesitter.language.register("sql", { "mysql", "plsql" })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("sql_repl", { clear = true }),

    pattern = filetypes,

    callback = function(event)
      attach(event.buf)
      if not has_connection(event.buf) then
        local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(event.buf))
        local url = direnv_url(dir)
        if url then vim.b[event.buf].db = url end
      end
    end,
  })
end

return M
