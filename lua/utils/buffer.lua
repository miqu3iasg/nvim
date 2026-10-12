-- lua/utils/buffer.lua

local M = {}

-- Saves the current buffer if it has unsaved changes and a real file name
-- (avoids erroring on unnamed/scratch buffers, which :update can't handle)
function M.save_if_modified()
  if vim.bo.modified and vim.api.nvim_buf_get_name(0) ~= "" then
    vim.cmd("update")
  end
end

return M
