-- lua/plugins/git.lua

-- Better alignment of similar lines inside diff hunks. `histogram` produces
-- more readable hunks than the default Myers algorithm on refactored code,
-- and `linematch` aligns changed lines within a hunk.
vim.opt.diffopt:append({ "algorithm:histogram", "indent-heuristic", "linematch:60" })

-- This handler toggles the diff view against the previous commit.
-- When invoked from a diff window, it closes the diff buffers through
-- Fugitive's `dq`, which keeps the working file open and runs `diffoff!`.
local function toggle_last_commit_diff()
  if vim.wo.diff then
    vim.cmd.normal("dq")
  else
    vim.cmd("Gvdiffsplit HEAD~1")
  end
end

-- Opens an interactive rebase in a dedicated tab. The number of commits
-- is provided interactively so the same mapping can be used for different
-- rebase ranges without maintaining separate mappings. For rebasing from a
-- specific commit, `ri` in the log view is usually faster.
local function interactive_rebase()
  local n = vim.fn.input("Rebase -i HEAD~", "3")
  if n ~= "" then
    vim.cmd("tab Git rebase -i HEAD~" .. n)
  end
end

-- Returns a handler that retrieves one side of a three-way conflict. The
-- guard avoids `diffget` errors when the current window is not part of a
-- conflict diff opened with `Gvdiffsplit!`.
local function diffget(n)
  return function()
    if not vim.wo.diff then
      return vim.notify("Not in a 3-way diff (use <leader>gm)", vim.log.levels.WARN)
    end
    vim.cmd("diffget //" .. n)
  end
end

-- Fugitive-owned buffers use `q` to close the current view. The mapping is
-- buffer-local so it does not alter Vim's global behavior. It is restricted
-- to buffers where `gq` closes the view, because `gq` is the native format
-- operator in `gitcommit` and `gitrebase`, and `q` would break macro recording.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "fugitive", "fugitiveblame", "git" },
  callback = function(event)
    vim.keymap.set("n", "q", function()
      -- Delegate to Fugitive's own `gq` when it exists in this buffer and
      -- fall back to closing the window otherwise.
      if vim.fn.mapcheck("gq", "n") ~= "" then
        vim.api.nvim_feedkeys(vim.keycode("gq"), "m", false)
      else
        vim.cmd("close")
      end
    end, {
      buffer = event.buf,
      desc = "Close",
    })
  end,
})

-- Fugitive's status buffer provides a Git-specific action through `cc`. The
-- mapping is intentionally restricted to this buffer so native `cc` behavior
-- remains unchanged in commit and rebase buffers. Commits are always verbose:
-- the staged diff is included in the commit buffer, providing the context
-- needed to review changes before completing the commit. This makes the
-- native `cvc` redundant, so it is left untouched.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function(event)
    vim.keymap.set("n", "cc", "<cmd>silent tab Git commit -v<cr>", {
      buffer = event.buf,
      silent = true,
      desc = "Git commit -v (full page, new tab)",
    })
  end,
})

-- Fugitive's blame view uses a vertical split. The default width is
-- insufficient for the author, timestamp, and commit summary, so the
-- window is given a fixed width when the blame buffer is created.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitiveblame",
  callback = function()
    vim.cmd("vertical resize 45")
  end,
})

