-- lua/keymaps/editing.lua

local km = vim.keymap.set
local substitute = require("utils.substitute")

if vim.fn.executable("rg") == 1 then
	vim.opt.grepprg = "rg --vimgrep"
end

-- Helpers

local function clamp_dest(dest)
	return math.max(0, math.min(dest, vim.fn.line("$")))
end

-- Move the current line up/down by [count] lines (default 1)
local function move_line(down)
	local lnum, n = vim.fn.line("."), vim.v.count1
	local dest = down and (lnum + n) or (lnum - n - 1)
	if pcall(vim.cmd, ("move %d"):format(clamp_dest(dest))) then
		vim.cmd("normal! ==")
	end
end

-- Move the visual selection up/down by [count] lines (default 1)
local function move_selection(down)
	local n = vim.v.count1
	vim.cmd("normal! " .. vim.keycode("<Esc>")) -- sets '< and '>
	local first, last = vim.fn.line("'<"), vim.fn.line("'>")
	local dest = down and (last + n) or (first - n - 1)
	pcall(vim.cmd, ("%d,%dmove %d"):format(first, last, clamp_dest(dest)))
	vim.cmd("normal! gv=gv")
end

-- Line and Selection Movement
km("n", "ZK", function()
	move_line(false)
end, { desc = "Move line up" })
km("n", "ZJ", function()
	move_line(true)
end, { desc = "Move line down" })
km("x", "K", function()
	move_selection(false)
end, { desc = "Move selection up" })
km("x", "J", function()
	move_selection(true)
end, { desc = "Move selection down" })

-- Line and Selection Duplication
km("n", "zk", ":t .-1<CR>", { desc = "Duplicate line above" })
km("n", "zj", ":t .<CR>", { desc = "Duplicate line below" })
km("x", "zk", ":t '<-1<CR>gv", { desc = "Duplicate selection above" })
km("x", "zj", ":t '>+0<CR>gv", { desc = "Duplicate selection below" })

-- Blank Lines
km("n", "ZH", function()
	vim.cmd("put!=repeat(nr2char(10), " .. vim.v.count1 .. ")")
end, { desc = "Insert blank line(s) above" })

km("n", "ZN", function()
	vim.cmd("put =repeat(nr2char(10), " .. vim.v.count1 .. ")")
end, { desc = "Insert blank line(s) below" })

-- Indentation
km("x", "<", "<gv", { desc = "Indent selection left" })
km("x", ">", ">gv", { desc = "Indent selection right" })

km("n", "<leader>=", function()
	local view = vim.fn.winsaveview()
	vim.cmd("normal! gg=G")
	vim.fn.winrestview(view)
end, { desc = "Indent entire file" })

km("x", "<leader>=", function()
	local view = vim.fn.winsaveview()
	vim.cmd("normal! =")
	vim.fn.winrestview(view)
	vim.cmd("normal! gv")
end, { desc = "Indent selection" })

-- Editing and Replacement
km("n", "J", "mzJ`z", { desc = "Join lines, keep cursor position" })

km("n", "S", '"_cc', { desc = "Replace line without yanking" })
km("n", "C", '"_C', { desc = "Replace to end of line without yanking" })

km("n", "c", '"_c', { desc = "Change without overwriting yank register" })
km("x", "c", '"_c', { desc = "Change selection without yanking" })

km("n", "x", '"_x', { desc = "Delete char without yanking" })
km("n", "X", '"_X', { desc = "Delete char before cursor without yanking" })
km("x", "x", '"_x', { desc = "Delete selection without yanking" })

-- P in visual mode keeps the unnamed register intact; p (native) yanks the replaced text
km("x", "p", "P", { desc = "Paste over selection without yanking" })
km("x", "<leader>p", "p", { desc = "Paste over selection (yanks replaced text)" })

km("n", "U", "<C-r>", { desc = "Redo" })

-- Substitution
km("n", "cu", function()
	substitute.prompt("%", vim.fn.expand("<cword>"), true)
end, { desc = "Substitute word in buffer" })

km("n", "cU", function()
	substitute.prompt("%", vim.fn.expand("<cWORD>"), false)
end, { desc = "Substitute WORD in buffer" })

km("n", "cd", function()
	substitute.prompt("s", vim.fn.expand("<cword>"), true)
end, { desc = "Substitute word in line" })

km("n", "cD", function()
	substitute.prompt("s", vim.fn.expand("<cWORD>"), false)
end, { desc = "Substitute WORD in line" })

km("n", "<leader>cw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {
	desc = "Substitute word under cursor at once",
})

km("x", "<leader>cw", function()
	substitute.selection(substitute.get_visual())
end, { desc = "Substitute selection at once" })

km("n", "<leader>cp", function()
	substitute.project(vim.fn.expand("<cword>"), true)
end, { desc = "Substitute word in project" })

km("x", "<leader>cp", function()
	substitute.project(substitute.get_visual(), false)
end, { desc = "Substitute selection in project" })

-- Repeatable Change
km("n", "<leader>cn", [[*``"_cgn]], {
	desc = "Change next occurrence of word under cursor (repeat with .)",
})

-- Navigation
km({ "n", "x", "o" }, "<Tab>", "%", {
	remap = true,
	desc = "Jump to matching pair",
})

-- Insert mode

-- Movement
km("i", "<C-a>", "<Home>", { desc = "Beginning of line" })
km("i", "<C-e>", "<End>", { desc = "End of line" })
km("i", "<C-f>", "<Right>", { desc = "Forward char" })
km("i", "<C-b>", "<Left>", { desc = "Backward char" })
km("i", "<C-l>", "<C-o>zz", { desc = "Recenter" })

-- Killing and Yanking
km("i", "<C-d>", "<Del>", { desc = "Delete char forward" })
km("i", "<C-k>", function()
	return vim.fn.col(".") > #vim.fn.getline(".") and "<Del>" or "<C-g>u<C-o>D"
end, { expr = true, desc = "Kill to end of line" })
