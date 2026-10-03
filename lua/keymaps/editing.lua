-- lua/keymaps/editing.lua

local km = vim.keymap.set

-- Move line/selection up/down
km("x", "ZK", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })
km("x", "ZJ", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })

km("n", "ZK", ":move -2<CR>==", { desc = "Move line up" })
km("n", "ZJ", ":move +1<CR>==", { desc = "Move line down" })

-- Duplicate visual selection up/down
km("x", "zj", ":t '>+0<CR>gv", { desc = "Duplicate selection below" })
km("x", "zk", ":t '<-1<CR>gv", { desc = "Duplicate selection above" })

km("n", "zj", ":t .+0<CR>", { desc = "Duplicate line below" })
km("n", "zk", ":t .-1<CR>", { desc = "Duplicate line above" })

-- Movement / Selection
km({ "n", "o" }, "gl", "$", { desc = "End of line" })
km("x", "gl", "g_", { desc = "End of line (without newline)" })
km({ "n", "x", "o" }, "gh", "^", { desc = "Start of line (extends selection in visual)" })
km("n", "gV", "`[v`]", { desc = "Reselect last changed text" })

-- Insert N blank lines above/below without entering insert mode
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

-- Formatting
km("n", "<leader>k", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer (conform, fallback to LSP)" })

-- Editing
km("n", "J", "mzJ`z", { desc = "Join lines, keep cursor position" })
km("n", "S", '"_cc', { desc = "Replace line without yanking" })
km("n", "C", '"_C', { desc = "Replace to end of line without yanking" })
km("x", "p", "P", { desc = "Paste over selection without yanking" })
km("n", "x", '"_x', { desc = "Delete char without yanking" })
km("x", "x", '"_x', { desc = "Delete selection without yanking" })
km("n", "X", '"_X', { desc = "Delete char before cursor without yanking" })
km("n", "c", '"_c', { desc = "Change without overwriting yank register" })
km("x", "c", '"_c', { desc = "Change selection without yanking" })

-- Add , or ; at the end of the line without move the cursor
km("n", "<leader>;", "mzA;<Esc>`z", { desc = "Append ; to end of line" })
km("n", "<leader>,", "mzA,<Esc>`z", { desc = "Append , to end of line" })

-- Change case word
km("n", "<leader>u", "viwU", { desc = "Uppercase word" })
km("n", "<leader>l", "viwu", { desc = "Lowercase word" })

-- Clipboard
km({ "n", "x" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
km("n", "<leader>Y", '"+y$', { desc = "Yank to end of line to system clipboard" })
km("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })
km("x", "<leader>p", '"+P', { desc = "Paste from system clipboard over selection" })

-- Undo and redo
km("n", "U", "<C-r>", { desc = "Redo" })

-- Insert mode line/word/char navigation and identation
km("i", "<C-a>", "<Home>", { desc = "Go to beginning of line" })
km("i", "<C-e>", "<End>", { desc = "Go to end of line" })
km("i", "<C-b>", "<Left>", { desc = "Move char backward" })
km("i", "<C-f>", "<Right>", { desc = "Move char forward" })
km("i", "<C-h>", "<C-o>b", { desc = "Move word backward" })
km("i", "<C-l>", "<C-o>w", { desc = "Move word forward" })
km("i", "<C-t>", "<C-o>>>", { desc = "Indent current line" })
km("i", "<C-d>", "<C-o><<", { desc = "Dedent current line" })

-- Substitution (word/WORD, buffer-wide/line-wide)
-- Rebuilt in Lua so the word/WORD is escaped before it ever reaches the
-- substitute pattern (avoids breaking on chars like . * $ ^ ~ [ ] / \).
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

km("n", "cu", function() sub_prompt("%s", vim.fn.expand("<cword>"), true) end, { desc = "Substitute word in buffer" })
km("n", "cU", function() sub_prompt("%s", vim.fn.expand("<cWORD>"), false) end, { desc = "Substitute WORD in buffer" })
km("n", "cd", function() sub_prompt("s", vim.fn.expand("<cword>"), true) end, { desc = "Substitute word in line" })
km("n", "cD", function() sub_prompt("s", vim.fn.expand("<cWORD>"), false) end, { desc = "Substitute WORD in line" })

-- Change the word in the entire file
km(
  "n",
  "<leader>cw", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Substitute word under cursor at once" }
)
