-- lua/features/statusline.lua

-- Native statusline built on the 'statusline' option, with no plugin required.
-- The active window shows editor state, position, search and selection info,
-- git branch, diagnostics and macro recording. Inactive windows get a reduced
-- version.
--
-- Costly or asynchronous pieces are not computed on every redraw. The mode, git
-- branch and file size are stored in `vim.g.sl_mode`, `vim.b.git_branch` and
-- `vim.b.sl_file_size` and refreshed by autocmds. The branch is looked up
-- asynchronously and cached per directory for a short time, so a change made
-- outside Neovim can take a few seconds to show up. The file size is read from
-- disk, so it is stale until the file is saved, and it is only shown for files
-- of at least `FILE_SIZE_MIN` bytes.
--
-- The segment functions are exposed through the global `StlLine` because the
-- statusline string calls them through `v:lua`. The zoom indicator reads
-- `vim.t.zoomed`, which is set by the window zoom feature.
--
-- Git must be installed for the branch segment, which stays empty without it.
-- `setup()` must be called once.
--
-- See: lua/features/window_zoom.lua
-- See: :help 'statusline'

local M = {}

-- Keyed by the directory the git command runs in, so frequent BufEnter and
-- WinEnter events reuse the label instead of spawning git every time.
---@type table<string, { label: string, ts: number }>
local branch_cache = {}

---Seconds a cached branch label is trusted before git is queried again.
---@type number
local BRANCH_TTL = 30

---Size in bytes below which the file size segment stays empty (1 MiB).
---@type number
local FILE_SIZE_MIN = 1024 * 1024

-- Beyond this many matches the search total is shown as `>999`, which keeps the
-- redraw cheap in huge files.
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

---Modes in which a selection exists and its size is shown.
---@type table<string, boolean>
local SELECTION_MODES = {
	v = true,
	V = true,
	["\22"] = true,
	s = true,
	S = true,
	["\19"] = true,
}

-- Set window-locally on WinLeave and cleared on WinEnter, so unfocused windows
-- fall back to this reduced line.
---@type string
local INACTIVE =
	"  %{v:lua.StlLine.lead()}  %P %<%{bufname() ==# '' ? '[No Name]' : fnamemodify(bufname(), ':p:~')}   L%l C%c %="

---Store the branch label in `b:git_branch` and redraw the statusline. Scheduled,
---so it is safe to call from a `vim.system` callback.
---@param buf integer
---@param branch string Branch name or `@<sha>`. An empty string clears the label.
local function set_branch(buf, branch)
	vim.schedule(function()
		if vim.api.nvim_buf_is_valid(buf) then
			vim.b[buf].git_branch = branch ~= "" and ("Git-" .. branch .. " ") or ""
			vim.cmd.redrawstatus()
		end
	end)
end

---Run `git <args>` asynchronously in `dir`.
---@param args string[] Git arguments, without the leading `git`.
---@param dir string
---@param cb fun(res: vim.SystemCompleted)
---@return boolean ok `false` if the process could not be started.
---@return vim.SystemObj|string result
local function git(args, dir, cb)
	local cmd = vim.list_extend({ "git" }, args)
	return pcall(vim.system, cmd, { cwd = dir, text = true }, cb)
end

---Refresh `b:git_branch` for `buf` without blocking the editor.
---
---The repository is looked up from the folder of the file. Special and unnamed
---buffers use the cwd. On a detached HEAD the short commit hash is shown
---instead, as `@abc1234`. The label is empty outside a repository or when git
---is missing.
---@param buf? integer Defaults to the current buffer.
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

	local cached = branch_cache[dir]
	if cached and (os.clock() - cached.ts) < BRANCH_TTL then
		vim.b[buf].git_branch = cached.label
		return
	end
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

	-- The new label arrives asynchronously, so the old one stays visible
	-- meanwhile to avoid flicker when the cache expires.
	if started and stale ~= "" then
		vim.b[buf].git_branch = stale
	end
end

---@param buf integer
---@param size_str string
local function set_file_size(buf, size_str)
	if vim.api.nvim_buf_is_valid(buf) then
		vim.b[buf].sl_file_size = size_str
	end
end

---Refresh `b:sl_file_size` with the size of the file on disk, padded with
---spaces and using the largest unit below 1024, such as `" 1.5M "`. It stays
---empty for small files, unnamed and special buffers, empty files and files that
---do not exist yet.
---@param buf? integer Defaults to the current buffer.
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

---Store the label of the current mode in `g:sl_mode`. The mode is looked up by
---its full code, then by its first two characters and then by the first one, so
---`niI` resolves to NORMAL. An unknown mode is shown as its raw code.
local function update_mode()
	local m = vim.api.nvim_get_mode().mode
	vim.g.sl_mode = MODES[m] or MODES[m:sub(1, 2)] or MODES[m:sub(1, 1)] or m
end

---Leading indicator made of an encoding character, an end-of-line character, a
---status marker and a dash. The encoding is `U` for UTF, `1` for latin and `-`
---otherwise. The end-of-line is `:` for unix, `\` for dos and `/` for mac. The
---status is `%%` when read-only or not modifiable, `**` when modified and `--`
---otherwise.
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

---Capitalized filetype in parentheses, such as `(Lua)`, or `(Fundamental)` when
---there is no filetype.
---@return string
function M.major()
	local ft = vim.bo.filetype
	if ft == "" then
		return "(Fundamental)"
	end
	return "(" .. ft:sub(1, 1):upper() .. ft:sub(2) .. ")"
end

---Diagnostic counts of the current buffer as `[E<errors> W<warnings>] `, or an
---empty string when there are no errors or warnings.
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

---Size of the current Visual or Select selection, such as `" 4L 63C"`. Empty
---outside those modes and when the line being drawn belongs to another window.
---@return string
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

---Search match counter such as `" [3/12]"`. It is only shown while 'hlsearch'
---highlighting is active, so it disappears after `:nohlsearch`. Counts are
---capped at `SEARCH_MAXCOUNT`, and the total is `?` when the count timed out.
---@return string
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
---The module is exposed as the global `StlLine`, which the statusline string
---needs to reach the segment functions through `v:lua`. The mode is already in
---the line, so `showmode` is turned off, and `S` is added to 'shortmess' to hide
---the native search count in favor of the one in the line.
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

	-- Writes may come from fugitive operations such as commit or checkout, and
	-- `:cd` changes what the current directory means for unnamed and special
	-- buffers, so the cached labels are dropped in both cases.
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

	-- CmdlineLeave fires before the command runs, so the redraw is scheduled to
	-- let `v:hlsearch` and the search register reflect the new state.
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
