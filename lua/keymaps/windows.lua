-- lua/keymaps/windows.lua

local utils = require("utils")
local km = vim.keymap.set

-- Helpers
local function is_terminal(buf)
  return vim.bo[buf].buftype == "terminal"
end

-- Saves the buffer only if it is a regular file buffer
-- (terminals have nothing to save)
local function save_current()
  if not is_terminal(vim.api.nvim_get_current_buf()) then
    utils.save_if_modified()
  end
end

-- Normal (non-floating) windows in the current tab
local function normal_wins()
  return vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_config(win).relative == ""
  end, vim.api.nvim_tabpage_list_wins(0))
end

-- Window navigation
km("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
km("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
km("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
km("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Move window within layout
km("n", "<leader>mh", "<C-w>H", { desc = "Move window to far left" })
km("n", "<leader>mj", "<C-w>J", { desc = "Move window to bottom" })
km("n", "<leader>mk", "<C-w>K", { desc = "Move window to top" })
km("n", "<leader>ml", "<C-w>L", { desc = "Move window to far right" })

-- Move window to new tab
km("n", "<leader>mt", "<C-w>T", { desc = "Move window to new tab" })

-- Swap current window with the next one
km("n", "<leader>mx", "<C-w>x", { desc = "Swap window with next" })

-- Rotate all windows, keeping the current layout
km("n", "<leader>mr", "<C-w>r", { desc = "Rotate windows" })

-- Window management
km("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split window vertically" })
km("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split window horizontally" })
km("n", "<leader>se", "<C-w>=", { desc = "Equalize window sizes" })

km("n", "<leader>sc", function()
  if #normal_wins() <= 1 then
    vim.notify("Last window, nothing to close", vim.log.levels.INFO)
    return
  end
  save_current()
  -- Closing a window never kills a terminal job; the buffer just stays hidden
  local ok, err = pcall(vim.cmd, "close")
  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
  end
end, { desc = "Save and close current window" })

km("n", "<leader>so", function()
  save_current()

  local current = vim.api.nvim_get_current_win()
  local kept = 0

  -- Not using :only, since it errors when another window has unsaved changes.
  -- Windows with modified file buffers are left open instead.
  for _, win in ipairs(normal_wins()) do
    if win ~= current then
      local buf = vim.api.nvim_win_get_buf(win)
      if not is_terminal(buf) and vim.bo[buf].modified then
        kept = kept + 1
      else
        pcall(vim.api.nvim_win_close, win, false)
      end
    end
  end

  if kept > 0 then
    vim.notify(
      kept .. " window(s) kept (unsaved changes)",
      vim.log.levels.INFO
    )
  end
end, { desc = "Save and close other windows (keeps modified ones)" })

-- Window resizing
km("n", "+", "<cmd>resize +5<cr>", { desc = "Increase window height" })
km("n", "_", "<cmd>resize -5<cr>", { desc = "Decrease window height" })
km("n", "=", "<cmd>vertical resize +5<cr>", { desc = "Increase window width" })
km("n", "-", "<cmd>vertical resize -5<cr>", { desc = "Decrease window width" })

-- Maximize window (toggle between maximized and original size)
km("n", "<leader>sm", function()
  if vim.fn.winnr("$") == 1 then
    return
  end
  if vim.t.zoom then
    vim.cmd(vim.t.zoom)
    vim.t.zoom = nil
  else
    vim.t.zoom = vim.fn.winrestcmd()
    vim.cmd("resize")
    vim.cmd("vertical resize")
  end
end, { desc = "Toggle window zoom" })
