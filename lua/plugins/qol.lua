-- lua/plugins/qol.lua

-- Small quality-of-life plugins

return {
  {
    "echasnovski/mini.nvim",
    version = false, -- use latest commit (main branch)
    event = "VeryLazy",
    config = function()
      require("mini.align").setup({
        mappings = {
          start = "ga",              -- Start align in Normal and Visual modes
          start_with_preview = "gA", -- Start align with live preview
        },
      })

      require("mini.comment").setup({
        mappings = {
          comment = "gc",        -- Toggle comment (operator, works with motion)
          comment_line = "gcc",  -- Toggle comment on current line
          comment_visual = "gc", -- Toggle comment on visual selection
          textobject = "gc",     -- Comment textobject (e.g. `dgc`)
        },
      })
    end,
  },

  -- I don't like icons btw.
  { "nvim-tree/nvim-web-devicons", enabled = false },
}
