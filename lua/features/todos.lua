-- lua/features/todos.lua

-- Native search and navigation for task comments such as TODO, FIXME, HACK, BUG
-- and XXX. It adds no highlighting on purpose, since the keywords live in
-- comments that treesitter already colors.
--
-- The project is scanned with ripgrep, falling back to grep, into a quickfix
-- list tagged so that it can be told apart from lists produced by something
-- else. When the current list is a TODO scan it is reused, otherwise a fresh
-- scan runs and jumps to the first match.
--
-- The scan temporarily overrides 'grepprg' and 'grepformat' and then restores
-- 'grepprg' to the value set in `lua/config/options.lua`, so both must stay in
-- sync with the restore in `scan_and_jump`.
--
-- The live grep restricted to the keywords requires fzf-lua. ripgrep is
-- optional but recommended, since the grep fallback excludes fewer directories.
--
-- `setup()` registers the `:Todos` command and the navigation keymaps, and must
-- be called once.
--
-- See: lua/plugins/fzf.lua
-- See: lua/config/options.lua
-- See: https://github.com/james-orcales/james-orcales/blob/main/home/.config/nvim/init.lua

local M = {}

---@type string
local RG_PATTERN = [[\b(TODO|FIXME|HACK|BUG|XXX)\b]]

---Title stored in the quickfix list, used to recognize lists made by a scan.
---@type string
local QF_TITLE = "TODO scan"

-- The globs are single-quoted because 'grepprg' runs through the user's shell,
-- and zsh would otherwise expand `!**` itself and fail.
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

---Scan the project into the quickfix list and jump to its first match, or to
---its last one when `dir` is -1.
---@param dir integer
local function scan_and_jump(dir)
	if vim.fn.executable("rg") == 1 then
		vim.o.grepprg = "rg --vimgrep --smart-case " .. RG_GLOBS
		vim.o.grepformat = "%f:%l:%c:%m,%f:%l:%m"
	else
		vim.o.grepprg =
			"grep -rn --binary-files=without-match --exclude-dir=.git --exclude-dir=node_modules $* /dev/null"
		vim.o.grepformat = "%f:%l:%m"
	end

	-- The pattern is in double quotes because single quotes are a mark to the Ex
	-- parser, and the pipes are escaped because `:grep` ends its arguments at an
	-- unescaped `|`. ripgrep still reads `\|` as alternation.
	vim.cmd([[keepjumps silent! grep! "\b(TODO\|FIXME\|HACK\|BUG\|XXX)\b"]])
	-- Restores the value set in lua/config/options.lua.
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

---Jump to the next task comment when `dir` is 1, or to the previous one when it
---is -1. A fresh scan runs unless the current quickfix list is already a TODO
---scan.
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

---Live grep restricted to the task keywords.
function M.fzf_search()
	require("fzf-lua").grep({
		search = RG_PATTERN,
		no_esc = true,
		prompt = "TODO/FIXME> ",
		-- The previewer cannot map every ripgrep regex to a vim pattern.
		silent = true,
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
