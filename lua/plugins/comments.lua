return {
  "numToStr/Comment.nvim",
  keys = {
    {
      "<leader>cc",
      function()
        require("Comment.api").toggle.linewise.current()
      end,
      mode = "n",
      desc = "Toggle comment line",
    },
    {
      "<leader>cc",
      function()
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("gc", true, false, true),
          "x",
          false
        )
      end,
      mode = "v",
      desc = "Toggle comment selection",
    },
  },
}
