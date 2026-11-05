-- lua/features/markdown_lists.lua

-- Native list editing for Markdown buffers, plus the formatter post-processing
-- that keeps list markers and indentation the way they were written.
--
-- Every list operation works in normal mode (current line, accepts a count) and
-- in visual mode (selected lines). In visual mode the selection stays active, so
-- a mapping can be pressed repeatedly, e.g. to cycle through the list types.
--
-- Settings (all optional):
--   vim.g.markdown_list_bullet     marker of new bullets: "-" (default), "*" or "+"
--   vim.g.markdown_list_delimiter  delimiter of new numbered items: "." (default) or ")"
--   vim.b.markdown_list_bullet     buffer-local version of the bullet setting
--   vim.b.markdown_list_delimiter  buffer-local version of the delimiter setting
--
-- Usage:
--   local lists = require("features.markdown_lists")
--   vim.keymap.set({ "n", "x" }, "<localleader>lb", lists.action(lists.toggle, "bullet"))
--   vim.keymap.set({ "n", "x" }, "<localleader>ll", lists.action(lists.cycle, 1))
--
-- The formatter helpers (`bullet_markers`, `restore_bullets`, `tabify`) are used
-- by the markdown formatters in `lua/plugins/formatting.lua`.

local M = {}

-- Types

---List type of a line.
---@alias MarkdownLists.Type
---| "none" plain text
---| "bullet" `- item`
---| "number" `1. item`
---| "check" `- [ ] item`

---One parsed line. Fields marked with `item` are only set when `kind == "item"`.
---@class MarkdownLists.Line
---@field kind "blank"|"hr"|"text"|"item"
---@field indent string leading whitespace
---@field text string content without the list prefix
---@field ordered? boolean `item`: numbered (`1.`) instead of bullet (`-`)
---@field marker? string `item`: `-`, `*` or `+` for bullets; `.` or `)` for numbered items
---@field num? integer `item`: number of a numbered item
---@field box? string `item`: `" "`, `"x"` or `"X"` when the item is a task, `nil` otherwise

---A line selected for an operation.
---@class MarkdownLists.Entry
---@field n integer line number
---@field p MarkdownLists.Line parsed line
---@field line string original text

---Signature shared by all list operations.
---@alias MarkdownLists.Operation fun(l1: integer, l2: integer, mode: "n"|"x", arg?: any)

---@class MarkdownLists.Config
---@field bullets string[] bullet markers, in the order of the marker cycle
---@field cycle MarkdownLists.Type[] order of the type cycle

---@type MarkdownLists.Config
M.config = {
	bullets = { "-", "*", "+" },
	cycle = { "bullet", "check", "number", "none" },
}

-- Parsing
-- These functions only use string operations, so they are safe to call from
-- conform.nvim formatters (which may run outside the main loop).

---@return string
local function default_bullet()
	return vim.b.markdown_list_bullet or vim.g.markdown_list_bullet or M.config.bullets[1]
end

---@return string
local function default_delimiter()
	return vim.b.markdown_list_delimiter or vim.g.markdown_list_delimiter or "."
end

---Whether a line is a thematic break (`---`, `***`, `* * *`, `___`).
---@param line string
---@return boolean
local function is_hr(line)
	local s = line:gsub("%s", "")
	return #s >= 3 and (s:match("^%-+$") or s:match("^%*+$") or s:match("^_+$")) ~= nil
end

---@param line string
---@return MarkdownLists.Line
local function parse(line)
	if line:match("^%s*$") then
		return { kind = "blank", indent = "", text = "" }
	end
	if is_hr(line) then
		return { kind = "hr", indent = line:match("^%s*"), text = line }
	end

	local indent, marker, rest = line:match("^(%s*)([-*+])%s+(.*)$")
	local ordered, num = false, nil
	if not indent then
		indent, marker = line:match("^(%s*)([-*+])$")
		rest = ""
	end
	if not indent then
		local n
		indent, n, marker, rest = line:match("^(%s*)(%d+)([.)])%s+(.*)$")
		if not indent then
			indent, n, marker = line:match("^(%s*)(%d+)([.)])$")
			rest = ""
		end
		if indent then
			ordered, num = true, tonumber(n)
		end
	end
	if not indent then
		local ws, text = line:match("^(%s*)(.*)$")
		return { kind = "text", indent = ws, text = text }
	end

	local box, text = rest:match("^%[([ xX])%]%s+(.*)$")
	if not box then
		box = rest:match("^%[([ xX])%]$")
		text = box and "" or rest
	end
	return {
		kind = "item",
		indent = indent,
		ordered = ordered,
		marker = marker,
		num = num,
		box = box,
		text = text,
	}
