local km = vim.keymap.set

-- Selection and line manipulation
km("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
km("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Move line/selection up/down
km("n", "ZK", function() vim.cmd("move -1-" .. vim.v.count1) end, { desc = "Move line up" })
km("n", "ZJ", function() vim.cmd("move +" .. vim.v.count1) end, { desc = "Move line down" })

-- Duplicate visual selection up/down
km("v", "zj", ":t '>+" .. vim.v.count .. "<CR>gv", { desc = "Duplicate selection below" })
km("v", "zk", ":t '<-1-" .. vim.v.count .. "<CR>gv", { desc = "Duplicate selection above" })

-- Insert blank lines
km("n", "<leader>bj", function()
  vim.cmd("put =repeat(nr2char(10), " .. vim.v.count1 .. ")")
end, { desc = "Insert blank line(s) below" })

km("n", "<leader>bk", function()
  vim.cmd("put! =repeat(nr2char(10), " .. vim.v.count1 .. ")")
end, { desc = "Insert blank line(s) above" })

-- do with automatic diffupdate
km("n", "do", "do<cmd>diffupdate<CR>", { desc = "Diffget and update diff" })

km("n", "<leader>dd", ":t.<CR>", { desc = "Duplicate line" })
km("v", "<leader>dd", ":t'>+1<cr>gv", { desc = "Duplicate selection" })

km("n", "gl", "v$", { desc = "Select to end of line" })
km("n", "gh", "v^", { desc = "Select to start of line" })
km("n", "gV", "`[v`]", { desc = "Reselect last changed text" })

-- Indentation
km("v", "<Tab>", ">gv", { desc = "Indent selection right" })
km("v", "<S-Tab>", "<gv", { desc = "Indent selection left" })

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

-- Insert mode: Emacs-style navigation
km("i", "<C-a>", "<Home>", { desc = "Go to beginning of line" })
km("i", "<C-e>", "<End>", { desc = "Go to end of line" })

km("i", "<C-b>", "<Left>", { desc = "Move char backward" })
km("i", "<C-f>", "<Right>", { desc = "Move char forward" })

km("i", "<C-h>", "<C-o>b", { desc = "Move word backward" })
km("i", "<C-l>", "<C-o>w", { desc = "Move word forward" })

-- Insert mode: Emacs-style deletion
km("i", "<C-d>", "<Delete>", { desc = "Delete char forward" })
km("i", "<C-BS>", "<C-w>", { desc = "Delete previous word" })
km("i", "<C-Del>", "<C-o>dw", { desc = "Delete next word" })
km("i", "<C-u>", "<C-o>d$", { desc = "Delete to end of line" })

-- Insert mode: Emacs-style editing
km("i", "<C-t>", "<Esc>xpa", { desc = "Transpose two characters" })
km("i", "<C-y>", '<C-r>"', { desc = "Paste last yank/delete" })

-- Insert mode: Emacs-style undo
km("i", "<C-z>", "<C-o>u", { desc = "Undo without leaving insert mode" })

-- Insert mode: Ctrl-C as Esc
km("i", "<C-c>", "<Esc>", { desc = "Exit insert mode" })
