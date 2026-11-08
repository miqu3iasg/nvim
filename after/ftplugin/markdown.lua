-- after/ftplugin/markdown.lua

-- Configures Markdown buffers for prose writing, with buffer-local keymaps for
-- lists, checkboxes and inline formatting. Pandoc integration is loaded from a
-- shared module.
--
-- `:PasteImage` is provided by img-clip.nvim, which must be installed through
-- the plugin manager and relies on a clipboard utility such as wl-clipboard or
-- xclip.
--
-- See: ~/.config/nvim/pandoc
-- See: lua/shared/pandoc.lua
-- See: lua/features/markdown_lists.lua
-- See: https://github.com/HakonHarnes/img-clip.nvim

local opt = vim.opt_local

opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.spell = false
opt.list = false
opt.fillchars:append({ eob = " " })
opt.spelllang = { "pt_br", "en_us" }
opt.textwidth = 100
opt.formatoptions:remove({ "t", "l" })
opt.formatoptions:append("n")
opt.formatoptions:append({ "r", "o" })
opt.suffixesadd:append(".md")
-- See: lua/plugins/formatting.lua
opt.expandtab = vim.g.markdown_use_tabs == false
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = -1

require("shared.pandoc").setup()

---@param mode string|string[]
---@param lhs string
---@param rhs string|fun()
---@param desc string
---@param opts? table Extra mapping options merged over the defaults.
local function map(mode, lhs, rhs, desc, opts)
	vim.keymap.set(
		mode,
		lhs,
		rhs,
		vim.tbl_extend("force", {
			buffer = true,
			silent = true,
			desc = desc,
		}, opts or {})
	)
end

map("n", "<localleader>ss", "<cmd>setlocal spell!<cr>", "Toggle spell check")
map("i", "<C-s>", "<c-g>u<Esc>[s1z=`]a<c-g>u", "Fix previous spelling mistake")

map("n", "<localleader>sc", function()
	vim.opt_local.conceallevel = vim.opt_local.conceallevel:get() == 0 and 2 or 0
	vim.notify("conceallevel = " .. vim.opt_local.conceallevel:get())
end, "Toggle conceal level")

local function parse_item(line)
	local indent, marker, rest = line:match("^(%s*)([-*+])%s+(.*)$")
	if not indent then
		indent, marker, rest = line:match("^(%s*)(%d+[.)])%s+(.*)$")
	end
	return indent, marker, rest
end

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

vim.api.nvim_buf_create_user_command(0, "ToggleCheckbox", function(o)
	for lnum = o.line1, o.line2 do
		toggle_checkbox_line(lnum)
	end
end, { range = true })

map({ "n", "x" }, "<localleader>lt", ":ToggleCheckbox<CR>", "Toggle checkbox")

-- Normal mode acts on the current line and accepts a count. Visual mode acts on
-- the selected lines and keeps the selection, so a mapping can be repeated to
-- cycle the list type.
local lists = require("features.markdown_lists")

map({ "n", "x" }, "<localleader>lb", lists.action(lists.toggle, "bullet"), "Toggle bullet list")
map({ "n", "x" }, "<localleader>ln", lists.action(lists.toggle, "number"), "Toggle numbered list")
map({ "n", "x" }, "<localleader>lc", lists.action(lists.toggle_checklist), "Toggle checklist")
map({ "n", "x" }, "<localleader>ll", lists.action(lists.cycle, 1), "Cycle list type (bullet > check > number > none)")
map({ "n", "x" }, "<localleader>lL", lists.action(lists.cycle, -1), "Cycle list type (reverse)")
map({ "n", "x" }, "<localleader>lm", lists.action(lists.cycle_marker), "Cycle marker (- * + / . ))")
map({ "n", "x" }, "<localleader>lr", lists.action(lists.renumber), "Renumber ordered list")
map({ "n", "x" }, "<localleader>lx", lists.action(lists.clear), "Remove list formatting")

map("i", ",", ",<C-g>u", "Break undo sequence at comma")
map("i", ".", ".<C-g>u", "Break undo sequence at period")
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", "Move down by visual line", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", "Move up by visual line", { expr = true })

---Keys that append `text` after the cursor and move `back` characters left.
---@param text string
---@param back integer
---@return string
local function insert(text, back)
	return "a" .. text .. ("<Left>"):rep(back)
