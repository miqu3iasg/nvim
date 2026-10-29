-- lua/utils/path.lua

-- Small helpers for working with file paths

local M = {}

---Expand a leading `~` to the user's home directory (`$HOME`, or `%USERPROFILE%`
---on Windows). Any other path is returned unchanged.
---
---Only a bare leading `~` is handled: `~user` is not supported and would be
---glued to the home path. Raises an error if neither variable is set.
---For the full set of expansions (`$VAR`, `%`, `#`...) use `vim.fn.expand`.
---@param path string
---@return string
function M.expand(path)
	if path:sub(1, 1) == "~" then
		local home = os.getenv("HOME") or os.getenv("USERPROFILE")
		return home .. path:sub(2)
	end
	return path
end

return M
