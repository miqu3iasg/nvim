local M = {}

-- Mode
function M.mode()
  local mode = vim.fn.mode()

  local modes = {
    n = "NORMAL",
    i = "INSERT",
    R = "REPLACE",
    v = "VISUAL",
    V = "VISUAL",
    ["\22"] = "V-BLOCK",
    s = "SELECT",
    S = "S-LINE",
    ["\19"] = "S-BLOCK",
    c = "COMMAND",
    t = "TERMINAL",
  }

  return "-- " .. (modes[mode] or mode) .. " --"
end

-- Indentation
function M.indent()
  if vim.bo.expandtab then
    return "sw=" .. vim.bo.shiftwidth .. " "
  elseif vim.bo.tabstop == vim.bo.shiftwidth then
    return "ts=" .. vim.bo.tabstop .. " "
  else
    return "sw=" .. vim.bo.shiftwidth .. ",ts=" .. vim.bo.tabstop .. " "
  end
end

-- Active statusline
function M.active()
  local diff = ""

  if vim.wo.diff and vim.fn.winnr("$") > 2 then
    diff = " [" .. vim.fn.bufnr() .. "] "
  end

  local zoom = vim.t.zoom and "[Z]" or ""
  local lsp = vim.g.lsp_enabled and "[L]" or ""

  return table.concat({
    "%{%v:lua.require('statusline').mode()%}",
    "  ",
    diff,
    "%<%F ",
    "%-5r",
    "%-4m",
    "%=",
    zoom,
    lsp,
    " ",
    M.indent(),
    "%-11.(%l:%c%)",
    "%-4P",
  })
end

function M.setup()
  -- Native statusline
  vim.opt.laststatus = 2

  -- Hide command area
  vim.opt.cmdheight = 0

  -- Mode is displayed in the statusline
  vim.opt.showmode = false

  -- Avoid interfering with floating plugin windows.
  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      local config = vim.api.nvim_win_get_config(0)

      if config.relative ~= "" then
        return
      end

      vim.opt_local.statusline = "%!v:lua.require('statusline').active()"
    end,

  })

  vim.opt.statusline = "%!v:lua.require('statusline').active()"
end

M.setup()

return M
