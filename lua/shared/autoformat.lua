-- lua/shared/autoformat.lua

-- Single source of truth for the autoformat-on-save state. Anything that reads
-- or changes the state must go through this module instead of touching the
-- variables directly.
--
-- The state has two scopes, global (`g:disable_autoformat`) and buffer-local
-- (`b:disable_autoformat`), and autoformat runs only when neither disables it.
-- `disable()`, `enable()` and `toggle()` act on the global scope. `enable()` also
-- clears the override of the current buffer, but not of other buffers.

local M = {}

---@param bufnr? integer Defaults to the current buffer.
---@return boolean
function M.enabled(bufnr)
	bufnr = bufnr or 0
	return not (vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat)
end

function M.disable()
	vim.g.disable_autoformat = true
end

function M.enable()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end

---Toggle the global state and notify the new one.
function M.toggle()
	if vim.g.disable_autoformat then
		M.enable()
	else
		M.disable()
	end
	vim.notify("Autoformat: " .. (vim.g.disable_autoformat and "OFF" or "ON"))
end

return M
