-- lua/utils/buffers.lua

-- Helpers for inspecting, saving and deleting buffers without breaking the
-- window layout

local M = {}

---Whether `buf` is a valid terminal buffer.
---@param buf integer
---@return boolean
function M.is_terminal(buf)
	return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal"
end

---Whether `win` is a regular window (not a floating one).
---@param win integer
---@return boolean
function M.is_normal_window(win)
	return vim.api.nvim_win_get_config(win).relative == ""
end

---Save `buf` if it has unsaved changes and a real file name. Special and
---unnamed buffers are skipped, since `:update` errors on them.
---
---Returns whether the buffer is safe to delete (nothing left to lose):
--- * `true` for terminals and for buffers that are unmodified (or were saved);
--- * `false` for modified special/unnamed buffers (nowhere to save) and for
---   buffers whose save failed.
---@param buf? integer buffer number, `0` or `nil` for the current buffer
---@return boolean
function M.save_if_modified(buf)
	buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf

	if M.is_terminal(buf) or not vim.bo[buf].modified then
		return true
	end
	if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then
		return false -- special or unnamed buffer: nowhere to save
	end

	vim.api.nvim_buf_call(buf, function()
		pcall(vim.cmd, "silent! update")
	end)
	return not vim.bo[buf].modified
end

---Delete `buf`. Terminals are deleted with `force`, everything else is not, so
---modified buffers are kept. Does not raise: returns the `pcall` result.
---@param buf integer
---@return boolean ok
---@return string? err
function M.delete(buf)
	return pcall(vim.api.nvim_buf_delete, buf, { force = M.is_terminal(buf) })
end

---Most recently used listed buffer, other than `buf`.
---@param buf integer buffer to exclude
---@return integer? bufnr `nil` when there is no other listed buffer
function M.pick_replacement(buf)
	local best
	for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
		if info.bufnr ~= buf and (not best or info.lastused > best.lastused) then
			best = info
		end
	end
	return best and best.bufnr
end

---Delete `buf` but keep every window that was showing it: those windows switch
---to the most recently used buffer (see `pick_replacement`), or to a new empty
---buffer when there is none.
---@param buf integer
---@return boolean ok
---@return string? err
function M.delete_keep_layout(buf)
	local wins = vim.fn.win_findbuf(buf)
	if #wins > 0 then
		local repl = M.pick_replacement(buf) or vim.api.nvim_create_buf(true, false)
		for _, win in ipairs(wins) do
			vim.api.nvim_win_set_buf(win, repl)
		end
	end
	return M.delete(buf)
end

---Save and delete every listed buffer that passes `filter`. A buffer that could
---not be saved is kept on purpose; a single warning reports how many.
---NOTE: unlike `delete_keep_layout`, this does not preserve the window layout.
---@param filter? fun(info: table): boolean receives a `getbufinfo()` entry; `nil` matches every listed buffer
function M.delete_where(filter)
	local kept = 0
	for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
		if not filter or filter(info) then
			if M.save_if_modified(info.bufnr) then
				M.delete(info.bufnr)
			else
				kept = kept + 1
			end
		end
	end
	if kept > 0 then
		vim.notify(kept .. " buffer(s) could not be saved, kept", vim.log.levels.WARN)
	end
end

return M
