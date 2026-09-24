-- lua/keymaps/lsp.lua

-- LSP keymaps are set on the `LspAttach` event so they only exist in
-- buffers where an LSP client is actually attached, instead of being
-- defined globally for every buffer.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    -- Local helper: automatically scopes each keymap to the current buffer
    local km = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
    end

    -- Navigation
    km("n", "K", vim.lsp.buf.hover, "Show hover information")
    km("n", "gd", vim.lsp.buf.definition, "Go to definition")
    km("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    km("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    km("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
    km("n", "gr", vim.lsp.buf.references, "Go to references")
    km("n", "gp", vim.lsp.buf.signature_help, "Show signature help")
    km("n", "gs", vim.lsp.buf.document_symbol, "Document symbols")

    -- Go to implementation in a new vertical split
    km("n", "gI", function()
      vim.cmd("vsplit")
      vim.lsp.buf.implementation()
    end, "Go to implementation in split")

    -- Signature help in insert mode (<C-s> is already the default in 0.11+)
    km("i", "<C-j>", vim.lsp.buf.signature_help, "Signature help")

    -- Actions
    km("n", "cr", vim.lsp.buf.rename, "Rename symbol")
    km({ "n", "v" }, "ca", vim.lsp.buf.code_action, "Code action")
  end,
})

-- Diagnostics
-- These can stay global since they don't depend on an LSP client
-- being attached (diagnostics can come from other sources too).
local km = vim.keymap.set

-- severity_sort keeps errors above warnings, update_in_insert keeps
-- diagnostics updating while typing. The float size is computed once at
-- startup, so it won't follow later window resizes.
vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = true,
  float = {
    border = "single",
    max_width = math.floor(vim.o.columns * 0.4),
    max_height = math.floor(vim.o.lines * 0.4),
  },
})

-- Only the diagnostic under the cursor, not the whole line
km("n", "<leader>e", function()
  vim.diagnostic.open_float({ scope = "cursor" })
end, { desc = "Show diagnostic under cursor" })

-- vim.diagnostic.jump replaces the deprecated goto_prev/goto_next
km("n", "[e", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Go to previous diagnostic" })

km("n", "]e", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Go to next diagnostic" })
