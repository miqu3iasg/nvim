-- lua/utils/init.lua

local utils = {}

--- get the operating system name
--- "windows", "mac", "linux"
function utils.get_os()
  local uname = vim.loop.os_uname()
  local os_name = uname.sysname
  if os_name == "Windows_NT" then
    return "windows"
  elseif os_name == "Darwin" then
    return "mac"
  else
    return "linux"
  end
end

-- Save the current buffer if it has unsaved changes and a real file name
-- (avoids erroring on unnamed/scratch buffers, which :update can't handle)
function utils.save_if_modified()
  if vim.bo.modified and vim.api.nvim_buf_get_name(0) ~= "" then
    vim.cmd("update")
  end
end

function utils.expand_path(path)
  if path:sub(1, 1) == "~" then
    local home = os.getenv("HOME") or os.getenv("USERPROFILE")
    return home .. path:sub(2)
  end
  return path
end

return utils
