return {
  "stevearc/oil.nvim",
  -- enabled = false,
  dependencies = {
    "refractalize/oil-git-status.nvim",
  },
  config = function()
    local oil = require("oil")
    local detail = false
    oil.setup({
      default_file_explorer = true,
      columns = {
        "permissions",
        "size",
        { "mtime", format = "%d/%m %H:%M" },
      },
      keymaps = {
        ["<C-h>"] = "actions.parent",
        ["<C-l>"] = "actions.select",
        ["<BS>"] = "actions.parent",
        ["<C-c>"] = false,
        ["<C-r>"] = "actions.refresh",
        ["sh"] = "actions.select_split",
        ["sv"] = "actions.select_vsplit",
        ["<C-p>"] = {
          "actions.preview",
          opts = {
            vertical = true,
            split = "botright",
          },
        },
        ["q"] = "actions.close",
        ["gd"] = {
          desc = "Toggle file detail view",
          callback = function()
            detail = not detail
            if detail then
              oil.set_columns({
                "permissions",
                "size",
                { "mtime", format = "%d/%m %H:%M" },
              })
            else
              oil.set_columns({})
            end
          end,
        },
      },
      delete_to_trash = true,
      view_options = {
        show_hidden = true,
      },
      skip_confirm_for_simple_edits = true,
      preview_win = {
        border = "rounded",
      },
      win_options = {
        signcolumn = "yes:2",
        number = false,
        relativenumber = false,
      },
    })
    require("oil-git-status").setup()

    -- Open parent directory
    vim.keymap.set("n", "go", "<CMD>Oil<CR>", {
      desc = "Open parent directory",
    })

    -- Toggle Oil floating window
    vim.keymap.set("n", "<leader>-", oil.toggle_float)

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
        vim.opt_local.cursorline = true
      end,
    })
  end,
}
