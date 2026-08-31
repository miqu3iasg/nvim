return {
  { "vim-scripts/newsprint.vim" },
  { "gbprod/nord.nvim" },
  { "slugbyte/lackluster.nvim", },
  { "kdheepak/monochrome.nvim" },
  { "vim-scripts/zenesque.vim", },
  { "blazkowolf/gruber-darker.nvim" },
  { "jaredgorski/fogbell.vim", },
  { "oahlen/iceberg.nvim", },
  { "barrettruth/midnight.nvim" },
  { "jwbaldwin/oscura.nvim" },
  { "craftzdog/solarized-osaka.nvim" },
  { "amedoeyes/eyes.nvim" },
  { "Skardyy/makurai-nvim", },
  { "ellisonleao/gruvbox.nvim" },
  { "jnurmine/Zenburn", },
  { "RRethy/base16-nvim", },
  {
    "sainnhe/gruvbox-material",
    config = function()
      vim.g.gruvbox_material_background = "hard"
    end,
  },
  {
    "blazkowolf/gruber-darker.nvim",
    opts = {
      bold = false,
    },
  },
  {
    "zenbones-theme/zenbones.nvim",
    dependencies = "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
    italic = false,
  },
  {
    "metalelf0/black-metal-theme-neovim",
    lazy = false,
    priority = 1000,
    config = function()
      require("black-metal").setup({
        -----MAIN OPTIONS-----
        --
        -- Can be one of: bathory | burzum | dark-funeral | darkthrone | emperor | gorgoroth | immortal | impaled-nazarene | khold | marduk | mayhem | nile | taake | thyrfing | venom | windir
        theme = "gorgoroth",
        -- Can be one of: 'light' | 'dark', or set via vim.o.background
        variant = "dark",
        -- Use an alternate, lighter bg
        alt_bg = false,
        -- If true, docstrings will be highlighted like strings, otherwise they will be
        -- highlighted like comments. Note, behavior is dependent on the language server.
        colored_docstrings = true,
        -- If true, highlights the {sign,fold} column the same as cursorline
        cursorline_gutter = true,
        -- If true, highlights the gutter darker than the bg
        dark_gutter = false,
        -- if true favor treesitter highlights over semantic highlights
        favor_treesitter_hl = false,
        -- Don't set background of floating windows. Recommended for when using floating
        -- windows with borders.
        plain_float = false,
        -- Show the end-of-buffer character
        show_eob = true,
        -- If true, enable the vim terminal colors
        term_colors = true,
        -- Keymap (in normal mode) to toggle between light and dark variants.
        toggle_variant_key = nil,
        -- Don't set background
        transparent = false,
        -- There is no light in trve black metal: if true, light variants are disabled
        -- and loading one falls back to dark. Set to false to allow light variants.
        trve = true,

        -----Diagnostics and code style-----
        --
        diagnostics = {
          darker = true,     -- Darker colors for diagnostic
          undercurl = true,  -- Use undercurl for diagnostics
          background = true, -- Use background color for virtual text
        },
        -- The following table accepts values the same as the `gui` option for normal
        -- highlights. For example, `bold`, `italic`, `underline`, `none`.
        code_style = {
          comments = "italic",
          conditionals = "none",
          functions = "none",
          keywords = "none",
          headings = "bold", -- Markdown headings
          operators = "none",
          keyword_return = "none",
          strings = "none",
          variables = "none",
        },

        -----Plugins-----
        --
        -- The following options allow for more control over some plugin appearances.
        plugin = {
          lualine = {
            -- Bold lualine_a sections
            bold = true,
            -- Don't set section/component backgrounds. Recommended to not set
            -- section/component separators.
            plain = false,
          },
          cmp = { -- works for nvim.cmp and blink.nvim
            -- Don't highlight lsp-kind items. Only the current selection will be highlighted.
            plain = false,
            -- Reverse lsp-kind items' highlights in blink/cmp menu.
            reverse = false,
          },
        },

        -- CUSTOM HIGHLIGHTS --
        --
        -- Override default colors
        colors = {},
        -- Override highlight groups
        highlights = {},
        trve = true, -- switch this to false if you want light variants
      })
      require("black-metal").load()
    end,
  },
  {
    "vague2k/vague.nvim",
    config = function()
      require("vague").setup({
        -- optional configuration here
        -- transparent = true,
        style = {
          -- "none" is the same thing as default. But "italic" and "bold" are also valid options
          boolean = "none",
          number = "none",
          float = "none",
          error = "none",
          comments = "none",
          conditionals = "none",
          functions = "none",
          headings = "bold",
          operators = "none",
          strings = "none",
          variables = "none",

          -- keywords
          keywords = "none",
          keyword_return = "none",
          keywords_loop = "none",
          keywords_label = "none",
          keywords_exception = "none",

          -- builtin
          builtin_constants = "none",
          builtin_functions = "none",
          builtin_types = "none",
          builtin_variables = "none",
        },
        colors = {
          func = "#bc96b0",
          keyword = "#787bab",
          -- string = "#d4bd98",
          string = "#8a739a",
          -- string = "#f2e6ff",
          -- number = "#f2e6ff",
          -- string = "#d8d5b1",
          number = "#8f729e",
          -- type = "#dcaed7",
        },
      })
    end,
  },
}
