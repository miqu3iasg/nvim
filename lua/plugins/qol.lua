-- lua/plugins/qol.lua

-- Small quality-of-life plugins

return {

  -- Editing

  -- Jump out of brackets and quotes using Tab
  {
    "abecodes/tabout.nvim",
    event = "InsertCharPre", -- lazy-load right before the first character is inserted
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "L3MON4D3/LuaSnip",
    },
    opts = {
      -- Keybindings for forward and backward tabout
      tabkey = "<C-]",
      backwards_tabkey = "C-[",

      act_as_tab = false,
      act_as_shift_tab = false,
      default_tab = "<C-t>",
      default_shift_tab = "<C-d>",

      -- Allow tabbing backward through supported pairs
      enable_backwards = true,

      -- Keep Tab available for tabout instead of completion menus
      completion = false,

      -- Tab out instead of shifting when at the beginning of content
      ignore_beginning = true,

      -- Filetypes where tabout is disabled
      exclude = {},

      -- Pairs that trigger tabout
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
    },
  },

  -- Companion to tabout, free <Tab> from LuaSnip's default keybinding
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
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
