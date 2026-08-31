---@module 'render-markdown'
---@type LazySpec
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>om", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle markdown/latex render" },
  },
  ---@type render.md.UserConfig
  opts = {
    file_types = { "markdown" },
    render_modes = true, -- keep rendering in all modes, including insert
    latex = {
      enabled = true,
      converter = "latex2text",
    },
  },
}
