-- lua/utils/buffers.lua

local M = {}

function M.is_terminal(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal"
end

function M.is_normal_window(win)
  return vim.api.nvim_win_get_config(win).relative == ""
end

-- Saves `buf` (default: current) if it has unsaved changes and a real file name
-- (avoids erroring on unnamed/scratch buffers, which :update can't handle).
-- Returns true if the buffer is safe to delete (nothing left to lose).
function M.save_if_modified(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf

  if M.is_terminal(buf) or not vim.bo[buf].modified then
    return true
  end
  if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then
    return false -- special or unnamed buffer: nowhere to save
  end

  vim.api.nvim_buf_call(buf, function()
    pcall(vim.cmd, "silent! update")
  end)
  return not vim.bo[buf].modified
end

function M.delete(buf)
  return pcall(vim.api.nvim_buf_delete, buf, { force = M.is_terminal(buf) })
end

-- Most recently used listed buffer, other than `buf`
function M.pick_replacement(buf)
  local best
  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if info.bufnr ~= buf and (not best or info.lastused > best.lastused) then
      best = info
    end
  end
  return best and best.bufnr
end

-- Deletes `buf` but keeps every window that was showing it
function M.delete_keep_layout(buf)
  local wins = vim.fn.win_findbuf(buf)
  if #wins > 0 then
    local repl = M.pick_replacement(buf) or vim.api.nvim_create_buf(true, false)
    for _, win in ipairs(wins) do
      vim.api.nvim_win_set_buf(win, repl)
    end
  end
  return M.delete(buf)
end

-- Saves and deletes every listed buffer that passes `filter`.
-- Only notifies if some buffer had nowhere to be saved (it is kept on purpose).
function M.delete_where(filter)
  local kept = 0
  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if not filter or filter(info) then
      if M.save_if_modified(info.bufnr) then
        M.delete(info.bufnr)
      else
        kept = kept + 1
      end
    end
  end
  if kept > 0 then
    vim.notify(kept .. " buffer(s) could not be saved, kept", vim.log.levels.WARN)
  end
end

return M
