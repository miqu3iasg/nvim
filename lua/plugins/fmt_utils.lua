-- lua/plugins/fmt_utils.lua

return {
  -- Split and join code blocks with a single keymap.
  {
    "Wansmer/treesj",
    keys = { "<space>i" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("treesj").setup({})
    end,
  },

  -- Highlight color codes with their actual colors.
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        "*",
        css = { rgb_fn = true },
      })
    end,
  },

  -- Jump out of brackets and quotes using Tab.
  {
    "abecodes/tabout.nvim",
    lazy = false,
    config = function()
      require("tabout").setup({
        -- Keybindings for forward and backward tabout.
        tabkey = "<Tab>",
        backwards_tabkey = "<S-Tab>",

        -- Fall back to regular indentation when tabout is unavailable.
        act_as_tab = true,
        act_as_shift_tab = false,

        -- Default indentation keys when tabout is unavailable.
        default_tab = "<C-t>",
        default_shift_tab = "<C-d>",

        -- Allow tabbing backward through supported pairs.
        enable_backwards = true,

        -- Keep Tab available for tabout instead of completion menus.
        completion = false,

        -- Pairs that trigger tabout.
        tabouts = {
          { open = "'", close = "'" },
          { open = '"', close = '"' },
          { open = "`", close = "`" },
          { open = "(", close = ")" },
          { open = "[", close = "]" },
          { open = "{", close = "}" },
          { open = "$", close = "$" },
          { open = "%", close = "%" },
        },

        -- Tab out instead of shifting when at the beginning of content.
        ignore_beginning = true,

        -- Filetypes where tabout is disabled.
        exclude = {},
      })
    end,

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "L3MON4D3/LuaSnip",
      "hrsh7th/nvim-cmp",
    },

    -- Load the plugin as an optional dependency.
    opt = true,

    -- Load before inserting a character for better compatibility.
    event = "InsertCharPre",

    priority = 1000,
  },

  -- Disable LuaSnip's default Tab keybinding.
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
    end,
  },

  -- Auto-close and auto-rename HTML/JSX tags.
  {
    "windwp/nvim-ts-autotag",
    ft = { "html", "xml", "jsx", "tsx", "vue", "svelte", "php", "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-ts-autotag").setup({
        opts = {
          -- Auto-close tags as you type.
          enable_close = true,
          -- Rename the closing tag when the opening tag changes.
          enable_rename = true,
          -- Auto-close on <>.
          enable_close_on_slash = false,
        },
      })
    end,
  },

  -- Highlight and navigate TODO/FIXME/HACK comments.
  {
    "folke/todo-comments.nvim",
    event = "BufReadPost",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("todo-comments").setup({
        -- Show a sign in the gutter for each keyword.
        signs = true,
        keywords = {
          FIX  = { icon = " ", color = "warning", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
          TODO = { icon = " ", color = "info" },
          HACK = { icon = " ", color = "warning" },
          WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
          PERF = { icon = " ", color = "default", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
          NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        },
        highlight = {
          -- Only color the keyword text itself, no background.
          keyword = "fg",
          -- Don't extend the color to the rest of the comment line.
          after = "",
          before = "",
        },
      })
    end,
    keys = {
      -- Jump to next/previous TODO-style comment.
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
    },
  },
}
