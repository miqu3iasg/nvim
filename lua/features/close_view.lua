-- lua/features/close_view.lua

-- Closes Fugitive views without ever quitting Neovim. The mappings are
-- buffer-local and installed by autocmds, so `setup()` must be called once.
--
-- Closing a `gitcommit` buffer discards it, which aborts the commit. Requires
-- vim-fugitive to be installed.
--
-- See: https://github.com/tpope/vim-fugitive
-- See: :help fugitive

local M = {}

---Whether `buf` is a Fugitive virtual buffer, such as the index or a commit
---side of a diff, as opposed to the working copy.
---@param buf integer
---@return boolean
local function is_fugitive_buf(buf)
	return vim.api.nvim_buf_get_name(buf):find("^fugitive://") ~= nil
end

---Close a diff, keeping the working copy and closing the other diff windows.
---When every diff window is a Fugitive buffer, the current window is kept.
---Does nothing outside diff mode.
---
---Replaces Fugitive's own `dq`, which is not mapped in every window.
function M.close_diff()
	if not vim.wo.diff then
		return
	end
	local wins = vim.tbl_filter(function(w)
		return vim.wo[w].diff
	end, vim.api.nvim_tabpage_list_wins(0))

	local keep
	for _, w in ipairs(wins) do
		if not is_fugitive_buf(vim.api.nvim_win_get_buf(w)) then
			keep = w
			break
		end
	end
	keep = keep or vim.api.nvim_get_current_win()

	for _, w in ipairs(wins) do
		if w ~= keep then
			pcall(vim.api.nvim_win_close, w, false)
		end
	end
	vim.api.nvim_set_current_win(keep)
	vim.cmd("diffoff!")
end

---Close the Fugitive view under the cursor without ever quitting Neovim.
---
---In diff mode it delegates to `close_diff`. On status and blame views it
---delegates to Fugitive's own `gq` when mapped, so the blame state is restored.
---Elsewhere it closes the window, or, when it is the last window, switches to
---the alternate buffer if it is a regular file and to an empty buffer
---otherwise.
---
---A `gitcommit` buffer is discarded, which aborts the commit. Errors are
---reported as warnings instead of being raised.
function M.close_view()
	if vim.wo.diff then
		return M.close_diff()
	end

	local ft = vim.bo.filetype
	if (ft == "fugitive" or ft == "fugitiveblame") and vim.fn.maparg("gq", "n") ~= "" then
		return vim.api.nvim_feedkeys(vim.keycode("gq"), "m", false)
	end

	local bang = ft == "gitcommit" and "!" or ""
	local ok, err = pcall(function()
		if #vim.api.nvim_tabpage_list_wins(0) > 1 or #vim.api.nvim_list_tabpages() > 1 then
			vim.cmd("close" .. bang)
			return
		end
		local alt = vim.fn.bufnr("#")
		if alt > 0 and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buftype == "" then
			vim.cmd("buffer" .. bang .. " " .. alt)
		else
			vim.cmd("enew" .. bang)
		end
	end)
	if not ok then
		vim.notify(tostring(err), vim.log.levels.WARN)
	end
end

---Install the buffer-local close mappings. `q` is mapped on Fugitive, blame,
---git and commit buffers. `gq` and `dq` are mapped on read-only buffers, except
---status and blame, which keep Fugitive's own `gq`.
---@param buf integer
function M.map_close(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local ft = vim.bo[buf].filetype
	local opts = { buffer = buf, silent = true, desc = "Close Fugitive view" }
	if ft == "fugitive" or ft == "fugitiveblame" or ft == "git" or ft == "gitcommit" then
		vim.keymap.set("n", "q", M.close_view, opts)
	end
	if ft ~= "fugitive" and ft ~= "fugitiveblame" and not vim.bo[buf].modifiable then
		vim.keymap.set("n", "gq", M.close_view, opts)
		vim.keymap.set("n", "dq", M.close_view, opts)
	end
end

---Register the autocmds that install the mappings. Safe to call more than once,
---since the augroup is cleared on every call.
function M.setup()
	local group = vim.api.nvim_create_augroup("FugitiveCloseView", { clear = true })

	-- Scheduled so these mappings override the ones Fugitive installs after
	-- setting the filetype.
	vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
		group = group,
		pattern = { "fugitive", "fugitiveblame", "git", "gitcommit", "fugitive://*" },
		callback = function(e)
			vim.schedule(function()
				M.map_close(e.buf)
			end)
		end,
	})

	vim.api.nvim_create_autocmd("OptionSet", {
		group = group,
		pattern = "diff",
		callback = function()
			if vim.wo.diff then
				vim.keymap.set("n", "dq", M.close_diff, {
					buffer = vim.api.nvim_get_current_buf(),
					silent = true,
					desc = "Close diff",
				})
			end
		end,
	})
end

return M
