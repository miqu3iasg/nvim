-- lua/langs/sql/statement.lua

-- Statement and selection helpers.

local M = {}

local function blank(lines, i)
  return lines[i] == nil or lines[i]:match("^%s*$") ~= nil
end

-- A statement ends with `;`, `\g` or `\G`. Trailing `--` comments are ignored.
function M.terminated(line)
  local code = line:gsub("%s*%-%-.*$", "")
  return code:match(";%s*$") ~= nil or code:match("\\[gG]%s*$") ~= nil
end

-- Returns the first and last line of the statement under the cursor, or nil
-- on a blank line. A statement is bounded by terminators and blank lines.
function M.under_cursor()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local first = vim.api.nvim_win_get_cursor(0)[1]
  if blank(lines, first) then
    return nil
  end

  local last = first
  while first > 1 and not blank(lines, first - 1) and not M.terminated(lines[first - 1]) do
    first = first - 1
  end
  while last < #lines and not M.terminated(lines[last]) and not blank(lines, last + 1) do
    last = last + 1
  end
  return first, last
end

-- Returns the first and last line of the visual selection and leaves visual mode.
function M.selection()
  local first, last = vim.fn.line("v"), vim.fn.line(".")
  if first > last then
    first, last = last, first
  end
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  return first, last
end

return M
