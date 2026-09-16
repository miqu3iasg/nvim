-- lua/langs/markdown/utils.lua

-- Small helpers shared across the keymap topic modules. Kept separate
-- so each one (lists, links, editing, ...) doesn't have to redefine
-- buffer-line access.

local M = {}

-- Thin wrapper over vim.keymap.set that always scopes the mapping to
-- the given buffer. Extra opts (e.g. { expr = true }) are merged in,
-- for mappings whose rhs is an expression.
function M.map(bufnr, mode, lhs, rhs, desc, opts)
  opts = opts or {}
  opts.buffer = bufnr
  if opts.silent == nil then
    opts.silent = true
  end
  opts.desc = desc
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.get_line(bufnr, n)
  return vim.api.nvim_buf_get_lines(bufnr, n - 1, n, false)[1] or ""
end

function M.set_line(bufnr, n, text)
  vim.api.nvim_buf_set_lines(bufnr, n - 1, n, false, { text })
end

-- Whether line_nr sits inside a fenced code block, i.e. an odd number
-- of ``` fences appear above it. Used to skip false heading matches
-- (like a `# comment` inside a shell code block).
function M.in_code_fence(bufnr, line_nr)
  local count = 0
  for l = 1, line_nr - 1 do
    if M.get_line(bufnr, l):match("^```") then
      count = count + 1
    end
  end
  return count % 2 == 1
end

return M
