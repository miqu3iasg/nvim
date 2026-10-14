-- lua/plugins/obsidian.lua

local VAULT_PATH = "~/personal/documents/vault"

local DEFAULT_TEMPLATE = "note_template"
local INBOX_TEMPLATE = "inbox_template"

local function new_inbox_capture()
  local title = "CAP-" .. os.date("%Y%m%d-%H%M%S")
  vim.cmd("Obsidian new " .. title)
  vim.schedule(function()
    vim.cmd("Obsidian template " .. INBOX_TEMPLATE)
  end)
end

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  enabled = true,
  event = { "BufReadPre " .. vim.fn.expand(VAULT_PATH) .. "/**.md" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "ibhagwan/fzf-lua",
  },

  -- Global entry points, available from ANY buffer/filetype, not just
  -- inside a recognized vault note
  keys = {
    { "<leader>os", "<cmd>Obsidian quick_switch<cr>",      desc = "Obsidian: jump to a note" },
    { "<leader>oc", "<cmd>Obsidian new<cr>",               desc = "Obsidian: quick capture" },
    { "<leader>oi", new_inbox_capture,                     desc = "Obsidian: new inbox capture" },
    { "<leader>ot", "<cmd>Obsidian new_from_template<cr>", desc = "Obsidian: new note (pick template)" },
    { "<leader>od", "<cmd>Obsidian today<cr>",             desc = "Obsidian: daily note (today)" },
  },

  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    legacy_commands = false,

    ui = { enable = false },

    footer = { enabled = false },

    workspaces = {
      { name = "Brain", path = VAULT_PATH, },
    },

    frontmatter = { enabled = false },

    link = {
      style = "wiki",
      format = "shortest",
    },

    new_notes_location = "notes_subdir",
    notes_subdir = "_inbox",

    daily_notes = {
      folder = "journal/daily/2026",
      date_format = "DD-MM-YYYY",
      workdays_only = true,
    },
    templates = {
      folder = "system/templates",
      date_format = "YYYY-MM-DD",
      time_format = "HH:mm",
      substitutions = {
        ["DATE:YYYYMMDDHHmm"] = function()
          return os.date("%Y%m%d%H%M")
        end,
        -- Same thing, covers the variant with a space after the colon
        ["DATE: YYYYMMDDHHmm"] = function()
          return os.date("%Y%m%d%H%M")
        end,
      },
    },

    picker = { name = "fzf-lua", },

    completion = {
      min_chars = 2,
      match_case = true,
      create_new = true,
    },

    attachments = { folder = "attachments", },

    -- Generates the file name from the entered title (slug) instead of a random code
    note_id_func = function(title)
      if title ~= nil and title ~= "" then
        if title:match("^CAP%-%d+%-%d+$") then
          return title
        end
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

        map({ "n", "v" }, "<leader>lt", actions.toggle_checkbox, "Cycle checkbox state")
        map("n", "<leader>ia", "<cmd>Obsidian paste_img<cr>", "Paste image from clipboard")

        map(
          "n",
          "<leader>on",
          "<cmd>Obsidian template " .. DEFAULT_TEMPLATE .. "<cr>",
          "Insert default template into this note"
        )

        map("n", "<leader>oo", "<cmd>Obsidian open<cr>", "Open this note in the Obsidian app")
        map("n", "<leader>om", actions.move_note, "Move note to another folder")
        map("n", "<leader>or", vim.lsp.buf.rename, "Rename note")
        map("n", "<leader>of", actions.workspace_symbol, "Search notes, aliases and headings")
        map("n", "<leader>og", "<cmd>Obsidian search<cr>", "Search text in vault (grep)")
      end,
    })
  end,
}
