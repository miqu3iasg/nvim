-- after/ftplugin/markdown.lua

-- Runs once per markdown buffer. Every mapping below is buffer-local, so it
-- needs the real buffer number (a nil `buffer` would make it global)
local bufnr = vim.api.nvim_get_current_buf()

-- Wrap long lines visually at word boundaries and keep wrapped lines indented
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.fillchars = { eob = " " }

-- Do not hide markdown syntax (links, emphasis)
vim.opt_local.conceallevel = 0
vim.opt_local.concealcursor = ""

-- Spell check is off by default but the dictionaries are ready
vim.opt_local.spell = false
vim.opt_local.spelllang = { "pt_br", "en_us" }

-- Lines are only broken at 100 columns when you format
vim.opt_local.textwidth = 100
vim.opt_local.formatoptions:remove({ "t", "l" })
vim.opt_local.formatoptions:append("n")

-- Keep the UI minimal for prose
vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = "no"

vim.opt_local.shiftwidth = 4

-- :Pandoc, :PandocPreview and <localleader>p* keymaps
require("shared.pandoc").setup()

-- Buffer-local, silent keymap helper
local function map(mode, lhs, rhs, desc, opts)
	vim.keymap.set(
		mode,
		lhs,
		rhs,
		vim.tbl_extend("force", {
			buffer = bufnr,
			silent = true,
			desc = desc,
		}, opts or {})
	)
end

-- Helpers

