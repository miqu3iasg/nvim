-- lua/sessions.lua

-- Minimal, fully automatic, per-directory session management built on
-- :mksession and :source.
--
-- Refs:
--     - https://github.com/mhinz/vim-startify/blob/81e36c352a8deea54df5ec1e2f4348685569bed2/autoload/startify.vim#L27
--     - https://github.com/tpope/vim-obsession/blob/master/plugin/obsession.vim
--     - https://github.com/bruhtus/dotfiles/blob/master/.vim/after/autoload/possession.vim

local M = {}

local SESSION_DIR = vim.fn.stdpath("state") .. "/sessions/"

-- Filetypes that must not trigger a save on their own, e.g. when Neovim is
-- used as `git commit` editor inside a project that has a stored session.
local IGNORED_FILETYPES = { gitcommit = true, gitrebase = true }

--- Whether session handling is active (only inside tmux).
---@return boolean
function M.enabled()
  return vim.env.TMUX ~= nil
end

--- Absolute path of the session file for the current working directory.
---@return string
function M.path()
  local name = vim.fn.getcwd():gsub("/", "__"):gsub("[^%w%-%._]", "_")
  return SESSION_DIR .. name
end

--- Number of buffers that represent real files on disk.
--- Excludes special buffers (oil, help, terminals, ...), unnamed buffers and
--- IGNORED_FILETYPES.
---@return integer
local function count_file_buffers()
  local count = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local is_file = vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
    if is_file and not IGNORED_FILETYPES[vim.bo[buf].filetype] then
      count = count + 1
    end
  end
  return count
end

--- Delete Oil buffers so they are not written into the session file.
local function remove_oil_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == "oil" then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

--- Restore the session of the current directory, if one exists.
--- Errors raised while sourcing are suppressed so that a partially outdated
--- session (e.g. a deleted file) still opens.
---@return boolean restored true if a session file was found and sourced
function M.load()
  local path = M.path()
  if not vim.uv.fs_stat(path) then
    return false
  end
  vim.cmd("silent! source " .. vim.fn.fnameescape(path))
  return true
end

--- Save the session of the current directory.
--- Does nothing unless at least one real file buffer is open, so that
--- opening and closing Neovim on the file explorer alone never overwrites
--- an existing session.
function M.save()
  if count_file_buffers() < 1 then
    return
  end

  remove_oil_buffers()

  vim.fn.mkdir(SESSION_DIR, "p")
  vim.cmd("mksession! " .. vim.fn.fnameescape(M.path()))
end

return M
