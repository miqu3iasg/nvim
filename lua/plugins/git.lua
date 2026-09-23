-- lua/plugins/git.lua

-- Function must be defined before the plugin spec below, since it's
-- referenced directly as a `keys` handler.
local function toggle_last_commit_diff()
  if vim.wo.diff then
    vim.cmd("diffoff!")
    vim.cmd("q")
  else
    vim.cmd("Gvdiffsplit HEAD~1")
  end
end

-- Prompts for how many commits back to rebase, then opens the interactive
-- rebase todo list full-page (same "tab" pattern as cvc/<leader>gg below).
local function interactive_rebase()
  local n = vim.fn.input("Rebase -i HEAD~", "3")
  if n ~= "" then
    vim.cmd("tab Git rebase -i HEAD~" .. n)
  end
end

-- Tracks whether gitsigns' own sign rendering is currently on. gitsigns
-- doesn't expose a public getter for this, so we track it ourselves; it
-- starts `false` to match `signcolumn = false` in the opts below.
local gitsigns_signs_visible = false

-- Turns the sign column on (only if it isn't already) and makes sure
-- gitsigns signs are shown. Leaves the sign column alone if something
-- else already has it active.
local function gitsigns_show()
  if vim.o.signcolumn == "no" then
    vim.o.signcolumn = "yes"
  end
  if not gitsigns_signs_visible then
    require("gitsigns").toggle_signs(true)
    gitsigns_signs_visible = true
  end
end

-- Turns everything off: gitsigns signs and the sign column itself.
-- Checks current state first so it never does redundant work.
local function gitsigns_hide()
  if gitsigns_signs_visible then
    require("gitsigns").toggle_signs(false)
    gitsigns_signs_visible = false
  end
  if vim.o.signcolumn ~= "no" then
    vim.o.signcolumn = "no"
  end
end

-- Per-buffer toggle for mini.diff. mini.diff enables itself on every
-- buffer by default, so we keep our own flag (`minidiff_user_on`) to know
-- whether the user explicitly turned it on for a given buffer.
local function minidiff_toggle()
  local md = require("mini.diff")
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].minidiff_user_on then
    vim.b[buf].minidiff_user_on = false
    md.disable(buf)
  else
    vim.b[buf].minidiff_user_on = true
    md.enable(buf)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "fugitive", "git", "gitcommit", "gitrebase" },
  callback = function(event)
    vim.keymap.set("n", "q", "gq", { buffer = event.buf, remap = true, desc = "Close" })
  end,
})

-- `cc` only in the fugitive status buffer. In `gitcommit`/`gitrebase`
-- it must stay as Vim's native "change whole line".
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function(event)
    -- normal commit in a new tab (full screen)
    vim.keymap.set("n", "cc", "<cmd>silent tab Git commit<cr>", {
      buffer = event.buf,
      silent = true,
      desc = "Git commit (full page, new tab)",
    })

    -- the commit buffer opens in a new tab (full screen), and -v
    -- includes the staged diff in it.
    vim.keymap.set("n", "cvc", "<cmd>silent tab Git commit -v<cr>", {
      buffer = event.buf,
      silent = true,
      desc = "Git commit -v (full page, new tab)",
    })
  end,
})

-- 3-way merge/rebase conflict resolution. Only meaningful while a
-- Gdiffsplit/Gvdiffsplit! conflict view is open, but harmless elsewhere
-- since diffget on a non-existent buffer number just errors quietly.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "fugitive", "gitrebase" },
  callback = function(event)
    vim.keymap.set("n", "gh", "<cmd>diffget //2<cr>", {
      buffer = event.buf,
      desc = "Diffget //2 (target/ours)",
    })
    vim.keymap.set("n", "gl", "<cmd>diffget //3<cr>", {
      buffer = event.buf,
      desc = "Diffget //3 (merge/theirs)",
    })
  end,
})

-- `:Git blame` opens a scrollbound vertical split whose default width is
-- too narrow for author + date + summary; widen it every time it opens.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitiveblame",
  callback = function()
    vim.cmd("vertical resize 45")
  end,
})

