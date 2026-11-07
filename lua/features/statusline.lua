-- lua/features/statusline.lua

-- Statusline built on the native 'statusline' option (no plugin). The active
-- window shows the mode, file state, scroll percentage, path, position,
-- selection size, search count, filetype, git branch, diagnostics, macro
-- recording and (for big files only) file size; inactive windows get a reduced
-- version (lead, percentage, path, position).
--
-- Costly or asynchronous pieces (mode, git branch, file size) are not computed
-- on every redraw: they are stored in `vim.g.sl_mode`, `vim.b.git_branch` and
-- `vim.b.sl_file_size` and refreshed by autocmds. The branch is looked up
-- asynchronously and cached per directory for a short time, so a change made
-- outside Neovim can take a few seconds to show up. The file size is read from
-- disk, so it is stale until the file is saved. It is only shown for files of
-- at least `FILE_SIZE_MIN` bytes.
--
-- The segment functions are exposed through the global `StlLine` because the
-- statusline string calls them via `v:lua`. The `[Z]` indicator reads
-- `vim.t.zoomed`, set by lua/features/window_zoom.lua.
--
-- Requires git for the branch segment; without it the segment is just empty.
--
-- Usage:
--   require("features.statusline").setup()
--
-- See: lua/features/window_zoom.lua

local M = {}

-- Branch cache, keyed by the directory the git command would run in
-- ("dir -> label"). After the first look, BufEnter/WinEnter reuse the label
-- instead of spawning git every time; entries expire (branch can change
-- outside Neovim) and are dropped on :cd. BufWritePost refreshes too, since
-- writes may come from fugitive Git operations.
--
-- See: update_branch and M.setup below.
---@type table<string, { label: string, ts: number }>
local branch_cache = {}

-- How long a cached branch label is trusted before a git subprocess is
-- spawned again.
---@type number cache lifetime in seconds
local BRANCH_TTL = 30

-- Files smaller than this are not worth a size indicator, so the segment stays
-- empty for them.
---@type number threshold in bytes (1 MiB)
local FILE_SIZE_MIN = 1024 * 1024

-- Maximum number of matches counted by the search segment; beyond it the total
-- is shown as `>999`. Keeps the redraw cheap in huge files.
---@type integer
local SEARCH_MAXCOUNT = 999

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

-- Modes (as returned by `vim.fn.mode()`) in which a selection exists and its
-- size is shown: charwise/linewise/blockwise Visual and Select.
---@type table<string, boolean>
local SELECTION_MODES = {
	v = true,
	V = true,
	["\22"] = true,
	s = true,
	S = true,
	["\19"] = true,
}

-- Statusline of windows that are not focused: lead, percentage, path and
-- position only. Set window-locally on WinLeave and cleared on WinEnter (see
-- `M.setup`).
---@type string
local INACTIVE =
	"  %{v:lua.StlLine.lead()}  %P %<%{bufname() ==# '' ? '[No Name]' : fnamemodify(bufname(), ':p:~')}   L%l C%c %="

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
---Results are cached per directory (see `branch_cache`), so frequent
---BufEnter/WinEnter calls reuse the label instead of spawning git every time.
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

	-- Fresh enough cache: apply without touching git
	local cached = branch_cache[dir]
	if cached and (os.clock() - cached.ts) < BRANCH_TTL then
		vim.b[buf].git_branch = cached.label
		return
	end
	-- Expired cache still avoids a flicker: keep the old label while probing
	local stale = cached and cached.label or ""

	local started = git({ "symbolic-ref", "--short", "-q", "HEAD" }, dir, function(res)
		if res.code == 0 then
			local label = "Git-" .. vim.trim(res.stdout) .. " "
			branch_cache[dir] = { label = label, ts = os.clock() }
			return set_branch(buf, vim.trim(res.stdout))
		end
		local ok = git({ "rev-parse", "--short", "HEAD" }, dir, function(r2)
			local label = r2.code == 0 and ("@" .. vim.trim(r2.stdout)) or ""
			branch_cache[dir] = { label = label, ts = os.clock() }
			set_branch(buf, r2.code == 0 and vim.trim(r2.stdout) or "")
		end)
		if not ok then
			branch_cache[dir] = { label = "", ts = os.clock() }
			set_branch(buf, "")
		end
	end)

	-- The new label arrives asynchronously anyway; keep the previously
	-- computed label visible meanwhile (avoids flicker on expiry refresh)
	if started and stale ~= "" then
		vim.b[buf].git_branch = stale
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

---Refresh `b:sl_file_size` with the size of the file on disk, but only when it
---is large (at least `FILE_SIZE_MIN` bytes). The value is padded with spaces
---and uses the largest unit below 1024 (`" 1.5M "`, `" 3.2G "`; one decimal).
---Empty for small files, unnamed buffers, special buffers, empty files and
---files that do not exist yet.
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
	if size == nil or size < FILE_SIZE_MIN then
		set_file_size(buf, "")
		return
	end

	local units = { "B", "K", "M", "G", "T" }
	local i = 1
	while size >= 1024 and i < #units do
		size = size / 1024
		i = i + 1
	end

	set_file_size(buf, string.format(" %.1f%s ", size, units[i]))
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
---@return string indicator
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
---@return string label
function M.major()
	local ft = vim.bo.filetype
	if ft == "" then
		return "(Fundamental)"
	end
	return "(" .. ft:sub(1, 1):upper() .. ft:sub(2) .. ")"
