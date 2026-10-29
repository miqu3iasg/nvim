-- lua/utils/system.lua

-- Information about the host system

local M = {}

---Return the name of the operating system Neovim is running on.
---Anything that is neither Windows nor macOS is reported as "linux" (includes BSDs).
---@return "windows"|"mac"|"linux"
function M.get_os()
	local os_name = vim.uv.os_uname().sysname
	if os_name == "Windows_NT" then
		return "windows"
	elseif os_name == "Darwin" then
		return "mac"
	else
		return "linux"
	end
end

return M
