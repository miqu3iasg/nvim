-- lua/plugins/git.lua

-- Histogram diffs read better than Myers on refactored code, and linematch
-- aligns changed lines within a hunk.
vim.opt.diffopt:append({ "algorithm:histogram", "indent-heuristic", "linematch:60" })

-- The default blame width is too narrow for author, timestamp and summary.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitiveblame",
  callback = function()
    vim.cmd("vertical resize 45")
  end,
})

local function is_fugitive_buf(buf)
  return vim.api.nvim_buf_get_name(buf):find("^fugitive://") ~= nil
end

-- Keeps the working copy (the only diff window that is not a `fugitive://`
-- buffer) and closes the rest. Replaces Fugitive's `dq`, which is not mapped
-- in every window.
local function close_diff()
  if not vim.wo.diff then
    return
  end
  local wins = vim.tbl_filter(function(w)
    return vim.wo[w].diff
  end, vim.api.nvim_tabpage_list_wins(0))

  local keep
  for _, w in ipairs(wins) do
    if not is_fugitive_buf(vim.api.nvim_win_get_buf(w)) then
      keep = w
      break
    end
  end
  keep = keep or vim.api.nvim_get_current_win()

  for _, w in ipairs(wins) do
    if w ~= keep then
      pcall(vim.api.nvim_win_close, w, false)
    end
  end
  vim.api.nvim_set_current_win(keep)
  vim.cmd("diffoff!")
end

-- Closes the Fugitive view under the cursor without ever quitting Neovim.
-- Status and blame delegate to Fugitive's own `gq` so blame state is restored.
-- A `gitcommit` buffer is discarded, which aborts the commit.
local function close_view()
  if vim.wo.diff then
    return close_diff()
  end

  local ft = vim.bo.filetype
  if (ft == "fugitive" or ft == "fugitiveblame") and vim.fn.maparg("gq", "n") ~= "" then
    return vim.api.nvim_feedkeys(vim.keycode("gq"), "m", false)
  end

  local bang = ft == "gitcommit" and "!" or ""
  local ok, err = pcall(function()
    if #vim.api.nvim_tabpage_list_wins(0) > 1 or #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd("close" .. bang)
      return
    end
    local alt = vim.fn.bufnr("#")
    if alt > 0 and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buftype == "" then
      vim.cmd("buffer" .. bang .. " " .. alt)
    else
      vim.cmd("enew" .. bang)
    end
  end)
  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
  end
end

-- Maps `q` on Fugitive views, plus `gq` and `dq` on read-only ones. Status and
-- blame keep Fugitive's own `gq`. Runs on the next tick so our maps override
-- the ones Fugitive installs after setting the filetype.
local function map_close(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local ft = vim.bo[buf].filetype
  local opts = { buffer = buf, silent = true, desc = "Close Fugitive view" }
  if ft == "fugitive" or ft == "fugitiveblame" or ft == "git" or ft == "gitcommit" then
    vim.keymap.set("n", "q", close_view, opts)
  end
  if ft ~= "fugitive" and ft ~= "fugitiveblame" and not vim.bo[buf].modifiable then
    vim.keymap.set("n", "gq", close_view, opts)
    vim.keymap.set("n", "dq", close_view, opts)
  end
end

local close_group = vim.api.nvim_create_augroup("FugitiveCloseView", { clear = true })
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
  group = close_group,
  pattern = { "fugitive", "fugitiveblame", "git", "gitcommit", "fugitive://*" },
  callback = function(e)
    vim.schedule(function()
      map_close(e.buf)
    end)
  end,
})

-- Also gives the working copy a `dq` once it enters diff mode.
vim.api.nvim_create_autocmd("OptionSet", {
  group = close_group,
  pattern = "diff",
  callback = function()
    if vim.wo.diff then
      vim.keymap.set("n", "dq", close_diff, {
        buffer = vim.api.nvim_get_current_buf(),
        silent = true,
        desc = "Close diff",
      })
    end
  end,
})

return {
  {
    "tpope/vim-fugitive",
    -- Provides GitHub URL resolution for `GBrowse`. GitHub Enterprise also
    -- needs `vim.g.github_enterprise_urls`.
    dependencies = { "tpope/vim-rhubarb" },
    cmd = { "Git", "G", "GBrowse", "Gvdiffsplit", "Gdiffsplit" },

    keys = {
      { "<leader>gs", "<cmd>silent vertical Git<cr>",                desc = "Git status (vertical split)" },
      { "<leader>gl", "<cmd>silent vertical Git log<cr>",            desc = "Git log (vertical split)" },
      { "<leader>gc", "<cmd>silent vertical Git commit -v<cr>",      desc = "Git commit -v (vertical split)" },
      { "<leader>gp", "<cmd>Git push<cr>",                           desc = "Git push" },
      { "<leader>gb", "<cmd>silent Git blame<cr>",                   desc = "Git blame (current file)" },
      { "<leader>gd", "<cmd>silent Gvdiffsplit<cr>",                 desc = "Diff against index (close with dq)" },
      { "<leader>g.", "<cmd>silent Git add -A<cr>",                  desc = "Git add -A (stage all)" },

      -- Fetch prunes stale remote branches; pull is fast-forward only to avoid
      -- surprise merge commits.
      { "<leader>gf", "<cmd>silent Git fetch --all --prune<cr>",     desc = "Git fetch (all remotes, prune)" },
      { "<leader>gu", "<cmd>silent vertical Git pull --ff-only<cr>", desc = "Git pull (fast-forward only)" },

      -- Leaves the command line open so only the number needs to be typed.
      { "<leader>gr", ":Git rebase -i HEAD~",                        desc = "Interactive rebase (type HEAD~N)" },

      -- Visual mappings use `:` so the selected range reaches `GBrowse`. The
      -- bang form copies the permalink instead of opening the browser.
      { "<leader>go", "<cmd>silent .GBrowse<cr>",                    desc = "Open in browser (GBrowse)" },
      { "<leader>go", ":<C-u>silent '<,'>GBrowse<cr>",               mode = "x",                                 desc = "Open selection in browser (GBrowse)" },
      { "<leader>gy", "<cmd>silent .GBrowse!<cr>",                   desc = "Copy browser link (GBrowse!)" },
      { "<leader>gy", ":<C-u>silent '<,'>GBrowse!<cr>",              mode = "x",                                 desc = "Copy selection link (GBrowse!)" },
    },
  },

  {
    "echasnovski/mini.diff",
    version = false,
    event = { "BufReadPre", "BufNewFile" },

    keys = {
      {
        "td",
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
        goto_first = "[C",
        reset = "<leader>hr",
        textobject = "ih",
        goto_prev = "[c",
        goto_next = "]c",
        goto_last = "]C",
      },
    },
  },

  -- Merged into the existing fzf-lua setup; ignored if fzf-lua is absent.
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