end

---Keys that replace the visual selection with itself between `open` and `close`.
---@param open string
---@param close string
---@return string
local function wrap(open, close)
	return '"zc' .. open .. "<C-r>z" .. close .. "<Esc>"
end

map("n", "<localleader>ik", function()
	local row = vim.fn.line(".")
	vim.api.nvim_buf_set_lines(0, row, row, false, { "```", "", "```" })
	vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
	vim.cmd("startinsert")
end, "Insert code block")

map("n", "<localleader>ii", "<cmd>PasteImage<cr>", "Paste image from clipboard")

map("n", "<localleader>j", "vipJ", "Join paragraph into one line")
map("x", "<localleader>s", ":sort i<CR>", "Sort lines")

---Wrap the word under the cursor between `open` and `close`. When `toggle` is
---set and the word is already wrapped, remove the pair instead. Away from a
---word, insert the empty pair and start insert mode inside it.
---@param open string
---@param close string
---@param toggle boolean Whether applying it again removes the wrapping.
---@param insert_back? integer After wrapping, start insert mode this many
---characters before the end of `close`. For example, 1 puts the cursor inside
---the `()` of a link.
local function format_word(open, close, toggle, insert_back)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_get_current_line()
	local ch = vim.fn.strcharpart(line:sub(col + 1), 0, 1)

	if ch == "" or vim.fn.match(ch, [[\k]]) < 0 then
		vim.api.nvim_feedkeys(vim.keycode(insert(open .. close, #close)), "ni", false)
		return
	end

	-- The word is the run of 'iskeyword' characters that contains the cursor.
	local _, s, e = unpack(vim.fn.matchstrpos(line, [[\k*\%]] .. (col + 1) .. [[c\k*]]))
	local before = s >= #open and line:sub(s - #open + 1, s) == open
	local after = line:sub(e + 1, e + #close) == close

	if toggle and before and after then
		vim.api.nvim_buf_set_text(0, row - 1, e, row - 1, e + #close, { "" })
		vim.api.nvim_buf_set_text(0, row - 1, s - #open, row - 1, s, { "" })
		vim.api.nvim_win_set_cursor(0, { row, math.max(col - #open, s - #open) })
		return
	end

	vim.api.nvim_buf_set_text(0, row - 1, e, row - 1, e, { close })
	vim.api.nvim_buf_set_text(0, row - 1, s, row - 1, s, { open })
	if insert_back then
		vim.api.nvim_win_set_cursor(0, { row, e + #open + #close - insert_back })
		vim.cmd.startinsert()
	else
		vim.api.nvim_win_set_cursor(0, { row, col + #open })
	end
end

local function word_map(lhs, desc, open, close, toggle, insert_back)
	map("n", lhs, function()
		format_word(open, close, toggle, insert_back)
	end, desc)
end

word_map("<localleader>il", "Markdown link (word under cursor)", "[", "]()", false, 1)
word_map("<localleader>iw", "Wiki link (word under cursor)", "[[", "]]", true)
word_map("<localleader>if", "Inline footnote (word under cursor)", "^[", "]", false)
word_map("<localleader>ib", "Bold (word under cursor)", "**", "**", true)
word_map("<localleader>ie", "Italic (word under cursor)", "_", "_", true)
word_map("<localleader>ic", "Inline code (word under cursor)", "`", "`", true)
word_map("<localleader>is", "Strikethrough (word under cursor)", "~~", "~~", true)

map("x", "<localleader>il", '"zc[<C-r>z]()<Left>', "Wrap selection as markdown link")
map("x", "<localleader>cl", '"zc[<C-r>z](<C-r>+)<Esc>', "Link with clipboard URL")
map("x", "<localleader>iw", wrap("[[", "]]"), "Wrap selection as wiki link")
map("x", "<localleader>if", wrap("^[", "]"), "Wrap selection as inline footnote")
map("x", "<localleader>ib", wrap("**", "**"), "Bold selection")
map("x", "<localleader>ie", wrap("_", "_"), "Italic selection")
map("x", "<localleader>ic", wrap("`", "`"), "Inline code selection")
map("x", "<localleader>is", wrap("~~", "~~"), "Strikethrough selection")
