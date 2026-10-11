-- lua/plugins/completions.lua
--
-- Requires ripgrep for the "rg" source
--
-- $ sudo pacman -S ripgrep

-- Modules under lua/snippets/ that are registered with LuaSnip, as pairs of
-- filetype and module name. The "common" entry is shared across filetypes via
-- `common_filetypes`
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

-- Registers the snippets exported by `module` for `filetype`. A module that
-- fails to load is reported but does not abort the remaining registrations
local function load_snippets(luasnip, filetype, module)
  local ok, snippets = pcall(require, module)
  if not ok then
    vim.notify(
      string.format("Failed to load snippets '%s' for filetype '%s': %s", module, filetype, snippets),
      vim.log.levels.ERROR
    )
    return
  end
  luasnip.add_snippets(filetype, snippets)
end

-- Configures LuaSnip, loads friendly-snippets (except for LaTeX, which uses
-- custom snippets only) and registers the local snippet modules. Snippet
-- navigation keys live in the cmp mappings below because they depend on the
-- state of the completion menu
local function setup_luasnip()
  local luasnip = require("luasnip")

  luasnip.setup({
    enable_autosnippets = true,
    store_selection_keys = "<Tab>",
    update_events = "TextChanged,TextChangedI",
    region_check_events = "InsertEnter",
    delete_check_events = "TextChanged",
  })

  require("luasnip.loaders.from_vscode").lazy_load({ exclude = { "tex" } })

  for _, entry in ipairs(snippet_modules) do
    load_snippets(luasnip, entry[1], entry[2])
  end

  for _, ft in ipairs(common_filetypes) do
    luasnip.filetype_extend(ft, { "common" })
  end
end

-- Returns the buffers shown in any window, skipping files larger than 1 MB so
-- that the buffer source stays fast. Used as the buffer source's scan list
local function visible_bufnrs()
  local bufs = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ok, stats = pcall((vim.uv or vim.loop).fs_stat, vim.api.nvim_buf_get_name(buf))
    if not (ok and stats and stats.size > 1024 * 1024) then
      bufs[buf] = true
    end
  end
  return vim.tbl_keys(bufs)
end

-- Sources shared by every filetype. All of them live in a single group, so
-- results are merged and ordered by `priority` (higher first) instead of lower
-- groups being hidden whenever a higher one returns something
local function base_sources()
  return {
    { name = "nvim_lsp", priority = 1000 },
    { name = "luasnip",  priority = 750, option = { show_autosnippets = false } },
    { name = "path",     priority = 500, option = { trailing_slash = false } },
    { name = "buffer",   priority = 250, option = { get_bufnrs = visible_bufnrs } },
    { name = "rg",       priority = 100, keyword_length = 3 },
  }
end

-- Builds a cmp source configuration made of the base sources plus `extra`
local function sources_with(extra)
  local list = base_sources()
  for _, src in ipairs(extra) do
    table.insert(list, src)
  end
  return require("cmp").config.sources(list)
end

-- Adds filetype-specific sources on top of the base set. Lua buffers get
-- lazydev, whose group_index of 0 makes it take precedence over every other
-- source. LaTeX buffers get vimtex (citations, references, labels) and LaTeX
-- symbols. Markdown gets LaTeX symbols for math blocks
local function setup_filetype_sources()
  local cmp = require("cmp")

  cmp.setup.filetype("lua", {
    sources = sources_with({ { name = "lazydev", group_index = 0 } }),
  })

  cmp.setup.filetype("tex", {
    sources = sources_with({
      { name = "vimtex",        priority = 900 },
      { name = "latex_symbols", priority = 800 },
    }),
  })

  cmp.setup.filetype("markdown", {
    sources = sources_with({
      { name = "latex_symbols", priority = 800 },
    }),
  })
end

-- Short labels shown in the right-hand column of the menu for each source
local source_names = {
  nvim_lsp = "LSP",
  luasnip = "Snippet",
  path = "Path",
  buffer = "Buffer",
  rg = "Ripgrep",
  vimtex = "VimTeX",
  latex_symbols = "Symbols",
  lazydev = "LazyDev",
}

-- Display names for completion kinds that differ from the LSP name. Kinds not
-- listed here are shown unchanged.
local kind_names = {
  EnumMember = "Enum Member",
  TypeParameter = "Type Parameter",
}

