-- lua/keymaps/lsp.lua

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local km = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
    end

    km("n", "K", vim.lsp.buf.hover, "Show hover information")
    km("n", "gd", vim.lsp.buf.definition, "Go to definition")
    km("n", "gp", vim.lsp.buf.signature_help, "Show signature help")
    km("i", "<C-j>", vim.lsp.buf.signature_help, "Signature help")

    km("n", "grc", vim.lsp.buf.declaration, "Go to declaration")
    km("n", "gri", vim.lsp.buf.implementation, "Go to implementation")
    km("n", "grt", vim.lsp.buf.type_definition, "Go to type definition")
    km("n", "grr", vim.lsp.buf.references, "Go to references")

    km("n", "grs", function()
      vim.cmd("vsplit")
      vim.lsp.buf.implementation()
    end, "Go to implementation in split")

    km("n", "grm", vim.lsp.buf.document_symbol, "Document symbols")
    km("n", "grn", vim.lsp.buf.rename, "Rename symbol")
    km({ "n", "v" }, "gra", vim.lsp.buf.code_action, "Code action")

    km("n", "gro", function()
      vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
    end, "Organize imports")

    km("n", "grq", function()
      vim.lsp.buf.code_action({ context = { only = { "quickfix" } }, apply = true })
    end, "Apply quickfix")
  end,
})

-- Diagnostics
local km = vim.keymap.set

km("n", "gre", function()
  vim.diagnostic.open_float({ scope = "cursor" })
end, { desc = "Show diagnostic under cursor" })

km("n", "[e", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Go to previous diagnostic" })

km("n", "]e", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Go to next diagnostic" })
