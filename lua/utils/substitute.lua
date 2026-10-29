-- lua/utils/substitute.lua

-- Helpers that pre-fill the command line with a :substitute / project-wide
-- substitution and leave the cursor between the pattern and the replacement.

local M = {}

local PATTERN_SPECIALS = "\\/.*$^~[]"

---Escape `text` for use in a (magic) search pattern.
---@param text string
---@param whole_word? boolean wrap in \< \>
---@return string
function M.escape_pattern(text, whole_word)
	local p = vim.fn.escape(text, PATTERN_SPECIALS)
	return whole_word and ("\\<" .. p .. "\\>") or p
end

-- Make `s` safe to feed as typed keys:
--  * "<" would be parsed as a key notation (e.g. "<CR>"), so use "<lt>"
--  * control chars (e.g. a literal Tab, which triggers completion) are quoted with <C-v>
local function to_keys(s)
	s = s:gsub("<", "<lt>")
	return (s:gsub("%c", function(c)
		return "<C-v>" .. c
	end))
end

---Open the cmdline with `head .. tail`, cursor placed right after `head`'s
---last char + 1 slash, i.e. between the two slashes of the trailing "//".
---`tail` must be plain ASCII without key notation (it starts with "//").
---@param head string
---@param tail string
local function feed_cmdline(head, tail)
	local keys = ":" .. to_keys(head .. tail) .. string.rep("<Left>", #tail - 1)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

---Substitute `text` in the given scope ("%" for buffer, "s" for line), confirming each match.
---@param scope string
---@param text string
---@param whole_word? boolean
function M.prompt(scope, text, whole_word)
	if text == "" then
		return
	end
	feed_cmdline(("keeppatterns %s/%s"):format(scope, M.escape_pattern(text, whole_word)), "//gc")
end

---Substitute `text` across the whole project (rg -> quickfix -> cfdo).
---@param text string
---@param whole_word? boolean
function M.project(text, whole_word)
	if text == "" then
		return
	end
	if text:find("[\n|]") then
		vim.notify("Project substitution: multi-line or '|' text is not supported", vim.log.levels.WARN)
		return
	end
	if not vim.o.grepprg:find("^rg") then
		vim.notify("Project substitution needs ripgrep ('rg') as 'grepprg'", vim.log.levels.ERROR)
		return
	end

	local grep = ("silent grep! --fixed-strings --case-sensitive %s-- %s"):format(
		whole_word and "--word-regexp " or "",
		vim.fn.shellescape(text, true)
	)
	-- \C keeps :s case-sensitive, matching rg's --case-sensitive
	local head = grep .. " | cfdo keeppatterns %s/\\C" .. M.escape_pattern(text, whole_word)
	feed_cmdline(head, "//gce | update")
end

---Substitute a literal (possibly multi-line) selection in the buffer, replacement left empty.
---@param text string
function M.selection(text)
	if text == "" then
		return
	end
	local p = vim.fn.escape(text, "\\/")
	-- in \V, a leading ^ and a trailing $ are still special
	p = p:gsub("^%^", "\\^"):gsub("%$$", "\\$")
	p = p:gsub("\n", "\\n")
	feed_cmdline("%s/\\V" .. p, "//g")
end

---Return the current visual selection as text and leave visual mode.
---Does not touch any register. Requires Neovim 0.10+.
---@return string
function M.get_visual()
	local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
	vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	return table.concat(lines, "\n")
end

return M
