-- lua/plugins/git.lua

-- The default blame width is too narrow for author, timestamp and summary
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitiveblame",
  callback = function()
    vim.cmd("vertical resize 45")
  end,
})

-- See: lua/utils/close.lua
-- Registers the Fugitive close-view keymaps and autocmds
require("utils.close").setup()

return {

  -- Testign Neogit for now
  {
    "NeogitOrg/neogit",
    dependencies = { "nvim-lua/plenary.nvim", "ibhagwan/fzf-lua" },
    cmd = "Neogit",
    keys = { { "<leader>gn", "<cmd>Neogit<cr>", desc = "Git status" } },
    opts = {
      disable_hint = true,
      disable_signs = true,
      disable_context_highlighting = true,
      process_spinner = false,
      graph_style = "ascii",
      integrations = { fzf_lua = true },
      status = {
        show_head_commit_hash = false,
      },
      sections = {
        recent  = { folded = true },
        stashes = { folded = true },
      },
    },
  },

  {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-rhubarb" },

    cmd = { "Git", "G", "GBrowse", "Gvdiffsplit", "Gdiffsplit", "Gwrite", "Gread", "Gclog", "Gedit", "GMove" },

    keys = {
      { "<leader>gs", "<cmd>silent tab Git<cr>",                          desc = "Git status" },
      { "<leader>ga", "<cmd>silent Gwrite<cr>",                           desc = "Stage current file" },

      { "<leader>gC", "<cmd>silent tab Git commit -v<cr>",                desc = "Git commit -v (new tab)" },
      { "<leader>gc", "<cmd>silent leftabove vertical Git commit -v<cr>", desc = "Git commit -v (new tab)" },

      { "<leader>gd", "<cmd>silent Gvdiffsplit<cr>",                      desc = "Diff against index" },
      { "<leader>gh", "<cmd>silent Gvdiffsplit HEAD<cr>",                 desc = "Diff against HEAD" },
      { "<leader>gb", "<cmd>silent Git blame<cr>",                        desc = "Git blame" },
      { "<leader>ge", "<cmd>.Git blame<cr>",                              desc = "Git blame (line)" },

      { "<leader>go", "<cmd>silent .GBrowse<cr>",                         desc = "Open in browser" },
      { "<leader>gy", "<cmd>silent .GBrowse!<cr>",                        desc = "Copy browser link" },
      { "<leader>go", ":<C-u>silent '<,'>GBrowse<cr>",                    mode = "x",                      desc = "Open selection in browser" },
      { "<leader>gy", ":<C-u>silent '<,'>GBrowse!<cr>",                   mode = "x",                      desc = "Copy selection link" },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signcolumn = false,
      numhl = false,
      word_diff = false,
      current_line_blame = false,
    },
    keys = {
      { "<leader>hs", function() require("gitsigns").stage_hunk() end,          desc = "Stage/unstage hunk" },
      {
        "<leader>hs",
        function() require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
        mode = "x",
        desc = "Stage/unstage selection",
      },
      { "<leader>hr", function() require("gitsigns").reset_hunk() end,          desc = "Reset hunk" },
      { "<leader>hp", function() require("gitsigns").preview_hunk_inline() end, desc = "Preview hunk" },
      {
        "<leader>hd",
        (function()
          local on = false
          return function()
            on = not on
            local gs = require("gitsigns")
            gs.toggle_deleted(on)
            gs.toggle_linehl(on)
          end
        end)(),
        desc = "Toggle diff overlay",
      },

      { "]f", function() require("gitsigns").nav_hunk("next", { navigation_message = false }) end,  desc = "Next hunk" },
      { "[f", function() require("gitsigns").nav_hunk("prev", { navigation_message = false }) end,  desc = "Prev hunk" },
      { "]F", function() require("gitsigns").nav_hunk("last", { navigation_message = false }) end,  desc = "Last hunk" },
      { "[F", function() require("gitsigns").nav_hunk("first", { navigation_message = false }) end, desc = "First hunk" },
    },
  },

  -- Merged into the existing fzf-lua setup; ignored if fzf-lua is absent
  {
    "ibhagwan/fzf-lua",
    optional = true,
    keys = {
      { "<leader>gw", "<cmd>FzfLua git_branches<cr>", desc = "Git branches (checkout)" },
      { "<leader>gi", "<cmd>FzfLua git_commits<cr>",  desc = "Git commits" },
      {
        "<leader>gf",
        function()
          require("fzf-lua").git_files({ cmd = "git ls-files --cached --others --exclude-standard" })
        end,
        desc = "Git files",
      },
    },
  },
}
