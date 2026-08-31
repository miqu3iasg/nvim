-- /home/miqu3iasg/.config/nvim/lua/plugins/fmt_utils.lua

return {
  -- treesj: split/join blocks of code (e.g. tables, function calls) with a single keymap
  {
    "Wansmer/treesj",
    keys = { "<space>j" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("treesj").setup({})
    end,
  },

  -- nvim-autopairs: auto-closes brackets, quotes, etc. while typing
  {
    "windwp/nvim-autopairs",
    event = { "InsertEnter" },
    config = function()
      local autopairs = require("nvim-autopairs")
      autopairs.setup({
        enable_check_bracket_line = false, -- don't check for existing closing char on the same line
        enable_afterquote = false,         -- don't add pairs right after a quote
        check_ts = true,                   -- use treesitter to decide when to pair
        ts_config = {
          lua = { "string" },              -- don't add pairs inside lua string treesitter nodes
          java = false,                    -- don't check treesitter on java
        },
      })
    end,
  },

  -- mini.surround: add/delete/replace surrounding characters (quotes, brackets, tags)
  {
    "echasnovski/mini.surround",
    opts = {
      custom_surroundings = nil,
      highlight_duration = 500,
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
      n_lines = 20,
      respect_selection_type = false,
      search_method = "cover",
      silent = false,
    },
  },

  -- nvim-colorizer.lua: highlights color codes (hex, rgb, etc.) with their actual color
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        "*",
        css = { rgb_fn = true },
      })
    end,
  },

  -- tabout.nvim: use Tab to "jump out" of brackets/quotes instead of just indenting
  {
    "abecodes/tabout.nvim",
    lazy = false,
    config = function()
      require("tabout").setup({
        tabkey = "<Tab>",             -- key to trigger tabout, set to an empty string to disable
        backwards_tabkey = "<S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
        act_as_tab = true,            -- shift content if tab out is not possible
        act_as_shift_tab = false,     -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
        default_tab = "<C-t>",        -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
        default_shift_tab = "<C-d>",  -- reverse shift default action,
        enable_backwards = true,      -- well ...
        completion = false,           -- if the tabkey is used in a completion pum
        tabouts = {
          { open = "'", close = "'" },
          { open = '"', close = '"' },
          { open = "`", close = "`" },
          { open = "(", close = ")" },
          { open = "[", close = "]" },
          -- { open = "{", close = "}" },
        },
        ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
        exclude = {}, -- tabout will ignore these filetypes
      })
    end,
    dependencies = { -- These are optional
      "nvim-treesitter/nvim-treesitter",
      "L3MON4D3/LuaSnip",
      "hrsh7th/nvim-cmp",
    },
    opt = true,              -- Set this to true if the plugin is optional
    event = "InsertCharPre", -- Set the event to 'InsertCharPre' for better compatibility
    priority = 1000,
  },

  -- LuaSnip: disable its default Tab keybinding so tabout.nvim can take over
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      -- Disable default tab keybinding in LuaSnip
      return {}
    end,
  },

  -- vim-maximizer: toggle zoom on the current split
  {
    "szw/vim-maximizer",
    keys = {
      { "<leader>sm", "<cmd>MaximizerToggle<cr>", desc = "Toggle zoom split" },
    },
  },
}
