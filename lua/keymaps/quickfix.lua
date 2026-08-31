local km = vim.keymap.set

-- Detect whether the current qf-filetype window is a loclist or quickfix.
-- Both share filetype "qf", so this distinction matters everywhere below.
local function is_loclist()
  return vim.fn.getwininfo(vim.fn.win_getid())[1].loclist == 1
end

-- Cycle list items with wraparound, keeping focus on the list window.
local function list_cycle(forward, loclist)
  local get_info = loclist and function(o) return vim.fn.getloclist(0, o) end
      or vim.fn.getqflist
  -- No 'what' arg here on purpose: with one, getqflist/getloclist return
  -- metadata instead of the item list, and # would fail or lie.
  local get_items = loclist and function() return vim.fn.getloclist(0) end
      or vim.fn.getqflist
  local idx = get_info({ idx = 0 }).idx
  local total = #get_items()
  local prefix = loclist and "l" or "c"
  if forward then
    vim.cmd(idx >= total and (prefix .. "first") or (prefix .. "next"))
  else
    vim.cmd(idx < 2 and (prefix .. "last") or (prefix .. "prev"))
  end
  vim.cmd("wincmd p")
end

-- Generic toggle, shared by quickfix and loclist.
local function list_toggle(loclist)
  -- getqflist(what) takes 1 arg; getloclist(winnr, what) takes 2.
  local get_info = loclist and function(o) return vim.fn.getloclist(0, o) end
      or vim.fn.getqflist
  -- Passing a 'what' dict (even empty) returns metadata, not the items —
  -- call with no 'what' arg at all to get the raw item list for #.
  local get_items = loclist and function() return vim.fn.getloclist(0) end
      or vim.fn.getqflist
  local open_cmd = loclist and vim.cmd.lopen or vim.cmd.copen
  local close_cmd = loclist and vim.cmd.lclose or vim.cmd.cclose

  local list = get_info({ winid = 0 })
  if list.winid ~= 0 then
    close_cmd()
    return
  end

  local size = #get_items()
  if size == 0 then
    -- Just a heads-up, not a blocker: we still open the (empty) list below
    -- so the user can see there's nothing there and close it themselves.
    vim.notify(
      (loclist and "Location list" or "Quickfix list") .. " is empty",
      vim.log.levels.WARN
    )
  end

  -- Passing 0/height only when there are items; with size == 0 we call
  -- open_cmd with no height arg so it doesn't try to open a 0-line window.
  local ok, err = pcall(open_cmd, size > 0 and math.min(size, 10) or nil)
  if not ok and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

-- Toggles
km("n", "<leader>xl", function() list_toggle(true) end, { desc = "Toggle location list" })
km("n", "<leader>xq", function() list_toggle(false) end, { desc = "Toggle quickfix list" })

-- Populate lists from LSP diagnostics
km("n", "<leader>xd", function()
  vim.diagnostic.setloclist({ open = true })
end, { desc = "Buffer diagnostics -> loclist" })

km("n", "<leader>xD", function()
  vim.diagnostic.setqflist({ open = true })
end, { desc = "Workspace diagnostics -> quickfix" })

-- Auto-open the list when a command populates it
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = { "[^l]*" }, -- grep, make, vimgrep, etc.
  callback = function()
    if #vim.fn.getqflist() > 0 then
      vim.cmd("copen " .. math.min(#vim.fn.getqflist(), 10))
    end
  end,
})

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = { "l*" }, -- lgrep, lvimgrep, lmake, etc.
  callback = function()
    if #vim.fn.getloclist(0) > 0 then
      vim.cmd("lopen " .. math.min(#vim.fn.getloclist(0), 10))
    end
  end,
})

-- Keymaps inside the qf/loclist window
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function(ev)
    local loclist = is_loclist()
    local close_only = loclist and ":lclose<CR>" or ":cclose<CR>"
    local opts = { noremap = true, silent = true, buffer = ev.buf }

    vim.keymap.set("n", "<CR>", "<CR>" .. (loclist and ":lclose<CR>" or ":cclose<CR>"),
      vim.tbl_extend("force", opts, { desc = "Jump to item and close list" }))
    vim.keymap.set("n", "q", close_only,
      vim.tbl_extend("force", opts, { desc = "Close list" }))

    -- Open item in a split without closing the list
    vim.keymap.set("n", "<C-v>", "<C-w><CR><C-w>L",
      vim.tbl_extend("force", opts, { desc = "Open in vertical split" }))
    vim.keymap.set("n", "<C-x>", "<C-w><CR><C-w>K",
      vim.tbl_extend("force", opts, { desc = "Open in horizontal split" }))

    vim.keymap.set("n", "<Tab>", function() list_cycle(true, loclist) end,
      vim.tbl_extend("force", opts, { desc = "Next item (preview)" }))
    vim.keymap.set("n", "<S-Tab>", function() list_cycle(false, loclist) end,
      vim.tbl_extend("force", opts, { desc = "Previous item (preview)" }))
  end,
})