return {
  {
    "tpope/vim-fugitive",
    -- vim-rhubarb teaches :GBrowse how to resolve GitHub (and GitHub
    -- Enterprise) URLs; without it, GBrowse has no host to open.
    dependencies = { "tpope/vim-rhubarb" },
    cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "GBrowse" },
    -- `keys` (rather than a separate vim.keymap.set block) makes these
    -- lazy-load the plugin on first press, and keeps them next to the
    -- plugin they belong to.
    keys = {
      -- any :Git subcommand that opens a window (status, commit, push, log)
      -- does so as a vertical split instead of its horizontal default.
      { "<leader>gs", "<cmd>vertical Git<cr>",                                  desc = "Git status" },
      { "<leader>gl", "<cmd>vertical Git log --oneline --decorate --graph<cr>", desc = "Git log" },
      { "<leader>gc", "<cmd>vertical Git commit<cr>",                           desc = "Git commit" },
      { "<leader>gp", "<cmd>vertical Git push<cr>",                             desc = "Git push" },
      { "<leader>gf", "<cmd>Git fetch<cr>",                                     desc = "Git fetch" },
      { "<leader>gP", "<cmd>vertical Git pull<cr>",                             desc = "Git pull" },
      { "<leader>gB", "<cmd>Git blame<cr>",                                     desc = "Git blame (current file)" },
      { "<leader>gd", "<cmd>Gvdiffsplit<cr>",                                   desc = "Diff against index/HEAD (uncommitted changes)" },
      { "<leader>gD", toggle_last_commit_diff,                                  desc = "Toggle diff against last commit" },
      -- Full-page status in its own tab, unobstructed by other splits.
      { "<leader>gg", "<cmd>tabnew | Git | only<cr>",                           desc = "Git status (full page, new tab)" },
      { "<leader>gr", interactive_rebase,                                       desc = "Interactive rebase (full page, prompts for HEAD~N)" },
      { "<leader>go", "<cmd>.GBrowse<cr>",                                      mode = { "n", "v" },                                        desc = "Open in browser (GBrowse)" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    -- BufReadPre/BufNewFile is gitsigns' own recommended lazy-load trigger:
    -- it guarantees attachment happens as soon as a buffer is opened,
    -- rather than depending on lazy.nvim's VeryLazy user-event timing.
    event = { "BufReadPre", "BufNewFile" },
    -- Also lazy-load on these keys, in case they're pressed before any
    -- buffer-opening event has fired.
    keys = {
      { "<leader>hv", gitsigns_show, desc = "Show sign column + gitsigns signs" },
      { "<leader>hx", gitsigns_hide, desc = "Hide sign column + gitsigns signs" },
    },
    opts = {
      -- All visual indicators disabled on purpose: this config only wants
      -- gitsigns for its hunk actions (stage/reset/preview/blame), not for
      -- gutter signs, line highlighting, or inline blame text.
      signcolumn = false,
      numhl = false,
      linehl = false,
      word_diff = false,
      current_line_blame = false,
      status_formatter = nil,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Hunk-level actions live under <leader>h, separate from the
        -- repo/file-level <leader>g actions above, so the two sets never
        -- collide (e.g. <leader>gs = Git status, <leader>hs = stage hunk).
        map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hb", gs.blame_line, "Blame line")
        map("n", "]h", gs.next_hunk, "Next hunk")
        map("n", "[h", gs.prev_hunk, "Previous hunk")
      end,
    },
  },
  {
    "echasnovski/mini.diff",
    version = false,
    event = { "BufReadPre", "BufNewFile" },
    -- mini.diff's own binds for these two are the reason to reach for it:
    -- gitsigns already owns hunk stage/reset/preview/navigation (<leader>hs,
    -- <leader>hr, <leader>hp, ]h/[h), so those are disabled below to avoid
    -- two plugins fighting over the same keys.
    keys = {
      { "<leader>ho", function() require("mini.diff").toggle_overlay(0) end, desc = "Toggle diff overlay" },
      { "<leader>ht", minidiff_toggle,                                       desc = "Toggle mini.diff signs for buffer" },
    },
    opts = {
      view = {
        style = "sign",
        signs = { add = "▎", change = "▎", delete = "" },
      },
      -- Disabled - apply/reset/textobject and hunk navigation overlap with
      -- gitsigns' own hunk keymaps above. '' unmaps a default entirely.
      mappings = {
        apply_hunks = "",
        apply_hunks_visual = "",
        reset_hunks = "",
        reset_hunks_visual = "",
        textobject = "",
        goto_first = "",
        goto_prev = "",
        goto_next = "",
        goto_last = "",
      },
    },
    config = function(_, opts)
      local md = require("mini.diff")
      md.setup(opts)

      -- setup() enables the plugin on every buffer. Turn it off here and
      -- on any buffer opened later, unless the user explicitly enabled it
      -- for that buffer with <leader>ht.
      local function ensure_off(buf)
        if not vim.b[buf].minidiff_user_on then
          md.disable(buf)
        end
      end

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          ensure_off(buf)
        end
      end

      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("MiniDiffOffByDefault", { clear = true }),
        callback = function(ev)
          -- runs after mini.diff's own auto-enable on BufEnter
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ev.buf) then
              ensure_off(ev.buf)
            end
          end)
        end,
      })
    end,
  },
}
