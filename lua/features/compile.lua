-- lua/features/compile.lua

-- Emacs-like `:Compile`, natively (no plugin). Runs a build command
-- asynchronously, streaming its output into a `*compilation*` buffer in a
-- bottom split. When the command fails, the output is parsed into the quickfix
-- list, so errors are navigated with the usual quickfix motions.
--
-- State is kept per working directory: one running process at a time (starting
-- a new compile in the same directory kills the previous one) and one "last
-- command", which `:Recompile` reruns. Commands run through `sh -c`, so shell
-- syntax works.
--
-- Without arguments, `:Compile` prompts for a command pre-filled with the
-- default for the current filetype (see `DEFAULT_COMMAND`). Only gcc/clang,
-- javac and Python traceback output is parsed into quickfix; anything else
-- still shows in the buffer but produces no entries (see `ERRORFORMAT`).
--
-- The `*compilation*` buffer uses the `qf` filetype so that the
-- `cg/close_utility_buffers` autocmd gives it the usual `q`/`<Esc>` close
-- behavior, and the quickfix motions `]q` / `[q` come from the search keymaps.
--
-- Commands:
--   :Compile {cmd}        run {cmd}, or prompt when no argument is given
--   :Recompile            rerun the last command of the current cwd
--   :CompileInterrupt     stop the command of the current cwd
--
-- Usage:
--   require("features.compile").setup()
--
-- See: lua/config/autocmds.lua
-- See: lua/config/keymaps/search.lua

local M = {}

-- Name of the output buffer.
---@type string
local BUFFER_NAME = "*compilation*"

-- Compilation commands per filetype, as the previous setup had them.
-- The "*" key is the fallback for filetypes without an entry.
---@type table<string, string>
local DEFAULT_COMMAND = {
	["*"] = "make -k ",
	python = "python %",
	lua = "lua %",
	c = "cc -o %:r.out % && ./%:r.out",
	cpp = "c++ -std=c++23 -o %:r.out % && ./%:r.out",
	java = "javac % && java %:r",
	go = "go run %",
}

-- 'errorformat' for parsing the output into quickfix entries, buffer-locally
-- on *compilation*. Covers the gcc/clang ("file:line:col: message") and
-- javac ("file:line: message") styles, plus Python tracebacks (each
-- "File ..., line ..., in ..." frame becomes an entry; the indented source
-- lines are context). Non-indented Python exception lines and all other
-- noise (make info, blanks) are ignored with %-G. Unmatched output is
-- dropped, keeping the list clean.
---@type string
local ERRORFORMAT = table.concat({
	-- gcc/clang
	"%f:%l:%c: %m",
	-- javac, plain "file:line: message"
	"%f:%l: %m",
	-- Python traceback frames (message text is not captured)
	'%A  File "%f"\\, line %l\\, in %.%#',
	"%-C  %.%#",
	"--In file included from %.%#",
	"%-G%.%#",
}, ",")

-- One running process per cwd (starting a new compile of the same directory
-- replaces the previous one) and the last command per cwd for :Recompile.
---@type table<string, vim.SystemObj>
local running = {}

---@type table<string, string>
local last_command = {}

---@type integer?
local compilation_buf = nil

---Return the default command for the current buffer's filetype, with "%"
---(file name) and "%:r" (name without extension) expanded word by word, like
---compile-mode's bang expansion did.
---@return string
local function default_for_ft()
	local cmd = DEFAULT_COMMAND[vim.bo.filetype] or DEFAULT_COMMAND["*"] or ""

	local fname = vim.fn.expand("%")
	local base = vim.fn.expand("%:r")

	local words = {}
	for word in cmd:gmatch("%S+") do
		if word == "%" then
			table.insert(words, fname)
		elseif word == "%:r" then
			table.insert(words, base)
		else
			table.insert(words, word)
		end
	end
	return table.concat(words, " ")
end

---Create (or reuse) the *compilation* buffer and show it in a bottom split.
---Unlisted, nofile, wiped when hidden and with a buffer-local 'errorformat';
---filetype "qf" so the close_utility_buffers autocmd gives it the usual
---q/<Esc> close behavior.
---@return integer buf
local function open_window()
	local buf = compilation_buf
	if not (buf and vim.api.nvim_buf_is_valid(buf)) then
		buf = vim.api.nvim_create_buf(false, true)
		compilation_buf = buf
		vim.api.nvim_buf_set_name(buf, BUFFER_NAME)
	end

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].swapfile = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buflisted = false
	vim.bo[buf].errorformat = ERRORFORMAT
	vim.bo[buf].modifiable = true
	-- filetype "qf": the close_utility_buffers autocmd then provides the
	-- q/<Esc> window close behavior and drops it from the buffer list
	vim.bo[buf].filetype = "qf"

	vim.cmd("rightbelow 25split")
	vim.cmd("buffer " .. buf)

	return buf
