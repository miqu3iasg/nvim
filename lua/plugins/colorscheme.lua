-- lua/plugins/colorscheme.lua

return {
  { "slugbyte/lackluster.nvim", },
  { "kdheepak/monochrome.nvim" },
  { "jaredgorski/fogbell.vim", },
  { "jwbaldwin/oscura.nvim" },
  { "amedoeyes/eyes.nvim" },
  {
    "blazkowolf/gruber-darker.nvim",
    opts = {
      bold = false,
    },
  },
  {
    "metalelf0/black-metal-theme-neovim",
    lazy = false,
    priority = 1000,
    config = function()
      require("black-metal").setup({
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

        -- Diagnostics and code style
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

        -- Plugins
        --
        -- The following options allow for more control over some plugin appearances.
        plugin = {
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
}
