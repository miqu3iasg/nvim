-- lua/features/todos.lua

-- TODO / FIXME / HACK / BUG / XXX task comments, natively (no plugin).
--
-- The keywords live in comments, where treesitter already colors them, so
-- this module adds no highlighting on purpose: it only provides the search
-- and navigation that todo-comments.nvim used to provide.
--
-- Custom color for one keyword (todo-comments' `keywords` option) is not
-- reproduced: highlighting is deliberately none.
--
-- * M.jump(dir):    jump between matches. If the current quickfix list was
--                   produced by a TODO scan, reuses it (cnext/cprev);
--                   otherwise scans the project first and jumps to the first
--                   match.
-- * M.fzf_search(): fzf-lua live grep restricted to the keywords (used by
--                   <leader>ft, replacing :TodoFzfLua).
--
-- Navigation between results in general (including these scans) uses the
-- ]q / [q quickfix keymaps.
--
-- See: lua/plugins/fzf.lua

local M = {}

-- Word boundary at both ends (`\b...\b` in ripgrep/POSIX grep syntax).
---@type string
local RG_PATTERN = [[\b(TODO|FIXME|HACK|BUG|XXX)\b]]

-- Marker stored in quickfix properties (w:quickfix_title) when the list was
-- produced by a TODO scan, so jump() can tell it apart from other lists.
---@type string
local QF_TITLE = "TODO scan"

-- Directories that are never worth searching; keeps the scan fast.
-- Only combined with rg below; plain grep falls back to the default.
---@type string
local RG_GLOBS = "--glob '!**/.git/**' --glob '!**/node_modules/**' --glob '!**/target/**' "
	.. "--glob '!**/dist/**' --glob '!**/.venv/**' --glob '!**/__pycache__/**' "
	.. "--glob '!*.min.js' --glob '!*.min.css' --glob '!*.lock' --glob '!*.map'"

---Whether the current quickfix list came from a TODO scan.
---@return boolean
local function is_todo_qf()
	local info = vim.fn.getqflist({ title = 0, items = 0 })
	return info.title == QF_TITLE and #info.items > 0
end

---Run the TODO scan (rg when available, grep otherwise) filling the quickfix
---list, then jump `dir` (1 forwards, -1 backwards) inside it.
---@param dir integer
local function scan_and_jump(dir)
	if vim.fn.executable("rg") == 1 then
		vim.o.grepprg = "rg --vimgrep --smart-case " .. RG_GLOBS
		vim.o.grepformat = "%f:%l:%c:%m,%f:%l:%m"
	else
		vim.o.grepprg = "grep -rn --binary-files=without-match --exclude-dir=.git --exclude-dir=node_modules $* /dev/null"
		vim.o.grepformat = "%f:%l:%m"
	end

	-- silent! keeps the "press enter" prompt and hit-errors away
	vim.cmd.keepjumps("silent! grep! " .. vim.fn.shellescape(RG_PATTERN))
	-- restore the user's grepprg from keymaps/editing.lua (set on startup)
	if vim.fn.executable("rg") == 1 then
		vim.o.grepprg = "rg --vimgrep"
	end
	vim.o.grepformat = ""

	vim.fn.setqflist({}, "a", { title = QF_TITLE })
	if vim.fn.getqflist({ size = 0 }).size == 0 then
		vim.notify("TODO scan: no matches", vim.log.levels.INFO)
		return
	end
	vim.cmd(dir == 1 and "cfirst" or "clast")
	vim.cmd("normal! zz")
end

---Jump to the next (`dir = 1`) or previous (`dir = -1`) TODO.
---Uses the existing quickfix list when it is a TODO scan, otherwise the list
---belongs to something else and a fresh scan is run.
---@param dir integer
function M.jump(dir)
	if is_todo_qf() then
		if dir == 1 then
			vim.cmd("try | cnext | catch | cfirst | endtry")
		else
			vim.cmd("try | cprev | catch | clast | endtry")
		end
		vim.cmd("normal! zz")
		return
	end
	scan_and_jump(dir)
end

---fzf-lua live grep restricted to the TODO keywords (replaces :TodoFzfLua).
function M.fzf_search()
	require("fzf-lua").grep({
		search = RG_PATTERN,
		no_esc = true,
		prompt = "TODO/FIXME> ",
		silent = true, -- previewer cannot map every ripgrep regex to a vim pattern
	})
end

function M.setup()
	vim.keymap.set("n", "]t", function()
		M.jump(1)
	end, { desc = "Next todo comment" })

	vim.keymap.set("n", "[t", function()
		M.jump(-1)
	end, { desc = "Previous todo comment" })

	vim.api.nvim_create_user_command("Todos", function()
		M.jump(1)
	end, { desc = "Scan the project for TODO/FIXME/HACK/BUG/XXX and jump to the first one" })
end

return M
