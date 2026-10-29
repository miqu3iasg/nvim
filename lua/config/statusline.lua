local M = {}

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

local INACTIVE =
	"  %{v:lua.StlLine.lead()}  %<%{bufname() ==# '' ? '[No Name]' : fnamemodify(bufname(), ':p:~')}   %P L%l C%c %="

local function set_branch(buf, branch)
	vim.schedule(function()
		if vim.api.nvim_buf_is_valid(buf) then
			vim.b[buf].git_branch = branch ~= "" and ("Git-" .. branch .. " ") or ""
			vim.cmd.redrawstatus()
		end
	end)
end

local function git(args, dir, cb)
	local cmd = vim.list_extend({ "git" }, args)
	return pcall(vim.system, cmd, { cwd = dir, text = true }, cb)
end

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

local function set_file_size(buf, size_str)
	if vim.api.nvim_buf_is_valid(buf) then
		vim.b[buf].sl_file_size = size_str
	end
end

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

local function update_mode()
	local m = vim.api.nvim_get_mode().mode
	vim.g.sl_mode = MODES[m] or MODES[m:sub(1, 2)] or MODES[m:sub(1, 1)] or m
end

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

function M.major()
	local ft = vim.bo.filetype
	if ft == "" then
		return "(Fundamental)"
	end
	return "(" .. ft:sub(1, 1):upper() .. ft:sub(2) .. ")"
end

function M.diag()
	local c = vim.diagnostic.count(0)
	local e = c[vim.diagnostic.severity.ERROR] or 0
	local w = c[vim.diagnostic.severity.WARN] or 0
	if e == 0 and w == 0 then
		return ""
	end
	return string.format("[E%d W%d] ", e, w)
end

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
