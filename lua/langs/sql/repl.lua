-- lua/langs/sql/repl.lua

-- Persistent interactive client sessions in a terminal split, one per
-- connection. The client command is provided by vim-dadbod, so any database
-- it supports works. Session state (transactions, variables) is preserved.

local statement = require("langs.sql.statement")

local M = {}

local sessions = {}

-- Connection of the current buffer, resolved in the same order as vim-dadbod.
local function connection()
  local url = vim.b.db or vim.w.db or vim.t.db or vim.g.db or vim.env.DATABASE_URL
  if type(url) == "string" and url ~= "" then
    return url
  end
  vim.notify("SQL REPL: no connection (b:db, g:db or $DATABASE_URL)", vim.log.levels.WARN)
end

local function alive(session)
  return session ~= nil
      and vim.api.nvim_buf_is_valid(session.buf)
      and vim.fn.jobwait({ session.chan }, 0)[1] == -1
end

local function window(session)
  if not (session and vim.api.nvim_buf_is_valid(session.buf)) then
    return nil
  end
  local win = vim.fn.bufwinid(session.buf)
  return win ~= -1 and win or nil
end

local function split(vertical)
  if vertical then
    -- Opens a real vertical split on the right with 40% of the screen width
    local width = math.floor(vim.o.columns * 0.4)
    vim.cmd("botright " .. width .. "vnew")
  else
    vim.cmd("botright 15new")
  end
end

local function start(url, vertical)
  local ok, cmd = pcall(vim.fn["db#adapter#dispatch"], url, "interactive")
  if not ok then
    vim.notify("SQL REPL: " .. tostring(cmd), vim.log.levels.ERROR)
    return nil
  end

  split(vertical)
  local buf = vim.api.nvim_get_current_buf()
  local chan = vim.fn.jobstart(cmd, { term = true })
  if chan <= 0 then
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.notify("SQL REPL: failed to start the client", vim.log.levels.ERROR)
    return nil
  end

  local session = { buf = buf, chan = chan }
  sessions[url] = session
  return session
end

-- Appends a terminator when the last code line has none.
local function terminate(text)
  local last
  for line in text:gmatch("[^\n]+") do
    if not line:match("^%s*%-%-") and not line:match("^%s*$") then
      last = line
    end
  end
  if not last then
    return nil
  end
  if not statement.terminated(last) then
    text = text .. "\n;"
  end
  return text
end

-- Opens or reveals the session of the current connection. Returns the session.
function M.open(focus, vertical)
  local url = connection()
  if not url then
    return nil
  end

  local origin = vim.api.nvim_get_current_win()
  local session = sessions[url]

  if not alive(session) then
    if session and vim.api.nvim_buf_is_valid(session.buf) then
      vim.api.nvim_buf_delete(session.buf, { force = true })
    end
    session = start(url, vertical)
    if not session then
      return nil
    end
  elseif not window(session) then
    split(vertical)
    vim.api.nvim_win_set_buf(0, session.buf)
  elseif focus then
    vim.api.nvim_set_current_win(window(session))
  end

  if focus then
    vim.cmd("startinsert")
  elseif vim.api.nvim_win_is_valid(origin) then
    vim.api.nvim_set_current_win(origin)
  end
  return session
end

function M.hide()
  local url = connection()
  local win = url and window(sessions[url])
  if win then
    vim.api.nvim_win_close(win, false)
  end
end

function M.toggle()
  local url = connection()
  if url and window(sessions[url]) then
    M.hide()
  else
    -- Default to vertical on toggle
    M.open(false, true)
  end
end

function M.kill()
  local url = connection()
  local session = url and sessions[url]
  if not session then
    return
  end
  if alive(session) then
    vim.fn.jobstop(session.chan)
  end
  if vim.api.nvim_buf_is_valid(session.buf) then
    vim.api.nvim_buf_delete(session.buf, { force = true })
  end
  sessions[url] = nil
end

function M.restart()
  M.kill()
  -- Default to vertical on restart
  M.open(false, true)
end

function M.send(text)
  text = terminate(text)
  if not text then
    return
  end

  -- Default to vertical when sending commands from the editor
  local session = M.open(false, true)
  if not session then
    return
  end

  vim.api.nvim_chan_send(session.chan, text .. "\n")
  local win = window(session)
  if win then
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(session.buf), 0 })
  end
end

function M.send_lines(first, last)
  M.send(table.concat(vim.api.nvim_buf_get_lines(0, first - 1, last, false), "\n"))
end

return M
