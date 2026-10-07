-- after/ftplugin/python.lua

local opt = vim.opt_local

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4

opt.textwidth = 88
opt.formatoptions:remove("t")
opt.formatoptions:append("croql")

opt.foldmethod = "indent"
opt.foldlevel = 99

local map = function(keys, func, desc)
  vim.keymap.set("n", keys, func, { buffer = true, silent = true, desc = "Python: " .. desc })
end

local function python_bin()
  local venv = vim.env.VIRTUAL_ENV
  if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
    return venv .. "/bin/python"
  end
  return vim.fn.exepath("python3") ~= "" and "python3" or "python"
end

map("<leader>rp", function()
  vim.cmd("silent write")
  local file = vim.fn.shellescape(vim.fn.expand("%:p"))
  vim.cmd("vsplit | terminal " .. python_bin() .. " " .. file)
  vim.cmd("startinsert")
end, "Run file")

map("<leader>ri", function()
  vim.cmd("botright 15split | terminal " .. python_bin() .. " -i")
  vim.cmd("startinsert")
end, "Open REPL")
