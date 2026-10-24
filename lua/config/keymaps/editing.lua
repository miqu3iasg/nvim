-- lua/keymaps/editing.lua

local km = vim.keymap.set

-- Helpers

-- Build a substitution prompt with an escaped search pattern
local function sub_prompt(scope, text, use_boundary)
	if text == "" then
		return
	end
	local pattern = vim.fn.escape(text, "\\/.*$^~[]")
	if use_boundary then
		pattern = [[\<]] .. pattern .. [[\>]]
	end
	local cmd = string.format(":keeppatterns %s/%s//gc", scope, pattern)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, false, true), "n", false)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Left><Left><Left>", true, false, true), "n", false)
end

vim.opt.grepprg = "rg --vimgrep"

-- Build a project-wide substitution (rg, quickfix and cfdo) on the cmdline
local function project_sub(text, use_boundary)
	if text == "" or text:find("[\n|]") then
		return
	end
	local pattern = vim.fn.escape(text, "\\/.*$^~[]")
	if use_boundary then
		pattern = [[\<]] .. pattern .. [[\>]]
	end
	local grep = string.format(
		"silent grep! --fixed-strings --case-sensitive %s-- %s",
		use_boundary and "--word-regexp " or "",
		vim.fn.shellescape(text, true)
	)
	local cmd = string.format(":%s | cfdo keeppatterns %%s/%s//gce | update", grep, pattern)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, false, true), "n", false)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(string.rep("<Left>", 13), true, false, true), "n", false)
end

-- Line and Selection Movement
km("n", "ZK", ":move -2<CR>==", { desc = "Move line up" })
km("n", "ZJ", ":move +1<CR>==", { desc = "Move line down" })
km("x", "ZK", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })
km("x", "ZJ", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })
-- Why two ways to do the same thing? Idk, just because I want and fuck you dawg
km("x", "K", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })
km("x", "J", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })

-- Line and Selection Duplication
km("n", "zk", ":t .-1<CR>", { desc = "Duplicate line above" })
km("n", "zj", ":t .+0<CR>", { desc = "Duplicate line below" })
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

km("x", "p", "P", { desc = "Paste over selection without yanking" })
km("x", "<leader>p", '"_dP', { desc = "Replace selection with yanked text" })

km("n", "U", "<C-r>", { desc = "Redo" })

-- Substitution
km("n", "cu", function()
	sub_prompt("%s", vim.fn.expand("<cword>"), true)
end, { desc = "Substitute word in buffer" })

km("n", "cU", function()
	sub_prompt("%s", vim.fn.expand("<cWORD>"), false)
end, { desc = "Substitute WORD in buffer" })

km("n", "cd", function()
	sub_prompt("s", vim.fn.expand("<cword>"), true)
end, { desc = "Substitute word in line" })

km("n", "cD", function()
	sub_prompt("s", vim.fn.expand("<cWORD>"), false)
end, { desc = "Substitute WORD in line" })

km("n", "<leader>cw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {
	desc = "Substitute word under cursor at once",
})

km("x", "<leader>cw", [["zy:%s/\V<C-r>=substitute(escape(@z, '/\'), '\n', '\\n', 'g')<CR>//g<Left><Left>]], {
	desc = "Substitute selection at once",
})

km("n", "<leader>cp", function()
	project_sub(vim.fn.expand("<cword>"), true)
end, { desc = "Substitute word in project" })

km("x", "<leader>cp", function()
	vim.cmd('noautocmd normal! "zy')
	project_sub(vim.fn.getreg("z"), false)
end, { desc = "Substitute selection in project" })

-- Repeatable Change
km("n", "<leader>cn", "*``cgn", {
	desc = "Change next occurrence of word under cursor (repeat with .)",
})

-- Navigation
km({ "n", "x", "o" }, "<Tab>", "%", {
	remap = true,
	desc = "Jump to matching pair",
})
