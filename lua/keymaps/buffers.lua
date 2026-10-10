-- lua/keymaps/buffers.lua

local utils = require("utils")

-- Helpers
local function km(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("keep", opts or {}, { silent = true })
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function is_terminal(buf)
  return vim.bo[buf].buftype == "terminal"
end

local function is_normal_window(win)
  return vim.api.nvim_win_get_config(win).relative == ""
end

local function delete_buf(buf)
  return pcall(vim.api.nvim_buf_delete, buf, { force = is_terminal(buf) })
end

local function pick_replacement(buf)
  local alt = vim.fn.bufnr("#")
  if alt > 0
      and alt ~= buf
      and vim.api.nvim_buf_is_valid(alt)
      and vim.bo[alt].buflisted
  then
    return alt
  end
  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if info.bufnr ~= buf then
      return info.bufnr
    end
  end
  return nil
end

local function delete_buf_keep_layout(buf)
  local replacement = pick_replacement(buf)
  if not replacement then
    replacement = vim.api.nvim_create_buf(true, false) -- empty buffer
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_set_buf(win, replacement)
  end
  return delete_buf(buf)
end

local function delete_buffers(filter)
  local kept = 0
  for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if not filter or filter(buf) then
      if not delete_buf(buf.bufnr) then
        kept = kept + 1
      end
    end
  end
  if kept > 0 then
    vim.notify(
      kept .. " buffer(s) kept (unsaved changes)",
      vim.log.levels.INFO
    )
  end
end

-- Buffers
km("n", "<leader>bn", "<cmd>enew<CR>", { desc = "New buffer" })
km("n", "<leader>bw", "<cmd>write<CR>", { desc = "Save buffer" })
km('n', '<leader>bs', '<cmd>noautocmd write<CR>', { desc = "Save buffer without auto-formatting" })

km("n", "<leader>bq", function()
  local ok, err = pcall(vim.cmd, "wall")
  if not ok then
    vim.notify(
      "Could not save all buffers, quit aborted:\n" .. tostring(err),
      vim.log.levels.INFO
    )
    return
  end
  vim.cmd("qall!")
end, { desc = "Save all and quit" })

km("n", "<leader>bd", function()
  local buf = vim.api.nvim_get_current_buf()

  if not is_terminal(buf) and vim.bo[buf].modified then
    pcall(utils.save_if_modified)
    if vim.bo[buf].modified then
      vim.notify("Could not save buffer, not deleted", vim.log.levels.INFO)
      return
    end
  end

  delete_buf_keep_layout(buf)
end, { desc = "Save and delete buffer" })

km("n", "<leader>ba", function()
  local scratch = vim.api.nvim_create_buf(true, false)
  local used = false

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_normal_window(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buflisted
          and (is_terminal(buf) or not vim.bo[buf].modified)
      then
        vim.api.nvim_win_set_buf(win, scratch)
        used = true
      end
    end
  end

  delete_buffers(function(buf)
    return buf.bufnr ~= scratch
  end)

  if not used then
    pcall(vim.api.nvim_buf_delete, scratch, {})
  end
end, { desc = "Delete all buffers (keeps modified ones)" })

km("n", "<leader>bo", function()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= current_win and is_normal_window(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if is_terminal(buf) or not vim.bo[buf].modified then
        pcall(vim.api.nvim_win_close, win, false)
      end
    end
  end

  delete_buffers(function(buf)
    return buf.bufnr ~= current_buf
  end)
end, { desc = "Close other windows and buffers (keeps modified ones)" })

-- Buffer navigation
km("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer" })
km("n", "[b", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
km("n", "<Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })
km("n", "<S-Tab>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
km("n", "<leader><Space>", "<C-^>", { desc = "Toggle between last two buffers" })
