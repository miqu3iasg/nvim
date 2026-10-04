-- lua/plugins/obsidian.lua

local VAULT_PATH = "~/personal/documents/vault"

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  event = { "BufReadPre " .. vim.fn.expand(VAULT_PATH) .. "/**.md" },
  dependencies = {
    "nvim-lua/plenary.nvim",
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
    legacy_commands = false,

    ui = { enable = false },

    workspaces = {
      { name = "Brain", path = VAULT_PATH, },
    },

    frontmatter = { enabled = false },

    link = {
      style = "wiki",
      format = "shortest",
    },

    new_notes_location = "notes_subdir",
    notes_subdir = "_Inbox",

    daily_notes = {
      folder = "Journal/daily/2026",
      date_format = "DD-MM-YYYY",
      workdays_only = true,
    },

    templates = {
      folder = "Templates",
      date_format = "YYYY-MM-DD",
      time_format = "HH:mm",
    },

    picker = { name = "fzf-lua", },

    completion = {
      min_chars = 2,
      match_case = true,
      create_new = true,
    },

    attachments = { folder = "Resources", },

    -- Generates the file name from the entered title (slug) instead of a random code
    note_id_func = function(title)
      if title ~= nil and title ~= "" then
        return title:gsub(" ", "-"):gsub("[^%w-]", ""):lower()
      end
      return tostring(os.time())
    end,
  },

  -- Mappings registered only inside buffers the plugin recognizes as a vault note
  config = function(_, opts)
    require("obsidian").setup(opts)

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

        map("n", "<leader>pa", actions.add_property, "Add frontmatter property")

        map("n", "]n", function() actions.nav_link("next") end, "Obsidian: next link")
        map("n", "[n", function() actions.nav_link("prev") end, "Obsidian: previous link")

        map({ "n", "v" }, "<leader>lt", actions.toggle_checkbox, "Obsidian: cycle checkbox state")

        map("n", "<leader>nf", "<cmd>Obsidian new<cr>", "New note")
        map("n", "<leader>nc", actions.unique_note, "New unique note (timestamp)")
        map("n", "<leader>nt", "<cmd>Obsidian new_from_template<cr>", "New note from template")
        map("n", "<leader>nd", "<cmd>Obsidian today<cr>", "Daily note: today")
        map("n", "<leader>dl", "<cmd>Obsidian dailies<cr>", "List daily notes")
        map("n", "<leader>fm", actions.move_note, "Move note to another folder")
        map("n", "<leader>rf", vim.lsp.buf.rename, "Rename note (updates backlinks)")

        map("n", "<leader>oo", "<cmd>Obsidian open<cr>", "Open this note in the Obsidian app")

        map("n", "<leader>fs", "<cmd>Obsidian quick_switch<cr>", "Quick switcher")
        map("n", "<leader>fo", "<cmd>Obsidian search<cr>", "Search text in vault")
        map("n", "<leader>ff", actions.workspace_symbol, "Search notes, aliases and headings")

        map("n", "<leader>ia", "<cmd>Obsidian paste_img<cr>", "Paste image from clipboard")
      end,
    })
  end,
}
