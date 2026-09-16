-- lua/langs/latex/keymaps.lua

local M = {}

function M.setup(bufnr)
  vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'",
    { buffer = bufnr, expr = true, desc = "Move down by visual line" })
  vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { buffer = bufnr, expr = true, desc = "Move up by visual line" })

  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  map("<leader>xc", "<cmd>VimtexCompile<cr>", "Compile (continuous)")
  map("<leader>xv", "<cmd>VimtexView<cr>", "View PDF")
  map("<leader>xt", "<cmd>VimtexTocToggle<cr>", "Table of contents")
  map("<leader>xs", "<cmd>VimtexStop<cr>", "Stop compilation")
  map("<leader>xk", "<cmd>VimtexClean<cr>", "Clean aux files")
end

return M
