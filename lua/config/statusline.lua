-- lua/config/statusline.lua

-- Statusline, built on the native 'statusline' option (no plugin).
--
-- Inactive windows get a reduced version (lead, path, position).
--
-- The segments are plain Lua functions called through `v:lua.StlLine`, plus
-- three pieces of state that are refreshed by autocmds instead of on every
-- redraw, because they are costly or asynchronous:
--
-- vim.g.sl_mode       label of the current mode (see MODES)
-- vim.b.git_branch    "Git-<branch> ", "Git-@<sha> " (detached) or ""
-- vim.b.sl_file_size  " 12.3K " or "" (size of the file on disk)
--
-- It also reads `vim.t.zoomed`, which is expected to be set by a window-zoom
-- feature elsewhere in the config (shows `[Z]` while a window is zoomed).
--
-- `M.setup()` installs the statusline and the autocmds (group
-- `StatuslineBranch`).

local M = {}

---Mode codes from `nvim_get_mode().mode` mapped to the label shown in the line.
---@type table<string, string>
local MODES = {
	n = "NORMAL",
	no = "O-PENDING",
	nt = "N-TERM",
	i = "INSERT",
	R = "REPLACE",
	Rv = "V-REPLACE",
	v = "VISUAL",
	V = "V-LINE",
	["\22"] = "V-BLOCK",
	s = "SELECT",
	S = "S-LINE",
	["\19"] = "S-BLOCK",
	c = "COMMAND",
	cv = "EX",
	r = "PROMPT",
	["!"] = "SHELL",
	t = "TERMINAL",
}

-- Statusline of windows that are not focused: lead, path and position only.
-- Set window-locally on WinLeave and cleared on WinEnter (see `M.setup`).
local INACTIVE =
	"  %{v:lua.StlLine.lead()}  %<%{bufname() ==# '' ? '[No Name]' : fnamemodify(bufname(), ':p:~')}   %P L%l C%c %="

---Store the branch label in `b:git_branch` and redraw the statusline.
---Scheduled, so it is safe to call from a `vim.system` callback. Does nothing
---if the buffer was wiped in the meantime.
---@param buf integer
---@param branch string branch name (or "@<sha>"); empty clears the label
local function set_branch(buf, branch)
	vim.schedule(function()
		if vim.api.nvim_buf_is_valid(buf) then
			vim.b[buf].git_branch = branch ~= "" and ("Git-" .. branch .. " ") or ""
			vim.cmd.redrawstatus()
		end
	end)
end

---Run `git <args>` asynchronously in `dir`.
---@param args string[] git arguments, without the leading "git"
---@param dir string working directory
---@param cb fun(res: vim.SystemCompleted) called when the process exits
---@return boolean ok false if the process could not be started (e.g. git is not installed)
---@return vim.SystemObj|string result the process handle, or the error message
local function git(args, dir, cb)
	local cmd = vim.list_extend({ "git" }, args)
	return pcall(vim.system, cmd, { cwd = dir, text = true }, cb)
end

---Refresh `b:git_branch` for `buf` without blocking the editor.
---Looks for the repository from the folder of the file; special buffers
---(`buftype ~= ""`) and unnamed ones use the cwd. On a detached HEAD the short
---commit hash is shown instead (`@abc1234`). The label is empty outside a
---repository, or when git is missing.
---@param buf? integer buffer number; `nil` or `0` for the current buffer
local function update_branch(buf)
	buf = (buf and buf > 0) and buf or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local name = vim.api.nvim_buf_get_name(buf)
	local dir = vim.uv.cwd()
	if name ~= "" and vim.bo[buf].buftype == "" then
		dir = vim.fs.dirname(name)
	end
	if not dir or vim.fn.isdirectory(dir) == 0 then
		vim.b[buf].git_branch = ""
		return
	end

	local started = git({ "symbolic-ref", "--short", "-q", "HEAD" }, dir, function(res)
		if res.code == 0 then
			return set_branch(buf, vim.trim(res.stdout))
		end
		local ok = git({ "rev-parse", "--short", "HEAD" }, dir, function(r2)
			set_branch(buf, r2.code == 0 and ("@" .. vim.trim(r2.stdout)) or "")
		end)
		if not ok then
			set_branch(buf, "")
		end
	end)

	if not started then
		vim.b[buf].git_branch = ""
	end
end

---Store the formatted size in `b:sl_file_size`, if the buffer still exists.
---@param buf integer
---@param size_str string
local function set_file_size(buf, size_str)
	if vim.api.nvim_buf_is_valid(buf) then
		vim.b[buf].sl_file_size = size_str
	end
end

---Refresh `b:sl_file_size` with the size of the file on disk, padded with
---spaces and in the largest unit below 1024 (`" 512B "`, `" 1.5K "`, `" 3.2M "`;
---bytes are shown as integers, the rest with one decimal). Empty for unnamed
---buffers, special buffers, empty files and files that do not exist yet.
---Reads the disk, not the buffer, so it is stale until the file is saved.
---@param buf? integer buffer number; `nil` or `0` for the current buffer
local function update_file_size(buf)
	buf = (buf and buf > 0) and buf or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" or vim.bo[buf].buftype ~= "" then
		set_file_size(buf, "")
		return
	end

	local size = vim.fn.getfsize(name)
	if size == nil or size <= 0 then
		set_file_size(buf, "")
		return
	end

	local units = { "B", "K", "M", "G", "T" }
	local i = 1
	while size >= 1024 and i < #units do
		size = size / 1024
		i = i + 1
	end

	local formatted
	if i == 1 then
		formatted = string.format("%d%s", size, units[i])
	else
		formatted = string.format("%.1f%s", size, units[i])
	end

	set_file_size(buf, " " .. formatted .. " ")