end

---Append lines to the compilation buffer and autoscroll every window showing
---it (like compile-mode's auto_scroll).
---@param buf integer
---@param lines string[]
local function append(buf, lines)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	vim.bo[buf].modifiable = true
	local last = vim.api.nvim_buf_line_count(buf)
	vim.api.nvim_buf_set_lines(buf, last, last, false, lines)
	vim.bo[buf].modifiable = false

	for _, win in ipairs(vim.fn.win_findbuf(buf)) do
		vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
	end
end

---Called when the job ends. Adds the exit status line, and on failure fills
---the quickfix list from the compilation buffer (:cbuffer uses the buffer's
---local 'errorformat'); navigation is done with ]q / [q.
---@param buf integer
---@param code integer
local function finish(buf, code)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	append(buf, { ("[Exited %d]"):format(code) })

	if code ~= 0 then
		-- Parse the compilation buffer into the quickfix list, with the
		-- compile errorformat given explicitly (the quickfix commands would
		-- instead use the 'errorformat' of the current window).
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		pcall(vim.fn.setqflist, {}, " ", {
			lines = lines,
			efm = ERRORFORMAT,
			title = "compilation",
		})
	end
end

---Run `cmd` in `cwd`, streaming stdout/stderr into *compilation*.
---@param cmd string
---@param cwd string
function M.command(cmd, cwd)
	-- A new compile of the same cwd replaces the running one
	local prev = running[cwd]
	if prev then
		running[cwd] = nil
		prev:kill("sigkill")
	end

	last_command[cwd] = cmd

	local buf = open_window()
	append(buf, { cwd .. " > " .. cmd, "" })

	local obj = vim.system({ "sh", "-c", cmd }, {
		cwd = cwd,
		text = true,
		stdout = function(_, data)
			if data and #vim.trim(data) > 0 then
				vim.schedule(function()
					append(buf, vim.split(data, "\n", { trimempty = true }))
				end)
			end
		end,
		stderr = function(_, data)
			if data and #vim.trim(data) > 0 then
				vim.schedule(function()
					append(buf, vim.split(data, "\n", { trimempty = true }))
				end)
			end
		end,
	}, function(res)
		-- Only the newest process of this cwd owns the state; a replaced
		-- process just reports its output.
		if running[cwd] == obj then
			running[cwd] = nil
		end
		vim.schedule(function()
			finish(buf, res.code)
		end)
	end)

	running[cwd] = obj
end

---Prompt for a compilation command (pre-filled with the current filetype's
---default) and run it.
function M.prompt()
	local cwd = vim.uv.cwd() or "."
	vim.ui.input({
		prompt = "Compile: ",
		default = last_command[cwd] or default_for_ft(),
	}, function(input)
		if input and input ~= "" then
			M.command(input, cwd)
		end
	end)
end

---Recompile: rerun the last command of the current cwd, or prompt.
function M.recompile()
	local cwd = vim.uv.cwd() or "."
	if last_command[cwd] then
		M.command(last_command[cwd], cwd)
	else
		M.prompt()
	end
end

---Interrupt the command running in the current directory.
function M.interrupt()
	local cwd = vim.uv.cwd() or "."
	local obj = running[cwd]
	if not obj then
		return
	end
	running[cwd] = nil
	obj:kill("sigkill")
	if compilation_buf and vim.api.nvim_buf_is_valid(compilation_buf) then
		append(compilation_buf, { "[Interrupted]" })
	end
end

function M.setup()
	vim.api.nvim_create_user_command("Compile", function(opts)
		if opts.args ~= "" then
			M.command(opts.args, vim.uv.cwd() or ".")
		else
			M.prompt()
		end
	end, {
		nargs = "?",
		desc = "Compile: run a build command asynchronously into *compilation*",
	})

	vim.api.nvim_create_user_command("Recompile", function()
		M.recompile()
	end, { desc = "Compile: rerun the last command of this directory" })

	vim.api.nvim_create_user_command("CompileInterrupt", function()
		M.interrupt()
	end, { desc = "Compile: interrupt the running command" })

	local km = vim.keymap.set
	km("n", "<leader>cc", M.prompt, { desc = "Compile (prompt with default)" })
	km("n", "<leader>cr", M.recompile, { desc = "Recompile (last command)" })
	km("n", "<leader>ck", M.interrupt, { desc = "Compile: interrupt" })
end

return M
