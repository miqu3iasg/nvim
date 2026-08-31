return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "echasnovski/mini.icons" },
  config = function()
    require("lualine").setup({
      options = {
        icons_enabled = false,
        theme = "auto",
        component_separators = "",
        section_separators = "",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {
          "branch",
          {
            "diff",
            symbols = {
              added = "+",
              modified = "~",
              removed = "-",
            },
          },
        },
        lualine_c = { "filename" },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
    })
    vim.api.nvim_create_user_command("ToggleStatusline", function()
      vim.o.laststatus = vim.o.laststatus == 0 and 3 or 0
    end, {})
  end,
}
