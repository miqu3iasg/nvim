-- lua/plugins/obsidian.lua
--
-- The maintained fork today is `obsidian-nvim/obsidian.nvim` (the
-- original `epwalsh/obsidian.nvim` is stalled). This is the fork this
-- spec installs.
--
-- REPLACE the path below with the actual path to your vault. It's the
-- vault root (the folder that contains the ".obsidian" subfolder), not
-- a specific note.
local VAULT_PATH = "~/personal/documents/vault" -- <- edit this

-- Why the keymaps below don't live in ftplugin/markdown.lua.
--
-- ftplugin/markdown.lua runs in ANY .md buffer (inside or outside a
-- vault) and only covers text formatting. The commands in this file
-- (backlinks, create note, templates, tags...) only make sense inside a
-- note recognized as part of an Obsidian vault, so they're scoped to
-- the `User ObsidianNoteEnter` event, which only fires in that case.
--
-- Since both files use `buffer = true`/`buffer = 0` on the SAME buffer
-- when the file is a vault note, the leader keys here were chosen
-- carefully to NOT reuse anything already claimed in
-- ftplugin/markdown.lua (the entire h/l/m groups, and within i: il
-- [visual], ih, ik, im, it, ic). One exception is intentional and
-- commented where it appears: <leader>lt (checkbox), because in that
-- case I DO want the Obsidian version to replace the generic one when
-- the buffer is a vault note.

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- use the latest release; remove to track the main branch's latest commit
  ft = "markdown",
  -- If you'd rather load the plugin only inside the vault (instead of
  -- ANY .md file on the system), swap `ft = "markdown"` above for:
  -- event = { "BufReadPre " .. vim.fn.expand(VAULT_PATH) .. "/**.md",
  --           "BufNewFile " .. vim.fn.expand(VAULT_PATH) .. "/**.md" },
  dependencies = {
    "nvim-lua/plenary.nvim", -- required
    -- picker: you already have telescope.nvim in your config (lua/plugins/telescope.lua)
    "nvim-telescope/telescope.nvim",
  },
  -- Global entry points, available from ANY buffer/filetype, not just
  -- inside a recognized vault note. Everything else in this file lives
  -- inside the ObsidianNoteEnter autocmd below, which only fires once
  -- you're already looking at a note -- these two are what get you
  -- there in the first place. Pressing either one lazy-loads the
  -- plugin if it isn't loaded yet (same mechanism as `ft = "markdown"`
  -- above, just triggered by a keypress instead of a filetype).
  -- These reuse the exact same keys as their buffer-local counterparts
  -- further down (<leader>fs, <leader>nn, <leader>nd, <leader>nt), so
  -- each bind does the same thing whether you're already inside a note
  -- or not -- once you ARE inside a note, the buffer-local mapping just
  -- takes over silently.
  keys = {
    { "<leader>fs", "<cmd>Obsidian quick_switch<cr>",      desc = "Obsidian: jump to a note (open vault)" },
    { "<leader>nn", "<cmd>Obsidian new<cr>",               desc = "Obsidian: quick capture (new note in _Inbox)" },
    { "<leader>nd", "<cmd>Obsidian today<cr>",             desc = "Obsidian: daily note (today)" },
    { "<leader>nt", "<cmd>Obsidian new_from_template<cr>", desc = "Obsidian: new note from template" },
  },
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    -- flag required by the fork during the migration; false = use the
    -- new command interface (`:Obsidian <subcommand>`). Will be removed
    -- in 4.0.0. Every `:Obsidian ...` used below depends on this.
    legacy_commands = false,

    workspaces = {
      {
        name = "Brain",
        path = VAULT_PATH,
      },
      -- You can have more than one vault; just add another entry here:
      -- { name = "work", path = "~/Documents/WorkVault" },
    },

    -- Links created by :Obsidian link, extract_note etc. come out as
    -- wikilinks ([[note]]), same as the default in the Obsidian app.
    link = {
      style = "wiki", -- "wiki" | "markdown"
      format = "shortest",
    },

    -- Where `:Obsidian new` creates the note, if you don't specify a path.
    -- "notes_subdir" + notes_subdir below routes every new note into
    -- _Inbox, regardless of which folder the current buffer is in.
    new_notes_location = "notes_subdir", -- "current_dir" | "notes_subdir"
    notes_subdir = "_Inbox",

    -- date_format/time_format use moment.js-style tokens (YYYY, MM, DD,
    -- HH, mm), not strftime -- that's what the plugin expects.
    --
    -- `folder` is relative to the vault root. Your daily notes don't
    -- live at the vault root, so this has to be the full relative path,
    -- not just the last segment. If a new year rolls in and you want
    -- notes to land in Journal/daily/2027 instead, this is the one
    -- string that needs to change.
    daily_notes = {
      folder = "Journal/daily/2026",
      date_format = "DD-MM-YYYY",
      default_tags = { "daily-notes" },
      workdays_only = true,
    },

    templates = {
      folder = "Templates",
      date_format = "YYYY-MM-DD", -- format used by {{date}} in templates; unchanged, you didn't ask for this one
      time_format = "HH:mm",
    },

    -- Picker used by :Obsidian search, quick_switch, backlinks, etc.
    picker = {
      name = "telescope.nvim",
    },

    -- Completion for links/tags/footnotes is handled by an in-process
    -- LSP server the plugin registers itself (triggered by typing `[[`,
    -- `#`, `[^`) -- it no longer relies on configuring nvim-cmp/blink.cmp
    -- as a separate source. `min_chars` is how many characters to type
    -- before the suggestion menu shows up.
    completion = {
      min_chars = 2,
      match_case = true,
      create_new = true, -- allows creating a new note straight from the completion menu
    },

    attachments = {
      folder = "Resources",
    },
    -- Gera o nome do arquivo a partir do título digitado (slug), em vez de um código aleatório
    note_id_func = function(title)
      if title ~= nil and title ~= "" then
        return title:gsub(" ", "-"):gsub("[^%w-]", ""):lower()
      end
      return tostring(os.time())
    end,

    -- Garante que o título digitado apareça no frontmatter (e como alias)
    frontmatter = {
      func = function(note)
        if note.title then
          note:add_alias(note.title)
        end
        local out = { id = note.id, title = note.title, aliases = note.aliases, tags = note.tags }
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          out = vim.tbl_deep_extend("force", out, note.metadata)
        end
        return out
      end,
    },
    -- toggle check-boxes
    -- mappings = {
    --   ["<leader>ti"] = {
    --     action = function()
    --       return require("obsidian").util.toggle_checkbox()
    --     end,
    --     opts = { buffer = true },
    --   },
    -- },
  },

  -- Mappings registered only inside buffers the plugin recognizes as a
  -- vault note (ObsidianNoteEnter event), so they don't collide with
  -- the rest of your markdown.lua in .md files outside the vault.
  config = function(_, opts)
    require("obsidian").setup(opts)

    -- (Optional) real completion as you type `:Obsidian <Tab>`.
    -- Recommended by the plugin's own wiki; doesn't play well with
    -- blink.cmp/nvim-cmp on the cmdline, so skip this block if you use
    -- one of those on `:`.
    vim.api.nvim_create_autocmd("CmdlineChanged", {
      callback = function()
        if vim.fn.getcmdtype() ~= ":" then
          return
        end
        local cmdline = vim.fn.getcmdline()
        if not cmdline:match("^Obsidian[A-Za-z0-9]*$") then
          return
        end
        vim.fn.wildtrigger()
      end,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "ObsidianNoteEnter",
      callback = function()
        local actions = require("obsidian.actions")

        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = true, silent = true, desc = desc })
        end

        -- Which-key: group labels, scoped to the buffer (same pattern
        -- used in ftplugin/markdown.lua).
        do
          local ok, wk = pcall(require, "which-key")
          if ok then
            wk.add({
              { "<leader>n", group = "Notes",             buffer = 0 },
              { "<leader>o", group = "Panels (Obsidian)", buffer = 0 },
              { "<leader>p", group = "Properties/Tags",   buffer = 0 },
              { "<leader>f", group = "Find (Obsidian)",   buffer = 0 },
            })
          end
        end

        -- Basic link navigation / smart action / checkbox. (The
        -- default smart_action already lives on <CR>, ]o, [o -- left
        -- untouched here; we only add Tab/S-Tab for link navigation
        -- and the property key, same as what you already had.)
        map("n", "<leader>pa", actions.add_property, "Add frontmatter property")

        map("n", "]n", function() actions.nav_link("next") end, "Obsidian: next link")
        map("n", "[n", function() actions.nav_link("prev") end, "Obsidian: previous link")

        -- Intentionally overrides ftplugin/markdown.lua's generic
        -- checkbox toggle (<leader>lt) only inside vault notes, with
        -- Obsidian's "smart" version, which cycles through the states
        -- configured in Obsidian.ui.checkboxes (e.g. todo -> doing ->
        -- done) instead of just flipping [ ]/[x]. In any other .md
        -- file outside the vault, <leader>lt keeps using the generic
        -- version as normal.
        map({ "n", "v" }, "<leader>lt", actions.toggle_checkbox, "Obsidian: cycle checkbox state")

        -- Notes (<leader>n): create, templates, daily notes, move/merge
        map("n", "<leader>nn", "<cmd>Obsidian new<cr>", "New note")
        map("n", "<leader>nu", actions.unique_note, "New unique note (timestamp)")
        map("n", "<leader>nt", "<cmd>Obsidian new_from_template<cr>", "New note from template")
        map("n", "<leader>nd", "<cmd>Obsidian today<cr>", "Daily note: today")
        map("n", "<leader>nD", "<cmd>Obsidian yesterday<cr>", "Daily note: yesterday")
        map("n", "<leader>nT", "<cmd>Obsidian tomorrow<cr>", "Daily note: tomorrow")
        map("n", "<leader>nl", "<cmd>Obsidian dailies<cr>", "List daily notes")
        map("n", "<leader>nm", actions.move_note, "Move note to another folder")
        map("n", "<leader>nM", actions.merge_note, "Merge note into another")
        -- `actions.rename` was removed upstream: the plugin's own
        -- changelog says rename was "reimplemented with vim.lsp", so
        -- what used to be a standalone action is now just the native
        -- LSP rename. grn already does this by default; this is only
        -- here so it's also reachable at <leader>rn.
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename note (updates backlinks)")

        -- Panels (<leader>o): backlinks, links, TOC, footnotes, open in app
        map("n", "<leader>ob", "<cmd>Obsidian backlinks<cr>", "Backlinks (references to this note)")
        -- Also always available via LSP: grr (vim.lsp.buf.references)
        map("n", "<leader>ol", "<cmd>Obsidian links<cr>", "Outgoing links from this note")
        map("n", "<leader>ot", "<cmd>Obsidian toc<cr>", "Table of contents")
        map("n", "<leader>of", "<cmd>Obsidian footnotes<cr>", "Footnotes in this note")
        map("n", "<leader>oo", "<cmd>Obsidian open<cr>", "Open this note in the Obsidian app")
        map("n", "<leader>ov", "<cmd>Obsidian workspace<cr>", "Switch vault/workspace")

        -- Properties / Tags (<leader>p)
        map("n", "<leader>pt", actions.insert_tag, "Insert existing tag")
        map("n", "<leader>pT", actions.add_tag, "Add tag to this note")
        map("n", "<leader>ps", actions.search_tags, "Search notes by tag")

        -- Find (<leader>f): quick switch, vault search, symbols
        map("n", "<leader>fs", "<cmd>Obsidian quick_switch<cr>", "Quick switcher")
        map("n", "<leader>fo", "<cmd>Obsidian search<cr>", "Search text in vault")
        map("n", "<leader>ff", actions.workspace_symbol, "Search notes, aliases and headings")

        -- Insert link / image / template, using slots in the "i" group
        -- that ftplugin/markdown.lua leaves free: il[normal], ii, iT.
        -- iw/iW/ie are also free and used below in visual mode.
        map("n", "<leader>il", actions.insert_link, "Insert link to a note (picker)")
        map("n", "<leader>ii", "<cmd>Obsidian paste_img<cr>", "Paste image from clipboard")
        map("n", "<leader>iT", actions.insert_template, "Insert template at cursor")

        -- Visual selection actions: link to an existing note, create a
        -- new note and link the selection, or extract the selection
        -- into a new note. Free keys in ftplugin/markdown.lua (iw/iW/ie
        -- only exist there, commented, in the real Obsidian config,
        -- never in Neovim).
        map("v", "<leader>iw", actions.link, "Link selection to an existing note")
        map("v", "<leader>iW", actions.link_new, "Create a new note and link the selection")
        map("v", "<leader>ie", actions.extract_note, "Extract selection to a new note")
      end,
    })
  end,
}

