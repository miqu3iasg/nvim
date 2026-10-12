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
      { "<leader>gs", "<cmd>silent vertical Git<cr>",                 desc = "Git status" },
      { "<leader>gl", "<cmd>silent vertical Git log<cr>",             desc = "Git log" },
      { "<leader>gu", "<cmd>silent vertical Git pull --ff-only<cr>",  desc = "Git pull (fast-forward only)" },
      { "<leader>gp", "<cmd>Git push<cr>",                            desc = "Git push" },

      -- Staging
      { "<leader>g.", "<cmd>silent Git add -A<cr>",                   desc = "Git add -A (stage all)" },
      { "<leader>ga", "<cmd>silent Gwrite<cr>",                       desc = "Stage current file" },

      -- Commits
      { "<leader>gc", "<cmd>silent vertical Git commit -v<cr>",       desc = "Git commit -v" },
      { "<leader>gA", "<cmd>silent Git commit --amend --no-edit<cr>", desc = "Amend (no edit)" },

      -- History
      { "<leader>gh", "<cmd>0Gclog<cr>",                              desc = "File history" },
      {
        "<leader>gh",
        ":Gclog<cr>",
        mode = "x",
        desc = "Line history",
      },

      -- Diff
      { "<leader>gd", "<cmd>silent Gvdiffsplit<cr>",      desc = "Diff against index" },
      { "<leader>gD", "<cmd>silent Gvdiffsplit HEAD<cr>", desc = "Diff against HEAD" },

      -- Inspection
      { "<leader>gb", "<cmd>silent Git blame<cr>",        desc = "Git blame" },

      -- Browser
      -- Visual mappings use `:` so the selected range reaches `GBrowse`. The
      -- bang form copies the permalink instead of opening the browser
      { "<leader>go", "<cmd>silent .GBrowse<cr>",         desc = "Open in browser" },
      { "<leader>gy", "<cmd>silent .GBrowse!<cr>",        desc = "Copy browser link" },
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
    "nvim-mini/mini.diff",
    version = false,
    event = { "BufReadPre", "BufNewFile" },

    keys = {
      {
        "<leader>hd",
        function()
          local md = require("mini.diff")
          local buf = vim.api.nvim_get_current_buf()

          if vim.bo[buf].buftype ~= "" then
            return vim.notify("mini.diff: not a normal file buffer", vim.log.levels.WARN)
          end

          if not md.get_buf_data(buf) then
            pcall(md.enable, buf)
          end

          if not md.get_buf_data(buf) then
            return vim.notify(
              "mini.diff: could not attach (file untracked or outside a git repo?)",
              vim.log.levels.WARN
            )
          end

          md.toggle_overlay(buf)
        end,
        desc = "Toggle diff overlay",
      },
    },
    opts = {
      mappings = {
        apply = "<leader>hs",
        reset = "<leader>hr",
        textobject = "ih",
        -- TODO: when there are no hunks to navigate, simply do nothing and do not issue a notification short description
        goto_first = "[S",
        goto_prev = "[s",
        goto_next = "]s",
        goto_last = "]S",
      },
    },
  },

  -- Merged into the existing fzf-lua setup; ignored if fzf-lua is absent
  {
    "ibhagwan/fzf-lua",
    optional = true,
    keys = {
      { "<leader>gw", "<cmd>FzfLua git_branches<cr>", desc = "Git branches (checkout)" },
      { "<leader>gi", "<cmd>FzfLua git_commits<cr>",  desc = "Git commits" },
      { "<leader>gz", "<cmd>FzfLua git_stash<cr>",    desc = "Git stash" },
    },
  },
}
