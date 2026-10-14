-- lua/plugins/qol.lua

-- Small quality-of-life plugins

return {

  -- Editing

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

      require("mini.pairs").setup()
    end,
  },

  -- Auto-close and auto-rename HTML/JSX tags
  {
    "windwp/nvim-ts-autotag",
    -- NOTE: real filetype names are javascriptreact/typescriptreact (not jsx/tsx)
    ft = {
      "html", "xml", "javascriptreact", "typescriptreact",
      "vue", "svelte", "php", "markdown",
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      opts = {
        enable_close = true,          -- auto-close tags as you type
        enable_rename = true,         -- rename the closing tag when the opening one changes
        enable_close_on_slash = true, -- auto-close when typing </
      },
    },
  },

  -- Split/join code blocks (arrays, objects, args, etc.) using treesitter
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    keys = {
      { "<leader>cj", function() require("treesj").toggle() end, desc = "Toggle split/join" },
      { "<leader>cb", function() require("treesj").join() end,   desc = "Join code block" },
      { "<leader>cs", function() require("treesj").split() end,  desc = "Split code block" },
      {
        "<leader>cm",
        function() require("treesj").toggle({ split = { recursive = true } }) end,
        desc = "Toggle split/join (recursive)",
      },
    },
    opts = {
      use_default_keymaps = false, -- we define our own keymaps above
      max_join_length = 120,       -- don't join blocks that would exceed this length
      cursor_behavior = "hold",    -- keep the cursor where it was
      notify = false,              -- stay quiet on unsupported language/node
      dot_repeat = true,           -- make the operation repeatable with `.`
    },
  },

  -- Highlight

  -- Highlight color codes with their actual colors
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPost",
    opts = {
      filetypes = {
        "*",
        css = { rgb_fn = true },
      },
      user_default_options = {
        names = false,
      },
    },
  },

  -- Highlight and navigate TODO/FIXME/HACK comments
  {
    "folke/todo-comments.nvim",
    event = "BufReadPost",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
    },
    opts = {
      signs = true, -- show a sign in the gutter for each keyword
      keywords = {
        FIX  = { icon = " ", color = "warning", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", color = "default", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
      },
      highlight = {
        keyword = "fg", -- only color the keyword itself, no background
        before = "",
        after = "",     -- don't extend the color to the rest of the line
      },
    },
  },

  -- UI

  -- I don't like icons btw.
  { "nvim-tree/nvim-web-devicons", enabled = false },
}
