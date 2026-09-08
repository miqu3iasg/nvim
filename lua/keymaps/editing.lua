local km = vim.keymap.set

-- Move line/selection up/down
km("v", "ZK", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })
km("v", "ZJ", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })

km("n", "ZK", ":move -2<CR>==", { desc = "Move line up" })
km("n", "ZJ", ":move +1<CR>==", { desc = "Move line down" })

-- Duplicate visual selection up/down
km("v", "zj", ":t '>+0<CR>gv", { desc = "Duplicate selection below" })
km("v", "zk", ":t '<-1<CR>gv", { desc = "Duplicate selection above" })

km("n", "zj", ":t .+0<CR>", { desc = "Duplicate line below" })
km("n", "zk", ":t .-1<CR>", { desc = "Duplicate line above" })

-- Selection
km("n", "gl", "v$", { desc = "Select to end of line" })
km("n", "gh", "v^", { desc = "Select to start of line" })
km("n", "gV", "`[v`]", { desc = "Reselect last changed text" })

-- Indentation
km("n", ">", ">>", { desc = "Indent line right" })
km("n", "<", "<<", { desc = "Indent line left" })

km("v", ">", ">gv", { desc = "Indent selection right" })
km("v", "<", "<gv", { desc = "Indent selection left" })

km("n", "<leader>=", "gg=G", { desc = "Indent entire file" })
km("v", "<leader>=", "=gv", { desc = "Indent selection" })

-- Formatting
km("n", "<leader>k", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer (conform, fallback to LSP)" })

-- Editing
km("n", "J", "mzJ`z", { desc = "Join lines, keep cursor position" })
km("n", "Y", "y$", { desc = "Yank to end of line" })
km("n", "S", "cc", { desc = "Replace entire line" })
km("n", "C", "c$", { desc = "Replace to end of line" })

km("x", "p", "P", { desc = "Paste without overwriting register" })
km("v", "p", '"_dP', { desc = "Paste over selection without losing the yank register" })
km({ "n", "v" }, "x", '"_x', { desc = "Delete char without yanking" })
km({ "n" }, "X", '"_X', { desc = "Delete char before cursor without yanking" })
km({ "n", "v" }, "c", '"_c', { desc = "Change without overwriting yank register" })
km({ "n", "v" }, "d", '"_d', { desc = "Delete without yanking" })
km({ "n" }, "D", '"_D', { desc = "Delete to end of line without yanking" })

-- Clipboard
km({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
km("n", "<leader>Y", '"+y$', { desc = "Yank to end of line to system clipboard" })
km({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Undo and redo
km("n", "U", "<C-r>", { desc = "Redo" })

-- External actions
km("n", "gx", function()
  local url = vim.fn.expand("<cWORD>")
  vim.ui.open(url)
end, { desc = "Open URL under cursor" })

-- Insert mode line/word/char navigation and identation
km("i", "<C-a>", "<Home>", { desc = "Go to beginning of line" })
km("i", "<C-e>", "<End>", { desc = "Go to end of line" })
km("i", "<C-b>", "<Left>", { desc = "Move char backward" })
km("i", "<C-f>", "<Right>", { desc = "Move char forward" })
km("i", "<C-h>", "<C-o>b", { desc = "Move word backward" })
km("i", "<C-l>", "<C-o>w", { desc = "Move word forward" })
km("i", "<C-t>", "<C-o>>>", { desc = "Indent current line" })
km("i", "<C-d>", "<C-o><<", { desc = "Dedent current line" })
