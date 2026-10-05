-- lua/plugins/csv.lua

-- See: https://github.com/hat0uma/csvview.nvim
-- See: https://github.com/bruhtus/dotfiles/tree/master/.vim
return {
  "hat0uma/csvview.nvim",
  ft = { "csv", "tsv" },
  cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle", "CsvViewInfo" },
  opts = {
    parser = {
      delimiter = { default = ",", ft = { tsv = "\t" } },
      comments = { "#", "//" },
    },

    view = {
      display_mode = "highlight", -- aligned columns, no drawn borders
      header_lnum = 1,
      sticky_header = { enabled = true },
    },

    keymaps = {
      textobject_field_inner = { "if", mode = { "o", "x" } },
      textobject_field_outer = { "af", mode = { "o", "x" } },

      -- Field / row navigation
      jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
      jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
      jump_next_row = { "<Enter>", mode = { "n", "v" } },
      jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
    },
  },
}
