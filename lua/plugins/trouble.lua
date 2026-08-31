-- lua/plugins/trouble.lua
return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  dependencies = { "folke/todo-comments.nvim" },
  opts = {
    focus = true,
    auto_close = true,
    auto_refresh = true,
    warn_no_results = false,
    open_no_results = true,
    indent_guides = false,
    win = {
      size = 0.3,
    },
    icons = {
      folder_closed = "",
      folder_open = "",
      indent = {
        fold_open = "",
        fold_closed = "",
      },
    },
    formatters = {
      severity_icon = function() return { text = "" } end,
      kind_icon = function() return { text = "" } end,
      file_icon = function() return { text = "" } end,
      folder_icon = function() return { text = "" } end,
    },
    modes = {
      diagnostics = {
        format = "{message:md} {item.source} {code} {pos}",
      },
    },
  },
  keys = {
    {
      "<leader>xx",
      "<cmd>Trouble diagnostics toggle<cr>",
      desc = "Diagnostics (Trouble)",
    },
    {
      "<leader>xX",
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    {
      "<leader>xs",
      "<cmd>Trouble symbols toggle focus=false<cr>",
      desc = "Symbols (Trouble)",
    },
    {
      "<leader>xr",
      "<cmd>Trouble lsp toggle focus=false win.position=right auto_close=false<cr>",
      desc = "LSP References/Definitions (Trouble)",
    },
    {
      "<leader>xt",
      "<cmd>Trouble todo toggle<cr>",
      desc = "TODOs (Trouble)",
    },
  },
}
