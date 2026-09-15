-- lua/plugins/obsidian.lua

-- REPLACE the path below with the actual path to your vault. It's the
-- vault root (the folder that contains the ".obsidian" subfolder), not
-- a specific note.
local VAULT_PATH = "~/personal/documents/vault" -- <- edit this

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- use the latest release; remove to track the main branch's latest commit
  event = { "BufReadPre " .. vim.fn.expand(VAULT_PATH) .. "/**.md" },
  dependencies = {
    "nvim-lua/plenary.nvim", -- required
    -- picker in fzf-lua in my config (lua/plugins/fzf.lua)
    "ibhagwan/fzf-lua",
  },

  -- Global entry points, available from ANY buffer/filetype, not just
  -- inside a recognized vault note.
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

    ui = { enable = false },

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
      name = "fzf-lua",
    },

    -- Completion for links/tags/footnotes
    completion = {
      min_chars = 2,
      match_case = true,
      create_new = true, -- allows creating a new note straight from the completion menu
    },

    attachments = {
      folder = "Resources",
    },

    -- Generates the file name from the entered title (slug) instead of a random code
    note_id_func = function(title)
      if title ~= nil and title ~= "" then
        return title:gsub(" ", "-"):gsub("[^%w-]", ""):lower()
      end
      return tostring(os.time())
    end,
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

        -- Basic link navigation / smart action / checkbox.
        map("n", "<leader>pa", actions.add_property, "Add frontmatter property")

        map("n", "]n", function() actions.nav_link("next") end, "Obsidian: next link")
        map("n", "[n", function() actions.nav_link("prev") end, "Obsidian: previous link")

        map({ "n", "v" }, "<leader>lt", actions.toggle_checkbox, "Obsidian: cycle checkbox state")

        -- Notes: create, templates, daily notes, move/merge
        map("n", "<leader>nn", "<cmd>Obsidian new<cr>", "New note")
        map("n", "<leader>nu", actions.unique_note, "New unique note (timestamp)")
        map("n", "<leader>nt", "<cmd>Obsidian new_from_template<cr>", "New note from template")
        map("n", "<leader>nd", "<cmd>Obsidian today<cr>", "Daily note: today")
        map("n", "<leader>nD", "<cmd>Obsidian yesterday<cr>", "Daily note: yesterday")
        map("n", "<leader>nT", "<cmd>Obsidian tomorrow<cr>", "Daily note: tomorrow")
        map("n", "<leader>nl", "<cmd>Obsidian dailies<cr>", "List daily notes")
        map("n", "<leader>nm", actions.move_note, "Move note to another folder")
        map("n", "<leader>nM", actions.merge_note, "Merge note into another")
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename note (updates backlinks)")

        -- Panels: backlinks, links, TOC, footnotes, open in app
        map("n", "<leader>ob", "<cmd>Obsidian backlinks<cr>", "Backlinks (references to this note)")
        -- Also always available via LSP: grr (vim.lsp.buf.references)
        map("n", "<leader>ol", "<cmd>Obsidian links<cr>", "Outgoing links from this note")
        map("n", "<leader>ot", "<cmd>Obsidian toc<cr>", "Table of contents")
        map("n", "<leader>of", "<cmd>Obsidian footnotes<cr>", "Footnotes in this note")
        map("n", "<leader>oo", "<cmd>Obsidian open<cr>", "Open this note in the Obsidian app")
        map("n", "<leader>ov", "<cmd>Obsidian workspace<cr>", "Switch vault/workspace")

        -- Properties / Tags
        map("n", "<leader>pt", actions.insert_tag, "Insert existing tag")
        map("n", "<leader>pT", actions.add_tag, "Add tag to this note")
        map("n", "<leader>ps", actions.search_tags, "Search notes by tag")

        -- Find: quick switch, vault search, symbols
        map("n", "<leader>fs", "<cmd>Obsidian quick_switch<cr>", "Quick switcher")
        map("n", "<leader>fo", "<cmd>Obsidian search<cr>", "Search text in vault")
        map("n", "<leader>ff", actions.workspace_symbol, "Search notes, aliases and headings")

        -- Insert link / image / template
        map("n", "<leader>il", actions.insert_link, "Insert link to a note (picker)")
        map("n", "<leader>ii", "<cmd>Obsidian paste_img<cr>", "Paste image from clipboard")
        map("n", "<leader>iT", actions.insert_template, "Insert template at cursor")

        -- Visual selection actions
        map("v", "<leader>iw", actions.link, "Link selection to an existing note")
        map("v", "<leader>iW", actions.link_new, "Create a new note and link the selection")
        map("v", "<leader>ie", actions.extract_note, "Extract selection to a new note")
      end,
    })
  end,
}
