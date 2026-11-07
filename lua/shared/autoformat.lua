-- lua/shared/autoformat.lua

-- Single source of truth for the autoformat-on-save state. Anything that reads
-- or changes the state (toggle keymap, format-on-save guards, commands) must go
-- through this module instead of touching the variables directly.
--
-- The state has two scopes: global (`g:disable_autoformat`) and buffer-local
-- (`b:disable_autoformat`). Autoformat runs only when neither disables it.
-- `enable()` and `toggle()` act on the global scope, and `enable()` also clears
-- the override of the current buffer only, not of other buffers.
--
-- Usage:
--   local autoformat = require("shared.autoformat")
--   if autoformat.enabled(bufnr) then ... end

local M = {}

---Whether autoformat on save runs for `bufnr`.
---@param bufnr? integer buffer number; `nil` or `0` for the current buffer
---@return boolean
function M.enabled(bufnr)
	bufnr = bufnr or 0
	return not (vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat)
end

---Disable autoformat everywhere.
function M.disable()
	vim.g.disable_autoformat = true
end

---Re-enable autoformat everywhere, clearing any buffer-local override.
function M.enable()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end

---Toggle autoformat everywhere and notify the new state.
function M.toggle()
	if vim.g.disable_autoformat then
		M.enable()
	else
		M.disable()
	end
	vim.notify("Autoformat: " .. (vim.g.disable_autoformat and "OFF" or "ON"))
end

return M
