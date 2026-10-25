-- after/ftplugin/markdown.lua

local opt = vim.opt_local

opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.spell = false
opt.spelllang = { "pt_br", "en_us" }
opt.textwidth = 100
opt.formatoptions:remove({ "t", "l" })
opt.formatoptions:append("n")
opt.formatoptions:append({ "r", "o" })
opt.suffixesadd:append(".md")
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = -1

-- Setup Pandoc configuration
-- See: ~/.config/nvim/pandoc
-- See: ~/.config/nvim/lua/shared/pandoc.lua
require("shared.pandoc").setup()

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

-- Spell
map("n", "<localleader>ss", "<cmd>setlocal spell!<cr>", "Toggle spell check")
map("i", "<C-s>", "<c-g>u<Esc>[s1z=`]a<c-g>u", "Fix previous spelling mistake")

-- View
map("n", "<localleader>sc", function()
	vim.opt_local.conceallevel = vim.opt_local.conceallevel:get() == 0 and 2 or 0
	vim.notify("conceallevel = " .. vim.opt_local.conceallevel:get())
end, "Toggle conceal level")

-- Lists and checkboxes
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

-- Typing
map("i", ",", ",<C-g>u", "Break undo sequence at comma")
map("i", ".", ".<C-g>u", "Break undo sequence at period")
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", "Move down by visual line", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", "Move up by visual line", { expr = true })

-- Editing
local function insert(text, back)
	return "a" .. text .. ("<Left>"):rep(back)
end

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

map("n", "<localleader>il", insert("[]()", 3), "Insert markdown link")
map("n", "<localleader>iw", insert("[[]]", 2), "Insert wiki link")
map("n", "<localleader>if", insert("^[]", 1), "Insert inline footnote")
map("n", "<localleader>ib", insert("****", 2), "Insert bold")
map("n", "<localleader>ie", insert("__", 1), "Insert italic")
map("n", "<localleader>ic", insert("``", 1), "Insert inline code")
map("n", "<localleader>is", insert("~~~~", 2), "Insert strikethrough")

map("x", "<localleader>il", '"zc[<C-r>z]()<Left>', "Wrap selection as markdown link")
map("x", "<localleader>cl", '"zc[<C-r>z](<C-r>+)<Esc>', "Link with clipboard URL")
map("x", "<localleader>iw", wrap("[[", "]]"), "Wrap selection as wiki link")
map("x", "<localleader>ib", wrap("**", "**"), "Bold selection")
map("x", "<localleader>ie", wrap("_", "_"), "Italic selection")
map("x", "<localleader>ic", wrap("`", "`"), "Inline code selection")
map("x", "<localleader>is", wrap("~~", "~~"), "Strikethrough selection")
