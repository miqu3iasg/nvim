local M = {}

local BLOCK_KEYWORDS = {
  "if",
  "elif",
  "else",
  "for",
  "while",
  "def",
  "class",
  "try",
  "except",
  "finally",
  "with",
  "match",
}

local BLOCK_NODES = {
  if_statement = true,
  for_statement = true,
  while_statement = true,
  function_definition = true,
  class_definition = true,
  try_statement = true,
  with_statement = true,
  match_statement = true,
}

local function ends_with_colon(line)
  return vim.trim(line):sub(-1) == ":"
end

local function is_block_keyword(line)
  local trimmed = vim.trim(line)

  for _, keyword in ipairs(BLOCK_KEYWORDS) do
    if trimmed:match("^" .. keyword .. "%f[%W]") then
      return true
    end
  end

  return false
end

local function get_treesitter_node()
  local ok, parser = pcall(vim.treesitter.get_parser, 0, "python")

  if not ok or not parser then
    return nil
  end

  local tree = parser:parse()[1]

  if not tree then
    return nil
  end

  local cursor = vim.api.nvim_win_get_cursor(0)

  return tree:root():named_descendant_for_range(
    cursor[1] - 1,
    cursor[2],
    cursor[1] - 1,
    cursor[2]
  )
end

local function is_inside_block(node)
  while node do
    if BLOCK_NODES[node:type()] then
      return true
    end

    node = node:parent()
  end

  return false
end

local function should_complete(line)
  if vim.trim(line) == "" then
    return false
  end

  if ends_with_colon(line) then
    return true
  end

  if is_block_keyword(line) then
    return true
  end

  local node = get_treesitter_node()

  if node and is_inside_block(node) then
    return true
  end

  return false
end

local function open_new_indented_line()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]

  vim.api.nvim_buf_set_lines(0, row, row, false, { "" })

  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })

  vim.cmd("normal! ==")

  vim.cmd("startinsert")
end

function M.complete_statement()
  local line = vim.api.nvim_get_current_line()

  if not should_complete(line) then
    return
  end

  if not ends_with_colon(line) then
    vim.api.nvim_set_current_line(line .. ":")
  end

  open_new_indented_line()
end

return M
