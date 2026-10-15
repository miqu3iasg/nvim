-- lua/plugins/csv.lua

-- See: https://github.com/hat0uma/csvview.nvim
-- See: https://github.com/bruhtus/dotfiles/tree/master/.vim
return {
  "hat0uma/csvview.nvim",
  enabled = false,
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

-- Put the following code into afeter/ftplugin/csv.lua:
-- local delimiter_arg = ""
-- if vim.bo.filetype == "csv" then
--   local first = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ""
--   local _, semicolons = first:gsub(";", "")
--   local _, commas = first:gsub(",", "")
--   if semicolons > commas then
--     delimiter_arg = " delimiter=;"
--   end
-- end
-- pcall(vim.cmd, "CsvViewEnable" .. delimiter_arg)
--
-- map("<leader>cv", "<cmd>CsvViewToggle<cr>", "CSV: toggle view")
-- map("<leader>ci", "<cmd>CsvViewInfo<cr>", "CSV: info")