-- Fenced blocks of the buffer as { start, stop, closed }. An unclosed block
-- runs to the last line
local function fence_blocks(lines)
	local blocks, open = {}, nil
	for i, line in ipairs(lines) do
		local fence = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
		if fence then
			if not open then
				open = { start = i, marker = fence:sub(1, 1), len = #fence }
			elseif fence:sub(1, 1) == open.marker and #fence >= open.len and line:match("^%s*[`~]+%s*$") then
				blocks[#blocks + 1] = { start = open.start, stop = i, closed = true }
				open = nil
			end
		end
	end
	if open then
		blocks[#blocks + 1] = { start = open.start, stop = #lines, closed = false }
	end
	return blocks
end

local function block_at(blocks, row)
	for _, block in ipairs(blocks) do
		if row >= block.start and row <= block.stop then
			return block
		end
	end
end

-- Current visual selection when it is inside one line. Leaves visual mode and
-- returns line number, text before, selected text and text after
local function single_line_selection(what)
	local mode = vim.fn.mode()
	local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
	local srow, scol, erow, ecol = s[2], s[3], e[2], e[3]
	if mode == "\22" or srow ~= erow then
		vim.notify("Markdown: select text inside a single line to " .. what, vim.log.levels.WARN)
		return
	end
	if scol > ecol then
		scol, ecol = ecol, scol
	end
	local line = vim.fn.getline(srow)
	if mode == "V" then
		scol, ecol = 1, #line
	end
	ecol = math.min(ecol, #line)
	ecol = ecol + vim.str_utf_end(line, ecol) -- include the whole last character
	vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	return srow, line:sub(1, scol - 1), line:sub(scol, ecol), line:sub(ecol + 1)
end

-- Insert `text` after the cursor (like `a`) and start typing `offset` bytes
-- into it
local function insert_template(text, offset)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_get_current_line()
	local after = line == "" and 0 or col + 1 + vim.str_utf_end(line, col + 1)
	vim.api.nvim_set_current_line(line:sub(1, after) .. text .. line:sub(after + 1))
	vim.api.nvim_win_set_cursor(0, { row, after + offset })
	vim.cmd("startinsert")
end

-- Wrap the visual selection between two markers and stay in normal mode
local function wrap_selection(open, close, what)
	local l, before, selected, after = single_line_selection(what)
	if not l then
		return
	end
	vim.fn.setline(l, before .. open .. selected .. close .. after)
end

-- Typing

-- Break the undo sequence at `,` and `.` so undo stops at sentence
-- boundaries instead of undoing a whole paragraph at once
map("i", ",", ",<C-g>u", "Break undo sequence at comma")
map("i", ".", ".<C-g>u", "Break undo sequence at period")

-- Visual-line motion (matters with 'wrap'); a count keeps physical lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", "Move down by visual line", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", "Move up by visual line", { expr = true })

-- Spell

map("n", "<localleader>ss", function()
	vim.opt_local.spell = not vim.opt_local.spell:get()
end, "Toggle spell check")

local spell_sets = { { "pt_br", "en_us" }, { "pt_br" }, { "en_us" } }
local spell_index = 1

map("n", "<localleader>sl", function()
	spell_index = spell_index % #spell_sets + 1
	vim.opt_local.spelllang = spell_sets[spell_index]
	vim.opt_local.spell = true
	vim.notify("spelllang: " .. table.concat(spell_sets[spell_index], ", "))
end, "Cycle spell language")

-- Fix the previous misspelled word with the first suggestion without leaving insert mode
map("i", "<C-l>", "<c-g>u<Esc>[s1z=`]a<c-g>u", "Fix previous spelling mistake")

-- Lists and checkboxes

local function parse_item(line)
	local indent, marker, rest = line:match("^(%s*)([-*+])%s+(.*)$")
	if not indent then
		indent, marker, rest = line:match("^(%s*)(%d+[.)])%s+(.*)$")
	end
	return indent, marker, rest
end

-- Toggle checkboxes
local function toggle_checkbox_line(lnum)
	local line = vim.fn.getline(lnum)
	if line:match("^%s*$") then
		return
	end
	local indent, marker, rest = parse_item(line)
	if not indent then
		local lead, text = line:match("^(%s*)(.*)$")
		vim.fn.setline(lnum, lead .. "- [ ] " .. text)
		return
	end
	local box, after = rest:match("^%[(.)%](.*)$")
	if box and (after == "" or after:match("^%s")) then
		box = (box == " ") and "x" or " "
		vim.fn.setline(lnum, indent .. marker .. " [" .. box .. "]" .. after)
	else
		vim.fn.setline(lnum, indent .. marker .. " [ ] " .. rest)
	end
end

-- Works in any markdown file
-- that many lines (3<leader>lt); in visual mode every selected line
map("n", "<leader>lt", function()
	local row = vim.fn.line(".")
	local last = math.min(row + vim.v.count1 - 1, vim.fn.line("$"))
	for lnum = row, last do
		toggle_checkbox_line(lnum)
	end
end, "Toggle checkbox")

map("x", "<leader>lt", function()
	local first, last = vim.fn.line("v"), vim.fn.line(".")
	if first > last then
		first, last = last, first
	end
	vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
	for lnum = first, last do
		toggle_checkbox_line(lnum)
	end
end, "Toggle checkbox on selected lines")

-- Inserting

-- Insert an empty fenced block below the cursor and start typing inside it.
map("n", "<leader>ik", function()
	local row = vim.fn.line(".")
	vim.api.nvim_buf_set_lines(bufnr, row, row, false, { "```", "", "```" })
	vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
	vim.cmd("startinsert")
end, "Insert code block")

-- Yank the content of the block under the cursor, without the fences
map("n", "yc", function()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local block = block_at(fence_blocks(lines), vim.fn.line("."))

	if not block then
		vim.notify("Markdown: cursor is not inside a code block", vim.log.levels.WARN)
		return
	end

	local first = block.start + 1
	local last = block.closed and block.stop - 1 or block.stop
	local content = first <= last and vim.list_slice(lines, first, last) or {}
	vim.fn.setreg("+", table.concat(content, "\n") .. "\n")
end, "Yank code block content to clipboard")

-- Turn a single-line selection into [selection]() and start typing the url
map("x", "<leader>il", function()
	local l, before, selected, after = single_line_selection("link")
	if not l then
		return
	end
	vim.fn.setline(l, before .. "[" .. selected .. "]()" .. after)
	vim.api.nvim_win_set_cursor(0, { l, #before + #selected + 3 })
	vim.cmd("startinsert")
end, "Wrap selection as markdown link")

-- Insert an empty []() and start typing the link text
map("n", "<leader>il", function()
	insert_template("[]()", 1)
end, "Insert markdown link")

-- Wrap a single-line selection as [[selection]]
map("x", "<leader>iw", function()
	wrap_selection("[[", "]]", "wiki link")
end, "Wrap selection as wiki link")

-- Insert an empty [[]] and start typing inside it
map("n", "<leader>iw", function()
	insert_template("[[]]", 2)
end, "Insert wiki link")

-- Insert a citation [@] and open the key completion
-- See: shared/citekeys.lua
map("n", "<leader>ir", function()
	insert_template("[@]", 2)
	vim.schedule(function()
		local ok, blink = pcall(require, "blink.cmp")
		if ok then
			blink.show()
		end
	end)
end, "Insert citation")

-- Insert an inline footnote ^[] and start typing it
map("n", "<leader>if", function()
	insert_template("^[]", 2)
end, "Insert inline footnote")

-- Emphasis for a single-line selection
map("x", "<leader>ib", function()
	wrap_selection("**", "**", "make it bold")
end, "Bold selection")

map("x", "<leader>ie", function()
	wrap_selection("*", "*", "make it italic")
end, "Italic selection")

map("x", "<leader>ic", function()
	wrap_selection("`", "`", "make it inline code")
end, "Inline code selection")