return {
  {
    "tpope/vim-fugitive",
    -- vim-rhubarb provides GitHub URL resolution for Fugitive's `GBrowse`
    -- command. GitHub Enterprise additionally requires setting
    -- `vim.g.github_enterprise_urls` to the list of enterprise hosts.
    dependencies = { "tpope/vim-rhubarb" },

    -- Every Fugitive command that may be typed before the plugin is loaded
    -- must be listed here, otherwise it fails until another trigger loads it.
    cmd = {
      "Git",
      "G",
      "Ggrep",
      "Glgrep",
      "Gclog",
      "Gllog",
      "Gedit",
      "Gsplit",
      "Gvsplit",
      "Gtabedit",
      "Gdiffsplit",
      "Gvdiffsplit",
      "Ghdiffsplit",
      "Gread",
      "Gwrite",
      "GMove",
      "GRename",
      "GDelete",
      "GRemove",
      "GBrowse",
    },

    -- Keymaps are declared with the plugin specification so Fugitive is
    -- loaded only when one of its Git operations is actually requested.
    keys = {
      -- Git commands that produce a window are opened as vertical splits
      -- to preserve the available horizontal editing space.
      { "<leader>gs", "<cmd>vertical Git<cr>",                                  desc = "Git status" },
      { "<leader>gl", "<cmd>vertical Git log --oneline --decorate --graph<cr>", desc = "Git log" },
      { "<leader>gc", "<cmd>vertical Git commit -v<cr>",                        desc = "Git commit -v" },
      { "<leader>gp", "<cmd>vertical Git push<cr>",                             desc = "Git push" },
      { "<leader>gd", "<cmd>Gvdiffsplit<cr>",                                   desc = "Diff against index/HEAD (uncommitted changes)" },
      { "<leader>gt", toggle_last_commit_diff,                                  desc = "Toggle diff against last commit" },
      { "<leader>gb", "<cmd>Git blame<cr>",                                     desc = "Git blame (current file)" },

      -- Fetch prunes remote-tracking branches that no longer exist, and pull
      -- is restricted to fast-forwards to avoid surprise merge commits.
      { "<leader>gf", "<cmd>Git fetch --all --prune<cr>",                       desc = "Git fetch (all remotes, prune)" },
      { "<leader>gu", "<cmd>vertical Git pull --ff-only<cr>",                   desc = "Git pull (fast-forward only)" },

      -- The status view is isolated in its own tab to provide an
      -- unobstructed workspace for reviewing repository state.
      { "<leader>gg", "<cmd>tab Git<cr>",                                       desc = "Git status (full page, new tab)" },

      -- The full-page commit includes the staged diff in the commit buffer
      -- so changes can be reviewed while the message is written.
      { "<leader>gn", "<cmd>tab Git commit -v<cr>",                             desc = "Git commit -v (full page, new tab)" },

      -- Amend variants: the first opens the message for editing alongside
      -- the diff, the second reuses the previous message and only folds in
      -- the staged changes.
      { "<leader>ga", "<cmd>tab Git commit --amend -v<cr>",                     desc = "Amend last commit" },
      { "<leader>gq", "<cmd>Git commit --amend --no-edit<cr>",                  desc = "Amend last commit (keep message)" },

      -- The rebase range is requested interactively because the appropriate
      -- number of commits depends on the operation being performed.
      { "<leader>gr", interactive_rebase,                                       desc = "Interactive rebase (full page, prompts for HEAD~N)" },

      -- File history is loaded into the quickfix list. The visual mapping
      -- uses `:` so Vim passes the selected range to `Gclog`, which then
      -- lists every commit that touched those lines.
      { "<leader>gh", "<cmd>0Gclog<cr>",                                        desc = "File history (quickfix)" },
      { "<leader>gh", ":Gclog<cr>",                                             mode = "x",                                                 desc = "Line history (quickfix)" },

      -- A three-way diff is only available while a merge or rebase has
      -- conflicts. The window layout is: //2 on the left, working copy in
      -- the middle, //3 on the right. During a merge `//2` is the target
      -- branch and `//3` the merged branch. During a rebase the roles are
      -- inverted: `//2` is the upstream being rebased onto and `//3` is the
      -- commit being replayed.
      { "<leader>gm", "<cmd>Gvdiffsplit!<cr>",                                  desc = "Merge: open 3-way diff" },
      { "<leader>g2", diffget(2),                                               desc = "Diffget //2 (merge: target, rebase: upstream)" },
      { "<leader>g3", diffget(3),                                               desc = "Diffget //3 (merge: incoming, rebase: your commit)" },

      -- The normal-mode mappings operate on the current line. The visual
      -- mappings use `:` so Vim passes the selected range to `GBrowse`.
      { "<leader>go", "<cmd>.GBrowse<cr>",                                      desc = "Open in browser (GBrowse)" },
      { "<leader>go", ":GBrowse<cr>",                                           mode = "x",                                                 desc = "Open selection in browser (GBrowse)" },

      -- The bang form copies the permalink to the clipboard instead of
      -- opening the browser, which is the common case for sharing links.
      { "<leader>gy", "<cmd>.GBrowse!<cr>",                                     desc = "Copy browser link (GBrowse!)" },
      { "<leader>gy", ":GBrowse!<cr>",                                          mode = "x",                                                 desc = "Copy selection link (GBrowse!)" },
    },
  },

  {
    "echasnovski/mini.diff",
    version = false,
    event = { "BufReadPre", "BufNewFile" },

    keys = {
      {
        "<leader>ho",
        function()
          local md = require("mini.diff")

          -- Diff overlays require buffer-local diff state. Enable the
          -- feature on demand when the current buffer has no diff data.
          if not md.get_buf_data(0) then
            md.enable(0)
          end

          md.toggle_overlay(0)
        end,
        desc = "Toggle diff overlay",
      },
    },

    opts = {
      -- Hunk navigation, the hunk text object, and stage/reset operations
      -- are exposed so mini.diff covers the full hunk workflow without a
      -- second plugin. `apply` and `reset` are operators, so they accept a
      -- motion or a visual selection. They live under `<leader>h` to stay
      -- clear of the native `gh`-style mappings used by other plugins.
      mappings = {
        apply = "<leader>ha",
        reset = "<leader>hr",
        textobject = "ih",
        goto_first = "[H",
        goto_prev = "[h",
        goto_next = "]h",
        goto_last = "]H",
      },
    },
  },

  -- Branch, commit, and stash pickers. Declared as an optional spec so the
  -- mappings are merged into the existing fzf-lua setup and are ignored
  -- when fzf-lua is not installed.
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