end

---@param it MarkdownLists.Line a line with `kind == "item"`
---@return string
local function render(it)
	local s = it.indent .. (it.ordered and (it.num .. it.marker) or it.marker)
	if it.box then
		s = s .. " [" .. it.box .. "]"
	end
	return s .. " " .. it.text
end

---@param p MarkdownLists.Line
---@return MarkdownLists.Type
local function type_of(p)
	if p.kind ~= "item" then
		return "none"
	end
	if p.box then
		return "check"
	end
	return p.ordered and "number" or "bullet"
end

---Rewrite a parsed line as another list type. An existing bullet keeps its
---marker and an existing number keeps its value.
---@param p MarkdownLists.Line
---@param target MarkdownLists.Type
---@return string line
local function convert(p, target)
	if target == "none" then
		return p.indent .. p.text
	end

	local it = { kind = "item", indent = p.indent, text = p.text, ordered = false, marker = default_bullet() }
	if p.kind == "item" and not p.ordered then
		it.marker = p.marker
	end
	if target == "number" then
		it.ordered, it.num, it.marker = true, 1, default_delimiter()
		if p.kind == "item" and p.ordered then
			it.num, it.marker = p.num, p.marker
		end
	elseif target == "check" then
		it.box = (p.kind == "item" and p.box) or " "
	end
	return render(it)
end

-- Buffer helpers

---@param indent string
---@return integer columns
local function width(indent)
	return vim.fn.strdisplaywidth(indent)
end

---@return string[]
local function buffer_lines()
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

---@param n integer line number
---@param text string
local function set_line(n, text)
	vim.api.nvim_buf_set_lines(0, n - 1, n, false, { text })
end

