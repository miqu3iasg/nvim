return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "echasnovski/mini.icons" },
  event = "VeryLazy",
  init = function()
    vim.o.laststatus = 0
  end,
  config = function()
    require("lualine").setup({
      options = {
        icons_enabled = false,
        theme = "auto",
        component_separators = "",
        section_separators = "",
        globalstatus = false,
        disabled_filetypes = {
          statusline = { "fzf" },
        },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {
          "branch",
          {
            "diff",
            symbols = { added = "+", modified = "~", removed = "-" },
          },
        },
        lualine_c = { "filename" },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
    })

    vim.o.laststatus = 0

    vim.api.nvim_create_user_command("ToggleStatusline", function()
      vim.o.laststatus = vim.o.laststatus == 0 and 2 or 0
    end, {})
  end,
}
