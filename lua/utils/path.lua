-- lua/utils/path.lua

local M = {}

-- Expands a leading `~` to the user's home directory
function M.expand(path)
  if path:sub(1, 1) == "~" then
    local home = os.getenv("HOME") or os.getenv("USERPROFILE")
    return home .. path:sub(2)
  end
  return path
end

return M
