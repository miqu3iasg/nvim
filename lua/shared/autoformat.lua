-- lua/shared/autoformat.lua

-- Single source of truth for the autoformat-on-save state. Every place that
-- reads or writes the state goes through this module:
--
--   * plugins/formatting.lua: `<leader>uf` toggle and conform's
--     `format_on_save` guard;
--   * plugins/lsp.lua: the `LspEslintFixAll` guard before conform formats;
--   * config/commands.lua: the `:FormatEnable` and `:FormatDisable` commands.
--
-- The state has two scopes: global (`g:disable_autoformat`) and buffer-local
-- (`b:disable_autoformat`), so autoformat can be turned off everywhere while
-- staying on in a specific buffer, or the other way around.

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
