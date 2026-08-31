-- telescope.nvim
return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          preview = {
            treesitter = false,
          },
          border = {
            prompt = { 1, 1, 1, 1 },
            results = { 1, 1, 1, 1 },
            preview = { 1, 1, 1, 1 },
          },
          borderchars = {
            prompt = { " ", " ", "─", "│", "│", " ", "─", "└" },
            results = { "─", " ", " ", "│", "┌", "─", " ", "│" },
            preview = { "─", "│", "─", "│", "┬", "┐", "┘", "┴" },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,                   -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true,    -- override the file sorter
            case_mode = "smart_case",
          },
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({
              -- even more opts
            }),
          },
        },
        pickers = {
          colorscheme = {
            enable_preview = true,
          },
          find_files = {
            hidden = true,
            find_command = {
              "rg",
              "--files",
              "--glob",
              "!{.git/*,.next/*,.svelte-kit/*,target/*,node_modules/*}",
              "--path-separator",
              "/",
            },
          },
        },
      })

      -- load extensions (depois do setup, senão dá erro e interrompe o resto do config)
      pcall(require("telescope").load_extension, "fzf")
      require("telescope").load_extension("zoxide")
      require("telescope").load_extension("file_browser")
      require("telescope").load_extension("ui-select")

      -- telescope setup
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>fb", ":Telescope file_browser<cr>", {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fd", builtin.diagnostics, {})
      vim.keymap.set("n", "<leader>ds", builtin.lsp_document_symbols, {})
      vim.keymap.set("n", "<leader>ws", builtin.lsp_workspace_symbols, {})
      vim.keymap.set("n", "<leader>fz", ":Telescope zoxide list<CR>", {})
      vim.keymap.set("n", "<leader>fv", builtin.help_tags, {})
      vim.keymap.set("n", "<leader>fp", builtin.builtin, {})
      -- Habits (GotoFile, RecentFiles, GotoAction, RecentLocations, FindInPath-word, Switcher)
      vim.keymap.set("n", "<leader>fr", builtin.oldfiles, {})
      vim.keymap.set("n", "<leader>fa", builtin.commands, {})
      vim.keymap.set("n", "<leader>fl", builtin.jumplist, {})
      vim.keymap.set("n", "<leader>fw", builtin.grep_string, {})
      vim.keymap.set("n", "<leader>fu", builtin.buffers, {})
      vim.keymap.set(
        "n",
        "<leader>jk",
        "<cmd>lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files', '--hidden', '-g', '!.git' }})<cr>",
        {}
      )
      vim.keymap.set(
        "n",
        "<leader>ff",
        "<cmd>lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files', '--hidden', '-g', '!.git' }})<cr>",
        {}
      )
    end,
  },
  {
    "jvgrootveld/telescope-zoxide",
    config = function() end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
  },
}
