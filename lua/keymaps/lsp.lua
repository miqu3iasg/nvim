local km = vim.keymap.set

-- LSP
km("n", "K", vim.lsp.buf.hover, { desc = "Show hover information" })
km("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
km("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
km("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
km("n", "gI", function()
  vim.cmd("vsplit")
  vim.lsp.buf.implementation()
end, { desc = "Go to implementation in split" })
km("n", "gy", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
km("n", "gp", vim.lsp.buf.signature_help, { desc = "Show signature help" })
km("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
km({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })

-- Diagnostics
km("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
km("n", "[e", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
km("n", "]e", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