end

---Diagnostic counts of the current buffer as `[E<errors> W<warnings>] `, or
---an empty string when there are neither errors nor warnings.
---@return string segment
function M.diag()
	local c = vim.diagnostic.count(0)
	local e = c[vim.diagnostic.severity.ERROR] or 0
	local w = c[vim.diagnostic.severity.WARN] or 0
	if e == 0 and w == 0 then
		return ""
	end
	return string.format("[E%d W%d] ", e, w)
end

---Size of the current Visual/Select selection as `" <lines>L <chars>C"`
---(e.g. `" 4L 63C"`). Empty outside those modes, and when the statusline being
---drawn belongs to another window (the selection only exists in the current one).
---@return string segment
function M.selection()
	local winid = vim.g.statusline_winid
	if winid and winid ~= vim.api.nvim_get_current_win() then
		return ""
	end
	if not SELECTION_MODES[vim.fn.mode()] then
		return ""
	end
	local lines = math.abs(vim.fn.line("v") - vim.fn.line(".")) + 1
	local chars = vim.fn.wordcount().visual_chars or 0
	return string.format(" %dL %dC", lines, chars)
end

---Search match counter as `" [<current>/<total>]"` (e.g. `" [3/12]"`). Only
---shown while 'hlsearch' highlighting is active (`v:hlsearch == 1`), so it
---disappears after `:nohlsearch`. Counts are capped at `SEARCH_MAXCOUNT`
---(`[>999/>999]`); `?` is shown for the total if the count timed out.
---@return string segment
function M.search()
	local winid = vim.g.statusline_winid
	if winid and winid ~= vim.api.nvim_get_current_win() then
		return ""
	end
	if vim.v.hlsearch == 0 then
		return ""
	end
	local ok, sc = pcall(vim.fn.searchcount, { maxcount = SEARCH_MAXCOUNT, timeout = 100 })
	if not ok or not sc or (sc.total or 0) == 0 then
		return ""
	end
	local max = sc.maxcount
	local cur = sc.current > max and (">" .. max) or tostring(sc.current)
	local total
	if sc.incomplete == 1 then
		total = "?"
	elseif sc.incomplete == 2 or sc.total > max then
		total = ">" .. max
	else
		total = tostring(sc.total)
	end
	return string.format(" [%s/%s]", cur, total)
end

---Install the statusline and the autocmds that keep it up to date.
---
--- * Exposes the module as the global `StlLine`, which the statusline string
---   needs to call `lead`, `major`, `diag`, `selection` and `search` through
---   `v:lua`.
--- * Uses `laststatus=2` (one statusline per window) and turns `showmode` off,
---   since the mode is already in the line, and adds `S` to 'shortmess' to hide
---   the native search count, since the line has its own.
--- * `b:git_branch` and `b:sl_file_size`: refreshed on BufEnter, BufWritePost,
---   FocusGained and DirChanged (the size also on FileChangedShellPost and
---   WinEnter/BufWinEnter).
--- * `g:sl_mode`: refreshed on ModeChanged.
--- * Redraws on mode, diagnostic, macro recording and command-line changes
---   (the latter so the search counter updates after `/`, `?` and `:noh`).
--- * Inactive windows use INACTIVE through a window-local 'statusline', which is
---   cleared again (falling back to the global one) when the window is entered.
function M.setup()
	_G.StlLine = M

	vim.opt.laststatus = 2
	vim.opt.showmode = false
	vim.opt.shortmess:append("S")

	vim.opt.statusline = table.concat({
		"-- %{get(g:, 'sl_mode', '')} -- ",
		"%{v:lua.StlLine.lead()}",
		"%{&diff && winnr('$') > 2 ? '  [' . bufnr() . ']' : ''}",
		"  %<%{bufname() ==# '' ? '[No Name]' : fnamemodify(bufname(), ':p:~')}   %P %m",
		"   L%l C%c",
		"%{v:lua.StlLine.selection()}",
		"%{v:lua.StlLine.search()}",
		"   %{v:lua.StlLine.major()}",
		"   %{get(b:, 'git_branch', '')}",
		" %{v:lua.StlLine.diag()}",
		"%{reg_recording() !=# '' ? 'REC@' . reg_recording() . ' ' : ''}",
		"%=",
		"%{get(t:, 'zoomed', 0) ? '[Z]  ' : ''}",
		"%{get(b:, 'sl_file_size', '')}",
		" ",
	})

	update_mode()

	local group = vim.api.nvim_create_augroup("StatuslineBranch", { clear = true })

	-- On writes and :cd the cached branch labels are dropped: writes may come
	-- from fugitive Git operations (commit/checkout) and :cd changes what the
	-- "current directory" key means for unnamed/special buffers.
	vim.api.nvim_create_autocmd({ "BufWritePost", "DirChanged" }, {
		group = group,
		callback = function()
			branch_cache = {}
		end,
	})

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

	-- CmdlineLeave fires before the command runs, so redraw on the next tick:
	-- by then `v:hlsearch` and the search register reflect `/foo`, `?foo`
	-- or `:nohlsearch`.
	vim.api.nvim_create_autocmd("CmdlineLeave", {
		group = group,
		pattern = { "/", "?", ":" },
		callback = function()
			vim.schedule(function()
				vim.cmd.redrawstatus()
			end)
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
