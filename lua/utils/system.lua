-- lua/utils/system.lua

local M = {}

-- Returns the operating system name, "windows", "mac" or "linux"
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
