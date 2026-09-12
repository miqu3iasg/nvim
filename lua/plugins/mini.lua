-- lua/plugins/mini.lua
-- mini.nvim modules configuration for LazyVim
-- ref: https://github.com/echasnovski/mini.nvim

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

      require("mini.operators").setup({
        evaluate = {
          prefix = "g=", -- Evaluate text and replace with result
        },
        exchange = {
          prefix = "gx", -- Exchange two pieces of text
        },
        multiply = {
          prefix = "gm", -- Duplicate text
        },
        replace = {
          prefix = "gr", -- Replace text with register content
        },
        sort = {
          prefix = "gs", -- Sort text
        },
      })

      require("mini.jump").setup({
        mappings = {
          forward = "f",       -- Jump forward to char
          backward = "F",      -- Jump backward to char
          forward_till = "t",  -- Jump forward till char (before it)
          backward_till = "T", -- Jump backward till char (after it)
          repeat_jump = "\\",  -- Repeat last jump
        },
      })

      require("mini.surround").setup({
        mappings = {
          add = "sa",            -- Add surrounding in Normal and Visual modes
          delete = "sd",         -- Delete surrounding
          find = "sf",           -- Find surrounding (to the right)
          find_left = "sF",      -- Find surrounding (to the left)
          highlight = "sh",      -- Highlight surrounding
          replace = "sr",        -- Replace surrounding
          update_n_lines = "sn", -- Update `n_lines`
          suffix_last = "l",     -- Suffix to search with "prev" method
          suffix_next = "n",     -- Suffix to search with "next" method
        },
      })

      require("mini.pairs").setup()
    end,
  },
}
