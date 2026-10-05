-- lua/plugins/sql.lua

-- This configuration requires the command line client of each database you
-- connect to. vim-dadbod shells out to it and the REPL runs it interactively.
-- You can install the common ones on Arch Linux via:
--
-- `sudo pacman -S mariadb-clients` (MySQL / MariaDB)
-- `sudo pacman -S postgresql` (psql)
-- `sudo pacman -S sqlite`
--
-- Connections are not defined here. vim-dadbod resolves the connection of a
-- buffer from `b:db`, `w:db`, `t:db`, `g:db` and `$DATABASE_URL`, in that
-- order. vim-dadbod-ui also lists the connections saved with
-- `:DBUIAddConnection` and the one in `$DBUI_URL`.
--
-- Formatting is handled by conform.nvim (see lua/plugins/conform.lua).
-- sql-formatter reads `.sql-formatter.json` from the working directory,
-- which is where the dialect and keyword case are configured per project.
--
-- refs:
--     - https://github.com/tpope/vim-dadbod
--     - https://github.com/kristijanhusak/vim-dadbod-ui
--     - https://github.com/kristijanhusak/vim-dadbod-completion
--     - https://github.com/sql-formatter-org/sql-formatter

local filetypes = { "sql", "mysql", "plsql" }

local function close_result()
  -- Closes any existing dadbod output window
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].filetype == "dbout" then
      local win = vim.fn.bufwinid(b)
      if win ~= -1 then
        vim.api.nvim_win_close(win, false)
      end
    end
  end
end

-- Runs a dadbod command in a vertical split
local function db_vertical(cmd)
  vim.cmd("vertical " .. cmd)
end

local function run_statement()
  local first, last = require("langs.sql.statement").under_cursor()
  if first then
    db_vertical(("%d,%dDB"):format(first, last))
  end
end

local function select_word()
  db_vertical("DB SELECT * FROM " .. vim.fn.expand("<cword>") .. " LIMIT 100;")
end

local function set_connection()
  local buf = vim.api.nvim_get_current_buf()
  local current = vim.b[buf].db
  vim.ui.input({
    prompt = "Connection URL: ",
    default = type(current) == "string" and current or "",
  }, function(url)
    if url and url ~= "" then
      vim.b[buf].db = url
    end
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
      -- Disable preview window so we can use vertical splits normally
      vim.g.db_use_preview_window = 0
    end,
    keys = {
      { "<localleader>rr", run_statement,           ft = filetypes, desc = "DB: run statement" },
      { "<localleader>rb", "<cmd>vertical %DB<CR>", ft = filetypes, desc = "DB: run buffer" },
      { "<localleader>rs", select_word,             ft = filetypes, desc = "DB: select from word" },
      { "<localleader>rc", set_connection,          ft = filetypes, desc = "DB: set buffer connection" },
      { "<localleader>rq", close_result,            ft = filetypes, desc = "DB: close result" },
    },
  },

  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { "tpope/vim-dadbod" },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer", "DBUILastQueryInfo" },

    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_execute_on_save = 0
      require("langs.sql").setup()
    end,

    keys = {
      { "<localleader>ra", "<cmd>DBUIAddConnection<CR>", ft = filetypes, desc = "DB: add connection" },
      { "<localleader>ri", "<cmd>DBUILastQueryInfo<CR>", ft = filetypes, desc = "DB: last query info" },
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
