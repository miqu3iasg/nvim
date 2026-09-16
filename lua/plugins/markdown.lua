-- lua/plugins/markdown.lua

return {
  -- Make sure the markdown parsers are present for everything below
  -- (render-markdown, obsidian's own LSP, treesitter folding, etc).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "markdown", "markdown_inline" })
      return opts
    end,
  },

  -- Inline rendering: headings, bullets, checkboxes, code blocks,
  -- tables and callouts rendered "live" while still editing plain
  -- text underneath.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<leader>om", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Toggle in-editor preview" },
    },
    opts = {
      enabled = false, -- off by default; toggle with <leader>om

      win_options = {
        conceallevel = { default = 0, rendered = 2 },
        concealcursor = { default = "", rendered = "nc" },
      },

      heading = {
        sign = false,
        icons = { "\u{f4e0} " }, -- nf-oct-heading
        position = "inline",
        backgrounds = {},        -- no background color on headings
        -- All six levels point at the same highlight group -> no
        -- color hierarchy between H1..H6. The group itself is defined
        -- (and kept theme-synced) in config() below.
        foregrounds = {
          "RenderMarkdownH1", "RenderMarkdownH1", "RenderMarkdownH1",
          "RenderMarkdownH1", "RenderMarkdownH1", "RenderMarkdownH1",
        },
      },

      code = {
        sign = false,
        width = "block",
        border = "thick",
        style = "normal", -- no background on the code block's line
        language = false, -- don't show the language name label
      },

      bullet = {
        enabled = false,
        -- icons = { "●", "○", "◆", "◇" },
      },

      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
        custom = {
          in_progress = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
        },
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)

      -- Pulls colors from whatever colorscheme is active right now,
      -- instead of hardcoding hex. Re-run on every colorscheme change
      -- so switching themes throughout the day just works.
      local function set_colors()
        local hl = vim.api.nvim_set_hl

        -- link = false forces resolution of linked groups into their
        -- final effective color, instead of possibly returning no fg
        -- at all if the theme defines Title via a link.
        local title = vim.api.nvim_get_hl(0, { name = "Title", link = false })
        local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
        local heading_fg = title.fg or normal.fg -- fallback if Title has no fg

        -- Single group used by all heading levels (see opts.heading.foregrounds above)
        hl(0, "RenderMarkdownH1", { fg = heading_fg, bold = true })

        -- Code blocks: no extra background, text color inherits from
        -- Normal/syntax highlighting underneath.
        hl(0, "RenderMarkdownCode", { bg = "NONE" })
        hl(0, "RenderMarkdownCodeInline", { bg = "NONE" })
      end

      set_colors()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_colors })
    end,
  },

  -- Paste an image from the clipboard straight into the note as a
  -- file + link, with automatic naming/resizing. obsidian.nvim
  -- auto-detects this plugin and upgrades its own `:Obsidian paste_img`
  -- (bound to <leader>ii in obsidian.lua) to use it -- no new keymap
  -- needed here.
  {
    "HakonHarnes/img-clip.nvim",
    ft = { "markdown" },
    opts = {
      default = {
        dir_path = "Resources", -- matches attachments.folder in obsidian.lua
        relative_to_current_file = false,
      },
    },
  },

  -- Table editing: type "|col1|col2|", hit <leader>tm once, and every
  -- following "|" keeps columns aligned automatically as you type.
  {
    "dhruvasagar/vim-table-mode",
    ft = { "markdown" },
    dependencies = { "godlygeek/tabular" },
    cmd = { "TableModeToggle", "TableModeEnable", "TableModeDisable", "Tableize" },
    init = function()
      vim.g.table_mode_corner = "|"
      vim.g.table_mode_corner_corner = "|"
      vim.g.table_mode_header_fillchar = "-"
      vim.g.table_mode_align_char = ":"

      -- Realign columns as you type, not just on demand.
      vim.g.table_mode_auto_align = 1

      -- Delimiter used by :Tableize (and <leader>tt below) to turn
      -- delimiter-separated text - e.g. lines pasted from a CSV -
      -- into a proper markdown table.
      vim.g.table_mode_delimiter = ","
    end,
    keys = {
      { "<leader>tm",  "<cmd>TableModeToggle<cr>", ft = "markdown",                        desc = "Toggle table mode" },
      { "<leader>tt",  ":Tableize<cr>",            mode = "v",                             ft = "markdown",           desc = "Tableize selection" },
      { "<leader>tr",  ft = "markdown",            desc = "Realign table" },
      { "<leader>ts",  ft = "markdown",            desc = "Sort table column under cursor" },
      { "<leader>tdd", ft = "markdown",            desc = "Delete table row" },
      { "<leader>tdc", ft = "markdown",            desc = "Delete table column" },
    },
  },

  -- Smart lists: continues bullets/numbers/checkboxes on `o`/`O`,
  -- renumbers ordered lists after deleting or reordering items.
  --
  -- <CR> in insert mode is deliberately guarded: if blink.cmp's menu
  -- is open, it defers to blink's own accept action first (so your
  -- completions.lua keymaps keep working exactly as before); only
  -- when nothing is being completed does it fall through to
  -- AutolistNewBullet. <Tab>/<S-Tab> are intentionally left alone
  -- since they're already doing double duty for blink.cmp + LuaSnip.
  --
  -- Wrapped in a FileType autocmd (rather than relying on config()
  -- running once) so keymaps and the recalculate autocmd are (re)set
  -- for every markdown buffer you open, not just the first one in the
  -- session.
  {
    "gaoDean/autolist.nvim",
    ft = { "markdown" },
    config = function()
      require("autolist").setup({})

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(args)
          local map = function(mode, lhs, rhs, desc, opts)
            opts = opts or {}
            vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", {
              buffer = args.buf,
              silent = true,
              desc = desc,
            }, opts))
          end

          map("i", "<CR>", function()
            local ok, blink = pcall(require, "blink.cmp")
            if ok and blink.is_visible and blink.is_visible() then
              return blink.select_and_accept()
            end
            return "<CR><cmd>AutolistNewBullet<cr>"
          end, "Confirm completion, or continue the list", { expr = true })

          map("n", "o", "o<cmd>AutolistNewBullet<cr>", "New line, continuing the list")
          map("n", "O", "O<cmd>AutolistNewBulletBefore<cr>", "New line above, continuing the list")
          map("n", "<leader>lr", "<cmd>AutolistRecalculate<cr>", "Recalculate list numbering")

          vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
            buffer = args.buf,
            callback = function()
              require("autolist").recalculate()
            end,
          })
        end,
      })
    end,
  },

  -- Markdown linting (style/consistency issues prettier won't catch:
  -- duplicate headings, bad heading hierarchy, trailing punctuation in
  -- headings, etc). The binary is pulled in automatically below.
  {
    "mfussenegger/nvim-lint",
    ft = { "markdown" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = lint.linters_by_ft or {}
      lint.linters_by_ft.markdown = { "markdownlint-cli2" }

      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        pattern = { "*.md", "*.markdown" },
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },

  -- Installs non-LSP CLI tools through Mason automatically, the same
  -- way mason-lspconfig's ensure_installed does for language servers.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "markdownlint-cli2" },
    },
  },

  -- Live browser preview, synced to the cursor as you type.
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_theme = "dark"
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Toggle browser preview" },
    },
  },
}