-- Window options for the completion menu and the documentation window. The
-- borders use the CmpBorder and CmpDocBorder highlight groups, so their color
-- is controlled by the colorscheme
local function ui_window()
  local cmp = require("cmp")
  return {
    completion = cmp.config.window.bordered({
      border = "single",
      scrollbar = false,
      winhighlight = "Normal:Pmenu,FloatBorder:CmpBorder,CursorLine:PmenuSel,Search:None",
    }),
    documentation = cmp.config.window.bordered({
      border = "single",
      winhighlight = "Normal:NormalFloat,FloatBorder:CmpDocBorder",
    }),
  }
end

-- Menu layout: kind, label, then kind again followed by the source name. The
-- kind in the last column is padded to 14 cells, the width of the longest
-- name, so that source names stay aligned. Labels are truncated at 50 cells
local function ui_formatting()
  return {
    fields = { "kind", "abbr", "menu" },
    expandable_indicator = true,
    format = function(entry, item)
      local kind = kind_names[item.kind] or item.kind
      local source = source_names[entry.source.name] or entry.source.name
      item.kind = kind
      item.menu = string.format("%-14s %s", kind, source)
      if #item.abbr > 50 then
        item.abbr = item.abbr:sub(1, 49) .. "…"
      end
      return item
    end,
  }
end

-- Insert-mode key bindings. Keys already used by custom insert-mode mappings
-- (<C-a>, <C-e>, <C-b>, <C-f>, <C-h>, <C-l>, <C-t>, <C-d>, <C-j>, <C-s>) and
-- all <M-*> keys are intentionally avoided
local keys = {
  open = "<C-y>",           -- Open the menu manually
  quit = "<C-q>",           -- Close the menu, or leave the current snippet if no menu is open
  accept = "<CR>",          -- Accept the selected item, only while the menu is open
  next = "<C-n>",           -- Next item, else next snippet choice, else open the menu
  prev = "<C-p>",           -- Previous item, else previous snippet choice, else open the menu
  docs_down = "<PageDown>", -- Scroll the documentation window while the menu is open
  docs_up = "<PageUp>",
  smart_tab = "<Tab>",      -- Accept, expand or jump a snippet, tab out, or silent accept
  smart_stab = "<S-Tab>",   -- Jump to the previous snippet field
}

-- Longest time, in milliseconds, to wait for sources before a silent accept
-- gives up and falls back to the original key
local SILENT_TIMEOUT_MS = 250

-- Characters after the cursor that <Tab> should skip over, which is delegated
-- to tabout.nvim through the mapping fallback
local TABOUT = {
  ["'"] = true,
  ['"'] = true,
  ["`"] = true,
  [")"] = true,
  ["]"] = true,
  ["}"] = true,
  ["$"] = true,
  ["%"] = true,
  ["\\"] = true,
}

-- Returns the character immediately after the cursor, or an empty string
local function next_char()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return vim.api.nvim_get_current_line():sub(col + 1, col + 1)
end

-- Returns whether the cursor sits right after a word or path character.
-- Silent accept only runs in that case, so <Tab> in indentation or after
-- whitespace stays a plain Tab without any delay
local function completable_before_cursor()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  if col == 0 then
    return false
  end
  local ch = vim.api.nvim_get_current_line():sub(col, col)
  return ch:match("[%w_%.%/\\]") ~= nil
end

-- Returns whether the cursor is inside an active LuaSnip snippet
local function in_snippet()
  local ok, ls = pcall(require, "luasnip")
  return ok and ls.session.current_nodes[vim.api.nvim_get_current_buf()] ~= nil
end

-- True while a silent accept is waiting for sources, to ignore repeated keys
local pending = false

-- Accepts the top completion candidate without showing the menu. nvim-cmp has
-- no native way to do this, so the function requests completion, waits for the
-- "menu_opened" event that signals the candidates have arrived, and confirms
-- the first one right away. If no source answers within SILENT_TIMEOUT_MS the
-- menu is closed and `fallback` runs, which normally inserts a regular Tab
local function silent_accept(cmp, confirm_opts, fallback)
  if pending then
    return
  end
  if not completable_before_cursor() then
    return fallback()
  end

  pending = true
  local uv = vim.uv or vim.loop
  local timer = assert(uv.new_timer())
  local handler

  -- Runs once, from either the event or the timer. Confirmation and fallback
  -- are scheduled because this may execute in a libuv callback
  local function finish(accepted)
    if not pending then
      return
    end
    pending = false
    cmp.event:off("menu_opened", handler)
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    vim.schedule(function()
      if accepted then
        cmp.confirm(confirm_opts)
      else
        cmp.close()
        fallback()
      end
    end)
  end

  handler = function()
    finish(true)
  end

  cmp.event:on("menu_opened", handler)
  timer:start(SILENT_TIMEOUT_MS, 0, function()
    finish(false)
  end)
  cmp.complete({ reason = cmp.ContextReason.Manual })