end

---Store the label of the current mode in `g:sl_mode`. Looks the mode up in
---MODES by its full code, then by its first two characters, then by the first
---one (so e.g. `niI` resolves to NORMAL); an unknown mode is shown as its raw code.
local function update_mode()
	local m = vim.api.nvim_get_mode().mode
	vim.g.sl_mode = MODES[m] or MODES[m:sub(1, 2)] or MODES[m:sub(1, 1)] or m
end

---Leading indicator: `<enc><eol><status>-`.
---  * enc:    `U` for UTF-*, `1` for latin*, `-` for anything else
---  * eol:    `:` unix, `\` dos, `/` mac
---  * status: `%%` read-only or not modifiable, `**` modified, `--` otherwise
---@return string
function M.lead()
	local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
	local c = enc:match("^utf") and "U" or (enc:match("^latin") and "1" or "-")
	local eol = ({ unix = ":", dos = "\\", mac = "/" })[vim.bo.fileformat] or ":"
	local st = "--"
	if vim.bo.readonly or not vim.bo.modifiable then
		st = "%%"
	elseif vim.bo.modified then
		st = "**"
	end
	return c .. eol .. st .. "-"
end

---Major mode: the capitalized filetype in parentheses
---(`(Lua)`), or `(Fundamental)` when there is no filetype.
---@return string
function M.major()
	local ft = vim.bo.filetype
	if ft == "" then
		return "(Fundamental)"
	end
	return "(" .. ft:sub(1, 1):upper() .. ft:sub(2) .. ")"
end

---Diagnostic counts of the current buffer as `[E<errors> W<warnings>] `, or
---an empty string when there are neither errors nor warnings.
---@return string
function M.diag()
	local c = vim.diagnostic.count(0)
	local e = c[vim.diagnostic.severity.ERROR] or 0
	local w = c[vim.diagnostic.severity.WARN] or 0
	if e == 0 and w == 0 then
		return ""
	end
	return string.format("[E%d W%d] ", e, w)
end

---Install the statusline and the autocmds that keep it up to date.
---
--- * Exposes the module as the global `StlLine`, which the statusline string
---   needs to call `lead`, `major` and `diag` through `v:lua`.
--- * Uses `laststatus=2` (one statusline per window) and turns `showmode` off,
---   since the mode is already in the line.
--- * `b:git_branch` and `b:sl_file_size`: refreshed on BufEnter, BufWritePost,
---   FocusGained and DirChanged (the size also on FileChangedShellPost and
---   WinEnter/BufWinEnter).
--- * `g:sl_mode`: refreshed on ModeChanged.
--- * Redraws on mode, diagnostic and macro recording changes.
--- * Inactive windows use INACTIVE through a window-local 'statusline', which is
---   cleared again (falling back to the global one) when the window is entered.
function M.setup()
	_G.StlLine = M

	vim.opt.laststatus = 2
	vim.opt.showmode = false

	vim.opt.statusline = table.concat({
		"-- %{get(g:, 'sl_mode', '')} -- ",
		"%{v:lua.StlLine.lead()}",
		"%{&diff && winnr('$') > 2 ? '  [' . bufnr() . ']' : ''}",
		"  %<%{bufname() ==# '' ? '[No Name]' : fnamemodify(bufname(), ':p:~')} %m",
		"   %P L%l C%c",
		"   %{v:lua.StlLine.major()}",
		" %{get(b:, 'git_branch', '')}",
		" %{v:lua.StlLine.diag()}",
		"%{reg_recording() !=# '' ? 'REC@' . reg_recording() . ' ' : ''}",
		"%=",
		"%{get(t:, 'zoomed', 0) ? '[Z]  ' : ''}",
		"%{get(b:, 'sl_file_size', '')}",
		" 0x%04B ",
	})

	update_mode()

	local group = vim.api.nvim_create_augroup("StatuslineBranch", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained", "DirChanged" }, {
		group = group,
		callback = function(args)
			update_branch(args.buf)
			update_file_size(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("FileChangedShellPost", {
		group = group,
		callback = function(args)
			update_file_size(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		callback = function()
			update_mode()
			vim.cmd.redrawstatus()
		end,
	})

	vim.api.nvim_create_autocmd({ "DiagnosticChanged", "RecordingEnter", "RecordingLeave" }, {
		group = group,
		callback = function()
			vim.cmd.redrawstatus()
		end,
	})

	vim.api.nvim_create_autocmd("WinLeave", {
		group = group,
		callback = function()
			vim.wo.statusline = INACTIVE
		end,
	})

	vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
		group = group,
		callback = function(args)
			vim.wo.statusline = ""
			update_file_size(args.buf)
		end,
	})

	update_branch()
	update_file_size()
end

return M
