-- lua/plugins/oil.lua

return {
  -- "stevearc/oil.nvim",
  "barrettruth/canola.nvim",
  -- enabled = false,
  -- dependencies = {
  --   "refractalize/oil-git-status.nvim",
  -- },
  config = function()
    local oil = require("oil")
    oil.setup({
      default_file_explorer = true,
      columns = {
        -- "type",
        "permissions",
        "user",
        "group",
        "size",
        { "mtime",     format = "%d/%m %H:%M" },
        { "ctime",     format = "%d/%m %H:%M" },
        { "birthtime", format = "%d/%m %H:%M" },
      },
      keymaps = {
        ["<C-c>"] = false,                -- disable default action
        ["<C-h>"] = false,                -- disable default action
        ["<C-l>"] = false,                -- disable default action
        ["h"] = "actions.parent",         -- go up to parent directory
        ["l"] = "actions.select",         -- open file or enter directory
        ["<BS>"] = "actions.parent",      -- go up to parent directory (alt key)
        ["r"] = "actions.refresh",        -- refresh directory listing
        ["sh"] = "actions.select_split",  -- open in horizontal split
        ["sv"] = "actions.select_vsplit", -- open in vertical split
        ["gp"] = {
          "actions.preview",              -- preview file contents
          opts = {
            vertical = true,
            split = "botright",
          },
        },
        ["gs"] = "actions.change_sort", -- cycle sort order
        ["gx"] = {
          -- open with a specific app based on extension, or fall back to OS default
          callback = function()
            local entry = oil.get_cursor_entry()
            local dir = oil.get_current_dir()
            if not entry or not dir then
              return
            end

            local path = dir .. entry.name
            local ext = entry.name:match("^.+%.(.+)$")
            ext = ext and ext:lower() or nil

            local app_map = {
              pdf  = { "zathura" },
              djvu = { "zathura" },
              epub = { "zathura" },
              cbz  = { "zathura" },
              cbr  = { "zathura" },
              xps  = { "zathura" },

              png  = { "imv" },
              jpg  = { "imv" },
              jpeg = { "imv" },
              gif  = { "imv" },
              webp = { "imv" },
              bmp  = { "imv" },
              svg  = { "imv" },

              mp4  = { "mpv" },
              mkv  = { "mpv" },
              webm = { "mpv" },
              mov  = { "mpv" },
              avi  = { "mpv" },
              mp3  = { "mpv" },
              flac = { "mpv" },
              wav  = { "mpv" },
            }

            local cmd = ext and app_map[ext]
            if cmd then
              local full_cmd = vim.list_extend(vim.deepcopy(cmd), { path })
              vim.fn.jobstart(full_cmd, { detach = true })
            else
              require("oil.actions").open_external.callback()
            end
          end,
        },
        ["gy"] = "actions.copy_entry_path", -- copy entry path to clipboard
        ["gh"] = "actions.toggle_hidden",   -- toggle hidden files visibility
        ["q"] = "actions.close",            -- close oil buffer
      },
      delete_to_trash = true,
      view_options = {
        show_hidden = true,
      },
      skip_confirm_for_simple_edits = true,
      preview_win = {
        border = "single",
      },
      win_options = {
        -- signcolumn = "yes:2",
        signcolumn = "no",
        number = false,
        relativenumber = false,
      },
    })
    -- require("oil-git-status").setup()

    -- Open parent directory
    vim.keymap.set("n", "go", "<CMD>Oil<CR>", {
      desc = "Open parent directory",
    })

    -- go straight to $HOME
    vim.keymap.set("n", "g~", function()
      require("oil").open(vim.fn.expand("~"))
    end, { desc = "Open home directory" })

    -- go straight to project cwd
    vim.keymap.set("n", "g.", function()
      require("oil").open(vim.fn.getcwd())
    end, { desc = "Open cwd" })

    -- go straight to repos directory
    vim.keymap.set("n", "g,", function()
      require("oil").open(vim.fn.expand("~/repos"))
    end, { desc = "Open repos directory" })
  end,
}
