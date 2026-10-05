-- Native statusline for Neovim.

local M = {}

local MODES = {
  n = "NORMAL",
  no = "O-PENDING",
  nt = "N-TERM",
  i = "INSERT",
  R = "REPLACE",
  Rv = "V-REPLACE",
  v = "VISUAL",
  V = "V-LINE",
  ["\22"] = "V-BLOCK",
  s = "SELECT",
  S = "S-LINE",
  ["\19"] = "S-BLOCK",
  c = "COMMAND",
  cv = "EX",
  r = "PROMPT",
  ["!"] = "SHELL",
  t = "TERMINAL",
}

local function esc(s)
  return (tostring(s):gsub("%%", "%%%%"))
end

local function set_branch(buf, branch)
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf].git_branch = branch
      vim.cmd.redrawstatus()
    end
  end)
end

local function git(args, dir, cb)
  local cmd = vim.list_extend({ "git" }, args)
  return pcall(vim.system, cmd, { cwd = dir, text = true }, cb)
end

local function update_branch(buf)
  buf = (buf and buf > 0) and buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then return end

  local name = vim.api.nvim_buf_get_name(buf)
  local dir = vim.uv.cwd()
  if name ~= "" and vim.bo[buf].buftype == "" then
    dir = vim.fs.dirname(name)
  end
  if not dir or vim.fn.isdirectory(dir) == 0 then
    vim.b[buf].git_branch = ""
    return
  end

  local started = git({ "symbolic-ref", "--short", "-q", "HEAD" }, dir, function(res)
    if res.code == 0 then
      return set_branch(buf, vim.trim(res.stdout))
    end
    local ok = git({ "rev-parse", "--short", "HEAD" }, dir, function(r2)
      set_branch(buf, r2.code == 0 and ("@" .. vim.trim(r2.stdout)) or "")
    end)
    if not ok then set_branch(buf, "") end
  end)

  if not started then vim.b[buf].git_branch = "" end
end

local function mode()
  local m = vim.api.nvim_get_mode().mode
  return MODES[m] or MODES[m:sub(1, 2)] or MODES[m:sub(1, 1)] or m
end

local function branch()
  local b = vim.b.git_branch
  return (b and b ~= "") and (" " .. esc(b)) or ""
end

local function diff_buf()
  if vim.wo.diff and vim.fn.winnr("$") > 2 then
    return "[" .. vim.fn.bufnr() .. "]"
  end
  return ""
end

local function indent()
  local sw, ts = vim.bo.shiftwidth, vim.bo.tabstop
  if vim.bo.expandtab then return "sw=" .. sw end
  if ts == sw then return "ts=" .. ts end
  return "sw=" .. sw .. ",ts=" .. ts
end

local function diagnostics()
  local counts = vim.diagnostic.count(0)
  local out = {}
  for _, s in ipairs({
    { "E", vim.diagnostic.severity.ERROR },
    { "W", vim.diagnostic.severity.WARN },
  }) do
    local n = counts[s[2]] or 0
    if n > 0 then out[#out + 1] = s[1] .. n end
  end
  return table.concat(out, " ")
end

local function lsp()
  local names = {}
  for _, cl in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    names[#names + 1] = cl.name
  end
  return #names > 0 and ("[" .. esc(table.concat(names, ",")) .. "]") or ""
end

local function encoding()
  local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
  local ff = vim.bo.fileformat
  if enc == "utf-8" and ff == "unix" then return "" end
  return esc(enc) .. "[" .. ff .. "]"
end

local function join(parts)
  local out = {}
  for _, p in ipairs(parts) do
    if p ~= "" then out[#out + 1] = p end
  end
  return table.concat(out, "  ")
end

local function is_active()
  local cur = tonumber(vim.g.actual_curwin)
  local win = tonumber(vim.g.statusline_winid)
  return cur == nil or win == nil or cur == win
end

function M.render()
  local active = is_active()

  if not active then
    return " %<%f %m%=%l:%c "
  end

  local left = join({
    "-- " .. mode() .. " --",
    diff_buf(),
    branch(),
    "%<%f%r%m",
  })

  local right = join({
    -- diagnostics(),
    -- vim.t.zoom and "[Z]" or "",
    -- lsp(),
    esc(vim.bo.filetype),
    encoding(),
    indent(),
    "%-8.(%l:%c%)",
    "%P",
  })

  return " " .. left .. "%=" .. right .. " "
end

function M.setup()
  vim.opt.laststatus = 2
  vim.opt.cmdheight = 0
  vim.opt.showmode = false
  vim.opt.statusline = "%!v:lua.require('statusline').render()"

  local group = vim.api.nvim_create_augroup("StatuslineBranch", { clear = true })
  vim.api.nvim_create_autocmd(
    { "BufEnter", "BufWritePost", "FocusGained", "DirChanged" },
    {
      group = group,
      callback = function(args) update_branch(args.buf) end,
    }
  )

  update_branch()
end

return M
