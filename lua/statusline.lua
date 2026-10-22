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

local INACTIVE = " %<%{bufname() ==# '' ? '[No Name]' : fnamemodify(bufname(), ':p:~')} %m%=%l:%c "

local function set_branch(buf, branch)
	vim.schedule(function()
		if vim.api.nvim_buf_is_valid(buf) then
			vim.b[buf].git_branch = branch ~= "" and (" Git:" .. branch .. " ") or ""
			vim.cmd.redrawstatus()
		end
	end)
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

local function update_mode()
	local m = vim.api.nvim_get_mode().mode
	vim.g.sl_mode = MODES[m] or MODES[m:sub(1, 2)] or MODES[m:sub(1, 1)] or m
end

function M.setup()
	vim.opt.laststatus = 2
	vim.opt.showmode = true

	vim.opt.statusline = table.concat({
		-- "-- %{g:sl_mode} --",
		"%{&diff && winnr('$') > 2 ? '  [' . bufnr() . ']' : ''}",
		"%<%{bufname() ==# '' ? '[No Name]' : fnamemodify(bufname(), ':p:~')}%r%m",
		-- " %{get(b:, 'git_branch', '')}",
		"%=",
		"%{get(t:, 'zoom', 0) ? '[Z]  ' : ''}",
		"%{&filetype}   ",
		-- "%{(&fenc !=# '' && &fenc !=# 'utf-8') || &ff !=# 'unix' ? '  ' . (&fenc ==# '' ? 'utf-8' : &fenc) . '[' . &ff . ']' : ''}",
		"  %{get(b:, 'sl_file_size', '')}",
		"  %-8.(%l,%c%)",
		"  %P ",
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

	vim.api.nvim_create_autocmd({ "FileChangedShellPost" }, {
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