---Lines of a range that an operation can change: blank lines and thematic
---breaks are skipped. A single blank line counts as empty text, so that an
---operation can start a list on it.
---@param l1 integer
---@param l2 integer
---@return MarkdownLists.Entry[]
local function collect(l1, l2)
	local out = {}
	local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)
	for i, line in ipairs(lines) do
		local p = parse(line)
		if p.kind == "blank" and l1 == l2 then
			p = { kind = "text", indent = "", text = "" }
		end
		if p.kind ~= "blank" and p.kind ~= "hr" then
			out[#out + 1] = { n = l1 + i - 1, p = p, line = line }
		end
	end
	return out
end

---Replace the text of each entry with `fn(parsed_line)`, touching only the
---lines that changed.
---@param entries MarkdownLists.Entry[]
---@param fn fun(p: MarkdownLists.Line): string?
local function write(entries, fn)
	for _, e in ipairs(entries) do
		local new = fn(e.p)
		if new and new ~= e.line then
			set_line(e.n, new)
		end
	end
end

---Line numbers of the sibling items of the item at line `n`, `n` included, in
---order. Siblings share indentation, kind (bullet/numbered) and marker, and are
---contiguous: nested items, continuation lines and blank lines inside the list
---are skipped over.
---@param lines string[]
---@param n integer
---@return integer[]
local function siblings(lines, n)
	local base = parse(lines[n])
	local w = width(base.indent)

	---@param p MarkdownLists.Line
	local function same(p)
		return p.kind == "item" and p.ordered == base.ordered and p.marker == base.marker and width(p.indent) == w
	end

	---@param dir 1|-1
	---@return integer[]
	local function scan(dir)
		local res = {}
		local i = n + dir
		while lines[i] do
			local p = parse(lines[i])
			if p.kind == "blank" then
				-- a blank line only continues the list if what follows belongs to it
				local j = i + dir
				while lines[j] and lines[j]:match("^%s*$") do
					j = j + dir
				end
				if not lines[j] then
					break
				end
				local q = parse(lines[j])
				if not (same(q) or width(q.indent) > w) then
					break
				end
				i = j - dir
			elseif same(p) then
				res[#res + 1] = i
			elseif width(p.indent) <= w then
				break
			end
			i = i + dir
		end
		return res
	end

	local out = {}
	local up = scan(-1)
	for k = #up, 1, -1 do
		out[#out + 1] = up[k]
	end
	out[#out + 1] = n
	vim.list_extend(out, scan(1))
	return out
end

---Renumber the numbered lists touched by a range, starting at the number of the
---first item of each list. The whole list is renumbered, not only the range.
---@param l1 integer
---@param l2 integer
local function renumber(l1, l2)
	local lines = buffer_lines()
	local done = {}
	for n = l1, l2 do
		local p = lines[n] and parse(lines[n])
		if p and p.kind == "item" and p.ordered and not done[n] then
			local sib = siblings(lines, n)
			local start = parse(lines[sib[1]]).num
			for k, ln in ipairs(sib) do
				done[ln] = true
				local q = parse(lines[ln])
				if q.num ~= start + k - 1 then
					q.num = start + k - 1
					set_line(ln, render(q))
				end
			end
		end
	end
end

-- Operations

---Toggle a list type. If every line already has the type the list is removed,
---otherwise all lines are converted to it.
---@type MarkdownLists.Operation
---@param target "bullet"|"number" as `arg`
function M.toggle(l1, l2, _, target)
	local entries = collect(l1, l2)
	if #entries == 0 then
		return
	end

	local all = true
	for _, e in ipairs(entries) do
		if type_of(e.p) ~= target then
			all = false
			break
		end
	end

	local final = all and "none" or target
	write(entries, function(p)
		return convert(p, final)
	end)
	renumber(l1, l2)
end

---Toggle the `[ ]` box of every line, keeping the bullet or number. If every
---line already has a box the boxes are removed, otherwise they are added.
---@type MarkdownLists.Operation
function M.toggle_checklist(l1, l2)
	local entries = collect(l1, l2)
	if #entries == 0 then
		return
	end

	local all_box = true
	for _, e in ipairs(entries) do
		if not e.p.box then
			all_box = false
			break
		end
	end

	write(entries, function(p)
		if all_box then
			p.box = nil
			return render(p)
		end
		if p.kind == "item" then
			p.box = p.box or " "
			return render(p)
		end
		return convert(p, "check")
	end)
end

---Cycle the list type following `M.config.cycle`. The current type is the one of
---the first line, and every line is converted to the next type.
---@type MarkdownLists.Operation
---@param dir 1|-1 as `arg`: direction of the cycle
function M.cycle(l1, l2, _, dir)
	local entries = collect(l1, l2)
	if #entries == 0 then
		return
	end

	local order = M.config.cycle
	local current, idx = type_of(entries[1].p), nil
	for i, t in ipairs(order) do
		if t == current then
			idx = i
		end
	end
	idx = idx or (dir > 0 and 0 or #order + 1)

	local target = order[(idx - 1 + dir) % #order + 1]
	write(entries, function(p)
		return convert(p, target)
	end)
	renumber(l1, l2)
end

---Turn the lines back into plain text.
---@type MarkdownLists.Operation
function M.clear(l1, l2)
	write(collect(l1, l2), function(p)
		return convert(p, "none")
	end)
end

---Cycle the marker: bullets go through `M.config.bullets`, numbered items swap
---`.` and `)`.
---In normal mode without a count the whole list (the sibling items) changes,
---because changing the marker of a single item would split the list in two.
---In visual mode (or with a count) only the selected lines change.
---@type MarkdownLists.Operation
function M.cycle_marker(l1, l2, mode)
	local lines = buffer_lines()
	local targets, first = {}, nil

	if mode == "n" and l1 == l2 then
		first = parse(lines[l1])
		if first.kind ~= "item" then
			vim.notify("Not a list item", vim.log.levels.WARN)
			return
		end
		targets = siblings(lines, l1)
	else
		for n = l1, l2 do
			if parse(lines[n]).kind == "item" then
				targets[#targets + 1] = n
			end
		end
		if #targets == 0 then
			return
		end
		first = parse(lines[targets[1]])
	end

	local new
	if first.ordered then
		new = first.marker == "." and ")" or "."
	else
		local idx = 0
		for i, b in ipairs(M.config.bullets) do
			if b == first.marker then
				idx = i
			end
		end
		new = M.config.bullets[idx % #M.config.bullets + 1]
	end

	for _, n in ipairs(targets) do
		local p = parse(lines[n])
		if p.ordered == first.ordered then
			p.marker = new
			set_line(n, render(p))
		end
	end
end

---Renumber the numbered lists touched by the range (1, 2, 3...), starting at the
---number of the first item.
---@type MarkdownLists.Operation
function M.renumber(l1, l2)
	renumber(l1, l2)
end

---Wrap an operation as a keymap callback. In normal mode the range is the current
---line plus `count - 1` lines below it; in visual mode it is the selection, which
---stays active afterwards. In normal mode the cursor keeps its place in the text
---when the list prefix changes size.
---@param fn MarkdownLists.Operation
---@param arg? any forwarded to `fn` as its last argument
---@return fun() callback
function M.action(fn, arg)
	return function()
		local m = vim.fn.mode()
		local visual = m == "v" or m == "V" or m == "\22"

		local l1, l2
		if visual then
			l1, l2 = vim.fn.line("v"), vim.fn.line(".")
			if l1 > l2 then
				l1, l2 = l2, l1
			end
		else
			l1 = vim.fn.line(".")
			l2 = math.min(l1 + vim.v.count1 - 1, vim.fn.line("$"))
		end

		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		local before = vim.api.nvim_get_current_line()
		fn(l1, l2, visual and "x" or "n", arg)

		if not visual then
			local after = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
			local new_col = math.max(0, col + #after - #before)
			pcall(vim.api.nvim_win_set_cursor, 0, { row, math.min(new_col, math.max(#after - 1, 0)) })
		end
	end
end

-- Formatter post-processing

---Index of the last line of the YAML front matter.
---@param lines string[]
---@return integer index `0` if there is no front matter
local function front_matter_end(lines)
	if lines[1] and lines[1]:match("^%-%-%-%s*$") then
		for j = 2, #lines do
			if lines[j]:match("^%-%-%-%s*$") or lines[j]:match("^%.%.%.%s*$") then
				return j
			end
		end
	end
	return 0
end

---Opening fence of a fenced code block (the backticks or tildes), if the line is one.
---@param line string
---@return string?
local function fence_open(line)
	return line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
end

---Whether `line` closes the code block opened by `fence`.
---@param line string
---@param fence string
---@return boolean
local function fence_closes(line, fence)
	local f = fence_open(line)
	return f ~= nil and f:sub(1, 1) == fence:sub(1, 1) and #f >= #fence and line:match("^%s*[`~]+%s*$") ~= nil
end

---Call `fn` for every real bullet item, skipping the YAML front matter and the
---fenced code blocks.
---@param lines string[]
---@param fn fun(i: integer, p: MarkdownLists.Line)
local function walk_bullets(lines, fn)
	local fence
	for i = front_matter_end(lines) + 1, #lines do
		local line = lines[i]
		if fence then
			if fence_closes(line, fence) then
				fence = nil
			end
		elseif fence_open(line) then
			fence = fence_open(line)
		else
			local p = parse(line)
			if p.kind == "item" and not p.ordered then
				fn(i, p)
			end
		end
	end
end

---Markers (`-`, `*` or `+`) of every bullet item, in order. Prettier rewrites
---`*` and `+` as `-`, so they are saved before formatting and put back after.
---@param lines string[]
---@return string[]
function M.bullet_markers(lines)
	local out = {}
	walk_bullets(lines, function(_, p)
		out[#out + 1] = p.marker
	end)
	return out
end

---Put the markers saved by `bullet_markers` back. If the number of bullets
---changed while formatting nothing is restored, since the items can no longer be
---matched one to one.
---@param lines string[] formatted lines (modified in place)
---@param markers? string[]
---@return string[] lines
function M.restore_bullets(lines, markers)
	if not markers or #markers == 0 then
		return lines
	end

	local count = 0
	walk_bullets(lines, function()
		count = count + 1
	end)
	if count ~= #markers then
		return lines
	end

	local k = 0
	walk_bullets(lines, function(i, p)
		k = k + 1
		if p.marker ~= markers[k] then
			lines[i] = p.indent .. markers[k] .. lines[i]:sub(#p.indent + 2)
		end
	end)
	return lines
end

---Replace each group of `ts` leading spaces of the list lines with a tab, so the
---indentation mixes tabs and spaces (the remainder stays as spaces). The YAML
---front matter (where tabs are invalid) and the fenced code blocks are left alone.
---@param lines string[] modified in place
---@param ts? integer columns per tab, 4 by default
---@return string[] lines
function M.tabify(lines, ts)
	ts = ts or 4
	local fence, in_list = nil, false

	for i = front_matter_end(lines) + 1, #lines do
		local line = lines[i]
		local skip = false

		if fence then
			skip = true
			if fence_closes(line, fence) then
				fence = nil
			end
		elseif fence_open(line) then
			fence, skip = fence_open(line), true
		else
			local p = parse(line)
			if p.kind == "item" then
				in_list = true
			elseif p.kind ~= "blank" and p.indent == "" then
				in_list = false
			end
		end

		if in_list and not skip then
			local spaces, rest = line:match("^( +)(.*)$")
			if spaces and #spaces >= ts then
				local tabs = math.floor(#spaces / ts)
				lines[i] = ("\t"):rep(tabs) .. (" "):rep(#spaces - tabs * ts) .. rest
			end
		end
	end
	return lines
end

return M