end

-- Builds the cmp mapping table from `keys`. Every mapping that cannot act
-- calls `fallback`, which runs whatever the key did before cmp took it over
local function build_mappings()
  local cmp = require("cmp")
  local luasnip = require("luasnip")
  local k = keys

  local confirm_opts = {
    select = true,
    behavior = cmp.ConfirmBehavior.Insert,
  }

  -- Wraps `action` so that it only runs while the menu is open
  local function when_visible(action)
    return function(fallback)
      if cmp.visible() then
        action()
      else
        fallback()
      end
    end
  end

  -- Context-sensitive <Tab>. In select mode it only jumps to the next snippet
  -- field. Otherwise it tries, in order: accepting the open menu's item,
  -- expanding a snippet trigger or jumping to the next field, tabbing out of a
  -- closing pair, and finally a silent accept
  local function smart_tab(fallback)
    if vim.fn.mode():sub(1, 1) == "s" then
      if luasnip.jumpable(1) then
        luasnip.jump(1)
      else
        fallback()
      end
      return
    end

    if cmp.visible() then
      cmp.confirm(confirm_opts)
      return
    end

    if luasnip.expand_or_jumpable() then
      luasnip.expand_or_jump()
      return
    end

    if TABOUT[next_char()] then
      return fallback()
    end

    silent_accept(cmp, confirm_opts, fallback)
  end

  -- Jumps to the previous snippet field when one exists
  local function smart_stab(fallback)
    if luasnip.jumpable(-1) then
      luasnip.jump(-1)
    else
      fallback()
    end
  end

  return {
    [k.open] = cmp.mapping(function()
      cmp.complete({ reason = cmp.ContextReason.Manual })
    end, { "i" }),

    [k.quit] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.close()
      elseif in_snippet() then
        luasnip.unlink_current()
      else
        fallback()
      end
    end, { "i", "s" }),

    [k.accept] = cmp.mapping(function(fallback)
      if cmp.visible() and cmp.get_selected_entry() then
        cmp.confirm(confirm_opts)
      else
        fallback()
      end
    end, { "i" }),

    [k.next] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
      elseif luasnip.choice_active() then
        luasnip.change_choice(1)
      else
        cmp.complete({ reason = cmp.ContextReason.Manual })
      end
    end, { "i" }),

    [k.prev] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
      elseif luasnip.choice_active() then
        luasnip.change_choice(-1)
      else
        cmp.complete({ reason = cmp.ContextReason.Manual })
      end
    end, { "i" }),

    [k.docs_down] = cmp.mapping(when_visible(function()
      cmp.scroll_docs(4)
    end), { "i" }),

    [k.docs_up] = cmp.mapping(when_visible(function()
      cmp.scroll_docs(-4)
    end), { "i" }),

    [k.smart_tab] = cmp.mapping(smart_tab, { "i", "s" }),
    [k.smart_stab] = cmp.mapping(smart_stab, { "i", "s" }),
  }
end

-- Applies the global nvim-cmp configuration and the per-filetype overrides
local function setup_cmp()
  local cmp = require("cmp")

  vim.opt.completeopt = { "menu", "menuone", "noinsert" }

  cmp.setup({
    enabled = function()
      return vim.bo.buftype ~= "prompt"
    end,

    completion = {
      -- Never open the menu automatically while typing
      autocomplete = false,
      -- Without "noselect" the first item is preselected when the menu opens
      completeopt = "menu,menuone,noinsert",
    },

    snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    },

    mapping = build_mappings(),
    sources = cmp.config.sources(base_sources()),
    window = ui_window(),
    formatting = ui_formatting(),

    experimental = { ghost_text = false },

    -- Fully fuzzy matching, so that "thm" can match "\theorem"
    matching = {
      disallow_fuzzy_matching = false,
      disallow_fullfuzzy_matching = false,
      disallow_partial_fuzzy_matching = false,
      disallow_partial_matching = false,
      disallow_prefix_unmatching = false,
    },
  })

  setup_filetype_sources()
end

return {
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = setup_luasnip,
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "lukas-reineke/cmp-rg",
      "saadparwaiz1/cmp_luasnip",
      "micangl/cmp-vimtex",
      "kdheepak/cmp-latex-symbols",
      "L3MON4D3/LuaSnip",
    },
    config = setup_cmp,
  },
}
