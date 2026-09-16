-- lua/langs/markdown/keymaps/lists.lua

local utils = require("langs.markdown.utils")

local M = {}

function M.setup(bufnr)
  local function get_line(n) return utils.get_line(bufnr, n) end
  local function set_line(n, text) utils.set_line(bufnr, n, text) end

  local function toggle_bullet_line(n)
    local line = get_line(n)
    local indent, rest = line:match("^(%s*)(.*)$")
    if rest:match("^[%-%*%+]%s") then
      rest = rest:gsub("^[%-%*%+]%s*", "", 1)
    else
      rest = rest:gsub("^%d+%.%s*", "", 1)
      rest = rest:gsub("^>%s?", "", 1)
      rest = "- " .. rest
    end
    set_line(n, indent .. rest)
  end

  local function toggle_numbered_line(n)
    local line = get_line(n)
    local indent, rest = line:match("^(%s*)(.*)$")
    if rest:match("^%d+%.%s") then
      rest = rest:gsub("^%d+%.%s*", "", 1)
    else
      rest = rest:gsub("^[%-%*%+]%s*", "", 1)
      rest = rest:gsub("^>%s?", "", 1)
      rest = "1. " .. rest
    end
    set_line(n, indent .. rest)
  end

  local function toggle_blockquote_line(n)
    local line = get_line(n)
    local indent, rest = line:match("^(%s*)(.*)$")
    if rest:match("^>%s?") then
      rest = rest:gsub("^>%s?", "", 1)
    else
      rest = "> " .. rest
    end
    set_line(n, indent .. rest)
  end

  local function toggle_checkbox_line(n)
    local line = get_line(n)
    if line:match("%[[xX]%]") then
      set_line(n, (line:gsub("%[[xX]%]", "[ ]", 1)))
    elseif line:match("%[ %]") then
      set_line(n, (line:gsub("%[ %]", "[x]", 1)))
    elseif line:match("^%s*[%-%*%+]%s") then
      set_line(n, (line:gsub("^(%s*[%-%*%+]%s)", "%1[ ] ", 1)))
    else
      local indent, rest = line:match("^(%s*)(.*)$")
      set_line(n, indent .. "- [ ] " .. rest)
    end
  end

  -- Cycles plain paragraph, numbered, bullet, checklist, back to plain.
  local function cycle_list_line(n)
    local line = get_line(n)
    local indent, rest = line:match("^(%s*)(.*)$")
    if rest:match("^[%-%*%+]%s%[[ xX]%]%s") then
      set_line(n, indent .. rest:gsub("^[%-%*%+]%s%[[ xX]%]%s*", "", 1))
    elseif rest:match("^[%-%*%+]%s") then
      set_line(n, indent .. "- [ ] " .. rest:gsub("^[%-%*%+]%s*", "", 1))
    elseif rest:match("^%d+%.%s") then
      set_line(n, indent .. "- " .. rest:gsub("^%d+%.%s*", "", 1))
    else
      set_line(n, indent .. "1. " .. rest)
    end
  end

  local function apply_normal_and_visual(key, fn, desc)
    utils.map(bufnr, "n", "<leader>" .. key, function() fn(vim.fn.line(".")) end, desc)
    utils.map(bufnr, "v", "<leader>" .. key, function()
      for l = vim.fn.line("'<"), vim.fn.line("'>") do fn(l) end
    end, desc)
  end

  apply_normal_and_visual("lb", toggle_bullet_line, "Bullet list")
  apply_normal_and_visual("ln", toggle_numbered_line, "Numbered list")
  apply_normal_and_visual("lq", toggle_blockquote_line, "Blockquote")
  apply_normal_and_visual("lt", toggle_checkbox_line, "Toggle checkbox")
  apply_normal_and_visual("lc", cycle_list_line, "Cycle list type")

  -- Same as <leader>lt above, bound to Ctrl+Enter for a quicker reflex
  utils.map(bufnr, "n", "<C-CR>", function()
    toggle_checkbox_line(vim.fn.line("."))
  end, "Toggle checkbox")

  utils.map(bufnr, "v", "<C-CR>", function()
    for l = vim.fn.line("'<"), vim.fn.line("'>") do
      toggle_checkbox_line(l)
    end
  end, "Toggle checkbox")

  utils.map(bufnr, "n", "<leader>li", ">>", "Indent item")
  utils.map(bufnr, "n", "<leader>lu", "<<", "Unindent item")
  utils.map(bufnr, "v", "<leader>li", ">gv", "Indent item")
  utils.map(bufnr, "v", "<leader>lu", "<gv", "Unindent item")

  -- Moves the current line down or up, swapping with its neighbor.
  -- Useful for reordering list items without cutting and pasting.
  utils.map(bufnr, "n", "<leader>lj", function()
    local n = vim.fn.line(".")
    if n < vim.fn.line("$") then
      vim.cmd("move +1")
    end
  end, "Move list item down")

  utils.map(bufnr, "n", "<leader>lk", function()
    local n = vim.fn.line(".")
    if n > 1 then
      vim.cmd("move -2")
    end
  end, "Move list item up")
end

return M
