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
        ["gs"] = "actions.change_sort",     -- cycle sort order
        ["gx"] = "actions.open_external",   -- open with OS default program
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

    -- Reveal current file in Oil
    vim.keymap.set("n", "ge", function()
      local file = vim.api.nvim_buf_get_name(0)
      if file == "" then
        return
      end
      local dir = vim.fs.dirname(file)
      local name = vim.fs.basename(file)
      oil.open(dir, {}, function()
        for lnum = 1, vim.api.nvim_buf_line_count(0) do
          local entry = oil.get_entry_on_line(0, lnum)
          if entry and entry.name == name then
            vim.api.nvim_win_set_cursor(0, { lnum, 0 })
            return
          end
        end
      end)
    end, {
      desc = "Reveal current file in Oil",
    })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "oil",
      callback = function()
        vim.opt_local.cursorline = false
      end,
    })
  end,
}
