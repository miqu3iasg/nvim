-- lua/keymaps/buffers.lua

local utils = require("utils")

local km = vim.keymap.set

-- Helpers

local function is_terminal(buf)
  return vim.bo[buf].buftype == "terminal"
end

-- Deletes a buffer. Terminals are forced (this kills the shell), since Neovim
-- always treats a running terminal as "modified" and would refuse otherwise.
local function delete_buf(buf)
  return pcall(vim.api.nvim_buf_delete, buf, { force = is_terminal(buf) })
end

-- Deletes listed buffers (optionally filtered), skipping the ones that can't
-- be deleted safely (unsaved file changes).
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

km("n", "<leader>bd", function()
  local buf = vim.api.nvim_get_current_buf()
  if not is_terminal(buf) then
    utils.save_if_modified()
  end
  vim.cmd("bprevious")
  if vim.api.nvim_get_current_buf() == buf then
    vim.cmd("enew") -- it was the only buffer
  end
  delete_buf(buf)
end, { desc = "Save and delete buffer" })

km("n", "<leader>ba", function()
  delete_buffers()
end, { desc = "Delete all buffers (keeps modified ones)" })

km("n", "<leader>bo", function()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()

  -- Close other windows (ignoring floats) whose buffer is saved or a terminal.
  -- Not using :only, since it errors when another window has unsaved changes.
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= current_win
        and vim.api.nvim_win_get_config(win).relative == ""
    then
      local buf = vim.api.nvim_win_get_buf(win)
      if is_terminal(buf) or not vim.bo[buf].modified then
        pcall(vim.api.nvim_win_close, win, false)
      end
    end
  end

  -- Delete other buffers, keeping the current one and modified ones
  delete_buffers(function(buf)
    return buf.bufnr ~= current_buf
  end)
end, { desc = "Close other windows and buffers (keeps modified ones)" })

-- Buffer navigation
km("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer" })
km("n", "[b", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
km("n", "<leader><Space>", "<C-^>", { desc = "Toggle between last two buffers" })
