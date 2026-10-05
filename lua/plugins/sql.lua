-- lua/plugins/sql.lua

-- This configuration requires the command line client of each database you
-- connect to. vim-dadbod-completion shells out to it to read the schema,
-- and the REPL runs it interactively. You can install the common ones on
-- Arch Linux via:
--
-- `sudo pacman -S mariadb-clients` (MySQL / MariaDB)
-- `sudo pacman -S postgresql` (psql)
-- `sudo pacman -S sqlite`
--
-- vim-dadbod is used only to resolve the connection of a buffer, which it
-- does from `w:db`, `t:db`, `b:db`, `$DATABASE_URL` and `g:db`, in that
-- order. The connection of a buffer can be set with `<localleader>rc`.
--
-- Formatting is handled by conform.nvim (see lua/plugins/conform.lua).
-- sql-formatter reads `.sql-formatter.json` from the working directory,
-- which is where the dialect and keyword case are configured per project.
--
-- refs:
--     - https://github.com/tpope/vim-dadbod
--     - https://github.com/kristijanhusak/vim-dadbod-completion
--     - https://github.com/sql-formatter-org/sql-formatter

local filetypes = { "sql", "mysql", "plsql" }

-- Runs an Ex command and reports failures (e.g. an invalid URL) as a
-- notification instead of a stack trace
local function run(cmd)
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR, { title = "DB" })
  end
end

local function set_connection()
  local buf = vim.api.nvim_get_current_buf()
  local current = vim.b[buf].db
  vim.ui.input({
    prompt = "Connection URL: ",
    default = type(current) == "string" and current or "",
  }, function(url)
    if not url or url == "" then
      return
    end
    -- Lets dadbod canonicalize and validate the URL while assigning it
    vim.api.nvim_buf_call(buf, function()
      run("DB b:db = " .. url)
    end)
  end)
end

local per_filetype = {}
for _, ft in ipairs(filetypes) do
  per_filetype[ft] = { inherit_defaults = true, "dadbod" }
end

return {
  {
    "tpope/vim-dadbod",
    ft = filetypes,
    cmd = "DB",
    init = function()
      require("langs.sql").setup()
    end,
    keys = {
      { "<localleader>rc", set_connection, ft = filetypes, desc = "DB: set buffer connection" },
    },
  },

  {
    "kristijanhusak/vim-dadbod-completion",
    ft = filetypes,
    dependencies = { "tpope/vim-dadbod" },
  },

  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = per_filetype,
        providers = {
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        },
      },
    },
  },
}
