-- lua/utils/close.lua

local M = {}

local function is_fugitive_buf(buf)
  return vim.api.nvim_buf_get_name(buf):find("^fugitive://") ~= nil
end

-- Keeps the working copy (the only diff window that is not a `fugitive://`
-- buffer) and closes the rest. Replaces Fugitive's `dq`, which is not mapped
-- in every window
function M.close_diff()
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
-- A `gitcommit` buffer is discarded, which aborts the commit
function M.close_view()
  if vim.wo.diff then
    return M.close_diff()
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
-- blame keep Fugitive's own `gq`
function M.map_close(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local ft = vim.bo[buf].filetype
  local opts = { buffer = buf, silent = true, desc = "Close Fugitive view" }
  if ft == "fugitive" or ft == "fugitiveblame" or ft == "git" or ft == "gitcommit" then
    vim.keymap.set("n", "q", M.close_view, opts)
  end
  if ft ~= "fugitive" and ft ~= "fugitiveblame" and not vim.bo[buf].modifiable then
    vim.keymap.set("n", "gq", M.close_view, opts)
    vim.keymap.set("n", "dq", M.close_view, opts)
  end
end

-- Registers the autocmds. Idempotent (the augroup uses `clear = true`)
function M.setup()
  local group = vim.api.nvim_create_augroup("FugitiveCloseView", { clear = true })

  -- Runs on the next tick so our maps override the ones Fugitive installs
  -- after setting the filetype
  vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    group = group,
    pattern = { "fugitive", "fugitiveblame", "git", "gitcommit", "fugitive://*" },
    callback = function(e)
      vim.schedule(function()
        M.map_close(e.buf)
      end)
    end,
  })

  -- Also gives the working copy a `dq` once it enters diff mode
  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = "diff",
    callback = function()
      if vim.wo.diff then
        vim.keymap.set("n", "dq", M.close_diff, {
          buffer = vim.api.nvim_get_current_buf(),
          silent = true,
          desc = "Close diff",
        })
      end
    end,
  })
end

return M
