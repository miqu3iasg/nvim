-- lua/plugins/git.lua

-- Histogram diffs read better than Myers on refactored code, and linematch
-- aligns changed lines within a hunk
vim.opt.diffopt:append({ "algorithm:histogram", "indent-heuristic", "linematch:60" })

-- The default blame width is too narrow for author, timestamp and summary
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitiveblame",
  callback = function()
    vim.cmd("vertical resize 45")
  end,
})

-- Registers the Fugitive close-view keymaps and autocmds
-- See: lua/utils/close.lua
require("utils.close").setup()

return {
  {
    "tpope/vim-fugitive",
    -- Provides GitHub URL resolution for `GBrowse`. GitHub Enterprise also
    -- needs `vim.g.github_enterprise_urls`
    dependencies = { "tpope/vim-rhubarb" },

    cmd = { "Git", "G", "GBrowse", "Gvdiffsplit", "Gdiffsplit", "Gwrite", "Gread", "Gclog", "Gedit", "GMove" },

    keys = {
      -- Repository
      { "<leader>gs", "<cmd>silent leftabove vertical Git<cr>",           desc = "Git status" },
      { "<leader>gl", "<cmd>silent vertical Git log<cr>",                 desc = "Git log" },
      { "<leader>gp", "<cmd>Git push<cr>",                                desc = "Git push" },

      -- Staging
      { "<leader>g.", "<cmd>silent Git add -A<cr>",                       desc = "Git add -A (stage all)" },
      { "<leader>ga", "<cmd>silent Gwrite<cr>",                           desc = "Stage current file" },

      -- Commits
      { "<leader>gC", "<cmd>silent tab Git commit -v<cr>",                desc = "Git commit -v (new tab)" },
      { "<leader>gc", "<cmd>silent leftabove vertical Git commit -v<cr>", desc = "Git commit -v (new tab)" },

      -- Diff
      { "<leader>gd", "<cmd>silent Gvdiffsplit<cr>",                      desc = "Diff against index" },
      { "<leader>gh", "<cmd>silent Gvdiffsplit HEAD<cr>",                 desc = "Diff against HEAD" },

      -- Inspection
      { "<leader>gb", "<cmd>silent Git blame<cr>",                        desc = "Git blame" },
      { "<leader>ge", "<cmd>.Git blame<cr>",                              desc = "Git blame (line)" },

      -- Browser
      { "<leader>go", "<cmd>silent .GBrowse<cr>",                         desc = "Open in browser" },
      { "<leader>gy", "<cmd>silent .GBrowse!<cr>",                        desc = "Copy browser link" },
      {
        "<leader>go",
        ":<C-u>silent '<,'>GBrowse<cr>",
        mode = "x",
        desc = "Open selection in browser",
      },
      {
        "<leader>gy",
        ":<C-u>silent '<,'>GBrowse!<cr>",
        mode = "x",
        desc = "Copy selection link",
      },
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
      -- Stage and reset
      {
        "<leader>hs",
        function() require("gitsigns").stage_hunk() end,
        desc = "Stage/unstage hunk",
      },
      {
        "<leader>hs",
        function() require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
        mode = "x",
        desc = "Stage/unstage selection",
      },
      {
        "<leader>hr",
        function() require("gitsigns").reset_hunk() end,
        desc = "Reset hunk",
      },
      {
        "<leader>hr",
        function() require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
        mode = "x",
        desc = "Reset selection",
      },

      -- Preview
      {
        "<leader>hp",
        function() require("gitsigns").preview_hunk_inline() end,
        desc = "Preview hunk",
      },
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

      -- Navigation (silent when there are no hunks)
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
    },
  },
}
