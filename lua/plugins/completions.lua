-- lua/plugins/completions.lua

-- Modules under lua/snippets/ registered with LuaSnip, as { filetype, module }
local snippet_modules = {
  { "tex",      "snippets.latex" },
  { "typst",    "snippets.typst" },
  { "c",        "snippets.c" },
  { "python",   "snippets.python" },
  { "java",     "snippets.java" },
  { "scheme",   "snippets.lisp" },
  { "lisp",     "snippets.lisp" },
  { "sql",      "snippets.sql" },
  { "mysql",    "snippets.sql" },
  { "plsql",    "snippets.sql" },
  { "markdown", "snippets.markdown" },
  { "common",   "snippets.common" },
}

-- Filetypes that inherit the "common" snippets
local common_filetypes = {
  "python",
  "c",
  "scheme",
  "lua",
  "java",
  "javascript",
  "typescript",
  "go",
  "sh",
  "markdown",
  "tex",
  "typst",
  "sql",
  "mysql",
  "plsql",
}

local function setup_luasnip()
  local luasnip = require("luasnip")

  luasnip.setup({
    enable_autosnippets = true,
    store_selection_keys = "<Tab>",
    update_events = "TextChanged,TextChangedI",
    region_check_events = "InsertEnter",
    delete_check_events = "TextChanged",
  })

  for _, entry in ipairs(snippet_modules) do
    local ok, snippets = pcall(require, entry[2])
    if ok then
      luasnip.add_snippets(entry[1], snippets)
    else
      vim.notify(
        string.format("Failed to load snippets '%s': %s", entry[2], snippets),
        vim.log.levels.ERROR
      )
    end
  end

  for _, ft in ipairs(common_filetypes) do
    luasnip.filetype_extend(ft, { "common" })
  end
end

-- Keymaps. The preset is "none", so only the mappings below exist.
-- Each entry is a list of commands tried in order; the first one that returns
-- true stops the chain. A function returning nil/false lets the next entry run
local function blink_keymap()
  local luasnip = require("luasnip")

  local function defer(fn)
    vim.schedule(fn)
    return true
  end

  return {
    preset = "none",

    ["<C-y>"] = { "show" },

    ["<C-q>"] = {
      "hide",
      function()
        if luasnip.in_snippet() then
          luasnip.unlink_current()
          return true
        end
      end,
      "fallback",
    },

    ["<CR>"] = { "accept", "fallback" },

    ["<C-n>"] = {
      "select_next",
      function()
        if luasnip.choice_active() then
          return defer(function() luasnip.change_choice(1) end)
        end
      end,
      "show",
    },

    ["<C-p>"] = {
      "select_prev",
      function()
        if luasnip.choice_active() then
          return defer(function() luasnip.change_choice(-1) end)
        end
      end,
      "show",
    },

    ["<Tab>"] = {
      "accept",
      function()
        if luasnip.expandable() then
          return defer(luasnip.expand)
        end
      end,
      "snippet_forward",
      "fallback",
    },

    ["<S-Tab>"] = { "snippet_backward", "fallback" },
  }
end

local function setup_blink()
  require("blink.cmp").setup({
    keymap = blink_keymap(),

    completion = {
      -- Never open the menu automatically
      menu = {
        auto_show = false,
        border = "none",
        min_width = 70,
        max_height = 18,
        scrollbar = false,
        scrolloff = 2,
        winblend = 0,
        winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
        draw = {
          padding = { 1, 1 },
          gap = 1,
          columns = {
            -- { "kind_icon" },
            { "label", "label_description", gap = 1 },
            { "kind" },
          },
          components = {
            kind_icon = { width = { max = 3 } },
            label = { width = { fill = true, min = 30 } },
            label_description = { width = { min = 20, max = 20 } },
            kind = { width = { min = 12, max = 12 } },
          },
          treesitter = { "lsp" },
        },
      },

      documentation = {
        auto_show = false,
        auto_show_delay_ms = 250,
        window = {
          border = "none",
        },
      },

      ghost_text = { enabled = false },
      -- First item is preselected when opened, but not inserted into the
      -- buffer (equivalent to completeopt "noinsert")
      list = {
        selection = { preselect = true, auto_insert = false },
      },

      accept = { auto_brackets = { enabled = false } },
    },

    -- Snippets are handled by LuaSnip
    snippets = { preset = "luasnip" },

    cmdline = { enabled = false },

    sources = {
      -- Shared by every filetype
      default = { "lsp", "snippets", "path", "buffer" },

      -- Lua gets lazydev, LaTeX gets vimtex and LaTeX symbols, Markdown gets
      -- LaTeX symbols for math blocks
      per_filetype = {
        lua = { inherit_defaults = true, "lazydev" },
        tex = { inherit_defaults = true, "vimtex", "latex_symbols" },
        markdown = { inherit_defaults = true, "latex_symbols" },
      },

      providers = {
        lsp = { score_offset = 0 },
        snippets = {
          score_offset = -3,
          opts = { show_autosnippets = false },
        },
        path = { score_offset = -4 },
        buffer = { score_offset = -5 },

        -- Takes precedence over every other source (group_index = 0 before)
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },

        vimtex = {
          name = "vimtex",
          module = "blink.compat.source",
          score_offset = -1,
        },

        latex_symbols = {
          name = "latex_symbols",
          module = "blink.compat.source",
          score_offset = -2,
        },
      },
    },
  })
end

return {
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    config = setup_luasnip,
  },

  {
    "saghen/blink.cmp",
    version = "1.*", -- prebuilt fuzzy matcher binaries
    event = "InsertEnter",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "micangl/cmp-vimtex",
      "kdheepak/cmp-latex-symbols",
      {
        "saghen/blink.compat",
        version = "*",
        lazy = true,
        opts = { impersonate_nvim_cmp = true },
      },
    },
    config = setup_blink,
  },
}