--[[
Mappings the plugin already registers by default (no config needed),
documented in the official wiki:

  <CR>   (normal)  smart_action -- follows a link / toggles a checkbox /
                    opens a picker for the tag under cursor / folds the
                    heading under cursor, depending on where the cursor is
  ]o     (normal)  go to the next link in the buffer
  [o     (normal)  go to the previous link in the buffer

And, via Neovim's native LSP (the plugin registers an "in-process" LSP
server for this), so they use whatever default LSP mappings your config
already has (grr/grn/gra, or your own from lspconfig.lua):

  grn / vim.lsp.buf.rename()      -> equivalent to <leader>rn / :Obsidian rename
  grr / vim.lsp.buf.references()  -> equivalent to <leader>ob / :Obsidian backlinks
  gra / vim.lsp.buf.code_action() -> note actions (extract_note, link, etc.)

Handy day-to-day commands (use `:Obsidian <Tab>` to see all of them):
`:Obsidian new`, `:Obsidian today`, `:Obsidian search`,
`:Obsidian quick_switch`, `:Obsidian template`, `:Obsidian paste_img`.

Subcommand/action names confirmed against the official fork wiki on
2026-08-15: github.com/obsidian-nvim/obsidian.nvim/wiki/Actions and
github.com/obsidian-nvim/obsidian.nvim/wiki/Keymaps. Since it's an
active project, run `:Obsidian <Tab>` once in a while to check nothing
was renamed before the next major release (4.0.0).
--]]
