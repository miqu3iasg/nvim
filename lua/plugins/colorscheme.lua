-- lua/plugins/colorscheme.lua

return {
  { "jaredgorski/fogbell.vim", },
  { "amedoeyes/eyes.nvim" },
  {
    "metalelf0/black-metal-theme-neovim",
    lazy = false,
    priority = 1000,
    config = function()
      -- Overrides
      local split_line = "#7a7a7a"
      local accent     = "#5f8787"
      local accent_dim = "#1c2828"
      -- local str        = "#8da88c"

      require("black-metal").setup({
        theme               = "darkthrone",
        variant             = "dark",
        alt_bg              = false,
        colored_docstrings  = true,
        cursorline_gutter   = false,
        dark_gutter         = false,
        favor_treesitter_hl = false,
        plain_float         = false,
        show_eob            = true,
        term_colors         = true,
        transparent         = false,
        trve                = true,

        -- Diagnostics and code style
        diagnostics         = {
          darker     = true,
          undercurl  = false,
          background = false,
        },

        -- The following table accepts values the same as the `gui` option for normal
        -- highlights. For example, `bold`, `italic`, `underline`, `none`.
        code_style          = {
          comments       = "none",
          conditionals   = "none",
          functions      = "none",
          keywords       = "none",
          headings       = "bold", -- Markdown headings
          operators      = "none",
          keyword_return = "none",
          strings        = "none",
          variables      = "none",
        },

        -- Plugins
        -- The following options allow for more control over some plugin appearances.
        plugin              = {
          cmp = { -- works for nvim.cmp and blink.nvim
            -- Don't highlight lsp-kind items. Only the current selection will be highlighted.
            plain = false,
            -- Reverse lsp-kind items' highlights in blink/cmp menu.
            reverse = false,
          },
        },

        -- Custom highlights, override default colors
        colors              = {},

        -- Override highlight groups
        highlights          = {
          StatusLine                 = { fg = "#a8a8a8", bg = "#121212" },
          StatusLineNC               = { fg = "#5f5f5f", bg = "#050505" },

          Boolean                    = { fg = accent },
          Number                     = { fg = accent },
          Float                      = { fg = accent },
          ["@boolean"]               = { fg = accent },
          ["@number"]                = { fg = accent },
          ["@number.float"]          = { fg = accent },
          ["@float"]                 = { fg = accent },

          WinSeparator               = { fg = split_line },
          VertSplit                  = { fg = split_line },

          Search                     = { fg = accent, bg = accent_dim },
          CurSearch                  = { fg = "#000000", bg = accent },
          IncSearch                  = { fg = "#000000", bg = accent },
          Substitute                 = { fg = "#000000", bg = accent },

          ["@markup.math"]           = { fg = accent },
          ["@markup.list"]           = { fg = accent },
          ["@markup.list.checked"]   = { fg = accent },
          ["@markup.list.unchecked"] = { fg = accent },
          ["@property.yaml"]         = { fg = accent },
          MarkdownBody               = { fg = "#d0d0d0", bg = "#000000" },
          ["@markup.italic"]         = { fg = "#d0d0d0", fmt = "italic" },

          -- String                     = { fg = str },
          -- ["@string"]                = { fg = str },
          -- ["@string.documentation"]  = { fg = str },
          -- ["@string.special.symbol"] = { fg = str },
        },

        trve                = true, -- switch this to false if you want light variants
      })
      require("black-metal").load()
    end,
  },
}
