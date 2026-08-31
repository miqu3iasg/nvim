-- ~/.config/nvim/ftplugin/markdown.lua
--
-- Keymaps that exist only in markdown buffers. Every vim.keymap.set
-- here uses buffer = true, so none of this leaks into other filetypes.
--
-- Scope is markdown text formatting only. Bold, italic, strikethrough,
-- inline and block code, links, headings, lists, table, horizontal
-- rule, math block. Nothing here depends on Obsidian's own commands
-- or the vim.ob API from Obsidian's Vim plugin. It is all implemented
-- with native Neovim API, so it works the same in any .md file, inside
-- or outside an Obsidian vault.

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = true, silent = true, desc = desc })
end

-- Which key group labels, scoped to the buffer.
-- Wrapped in pcall because ftplugin runs per buffer and which key might
-- not be loaded yet.
do
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<leader>h", group = "Headings", buffer = 0 },
      { "<leader>i", group = "Insert",   buffer = 0 },
      { "<leader>l", group = "Lists",    buffer = 0 },
      { "<leader>m", group = "Markdown", buffer = 0 },
    })
  end
end

-- Headings from leader h0 to leader h6.
-- Rewrites the current line, replacing any existing leading hashes.
local function set_heading(level)
  return function()
    local line = vim.api.nvim_get_current_line()
    local text = line:gsub("^#+%s*", "")
    if level > 0 then
      vim.api.nvim_set_current_line(string.rep("#", level) .. " " .. text)
    else
      vim.api.nvim_set_current_line(text)
    end
  end
end

for level = 0, 6 do
  local desc = level == 0 and "Paragraph, no heading" or ("Heading " .. level)
  map("n", "<leader>h" .. level, set_heading(level), desc)
end

-- Increase or decrease the heading level relative to the current one.
-- Useful when restructuring a document without retyping the level.
local function shift_heading(delta)
  return function()
    local line = vim.api.nvim_get_current_line()
    local hashes, text = line:match("^(#*)%s*(.*)$")
    local level = #hashes + delta
    level = math.max(0, math.min(6, level))
    if level > 0 then
      vim.api.nvim_set_current_line(string.rep("#", level) .. " " .. text)
    else
      vim.api.nvim_set_current_line(text)
    end
  end
end

map("n", "<leader>h]", shift_heading(1), "Increase heading level")
map("n", "<leader>h[", shift_heading(-1), "Decrease heading level")

-- Inline formatting, toggling a delimiter pair.
-- In normal mode it acts on the word under the cursor, equivalent to
-- viw. In visual mode it acts on the selection. Restricted to single
-- line selections, since inline formatting spanning multiple lines
-- is not a well defined operation in plain markdown.
local function toggle_wrap(open, close)
  local sp, ep = vim.fn.getpos("'<"), vim.fn.getpos("'>")
  local s_line, s_col = sp[2], sp[3]
  local e_line, e_col = ep[2], ep[3]

  if s_line ~= e_line then
    vim.notify("Markdown, select a single line to apply inline formatting", vim.log.levels.WARN)
    return
  end

  local line = vim.fn.getline(s_line)
  if e_col > #line then e_col = #line end

  local before = line:sub(1, s_col - 1)
  local selected = line:sub(s_col, e_col)
  local after = line:sub(e_col + 1)

  local ol, cl = #open, #close
  local new_line

  if before:sub(-ol) == open and after:sub(1, cl) == close then
    -- delimiters already hug the selection, remove them
    new_line = before:sub(1, -ol - 1) .. selected .. after:sub(cl + 1)
  elseif #selected >= ol + cl and selected:sub(1, ol) == open and selected:sub(-cl) == close then
    -- selection itself includes the delimiters, remove them
    new_line = before .. selected:sub(ol + 1, -cl - 1) .. after
  else
    -- no delimiters yet, add them
    new_line = before .. open .. selected .. close .. after
  end

  vim.fn.setline(s_line, new_line)
end

-- normal! viw<Esc> selects the word under the cursor and, on leaving
-- visual mode, Neovim sets the '< '> marks as if it were a manual
-- selection. So toggle_wrap can be reused for both cases.
local function wrap_word(open, close)
  return function()
    vim.cmd("normal! viw\27")
    toggle_wrap(open, close)
  end
end

-- In visual mode the '< '> marks are already correct by the time the
-- mapping runs, since Neovim always leaves visual mode first.
local function wrap_selection(open, close)
  return function()
    toggle_wrap(open, close)
  end
end

local inline_wraps = {
  { key = "mb", open = "**", close = "**", desc = "Bold" },
  { key = "mi", open = "_",  close = "_",  desc = "Italic" },
  { key = "ms", open = "~~", close = "~~", desc = "Strikethrough" },
  { key = "mc", open = "`",  close = "`",  desc = "Inline code" },
  { key = "mh", open = "==", close = "==", desc = "Highlight" },
  { key = "mx", open = "$",  close = "$",  desc = "Inline math" },
}

for _, w in ipairs(inline_wraps) do
  map("n", "<leader>" .. w.key, wrap_word(w.open, w.close), w.desc)
  map("v", "<leader>" .. w.key, wrap_selection(w.open, w.close), w.desc)
end

-- Custom inline wrap, asks for the delimiter instead of a fixed one.
-- Handy for extensions with no dedicated binding, like footnote markers
-- or a custom highlight syntax.
map("n", "<leader>mw", function()
  local delim = vim.fn.input("Wrap with, ")
  if delim == "" then return end
  wrap_word(delim, delim)()
end, "Wrap word with custom delimiter")

map("v", "<leader>mw", function()
  local delim = vim.fn.input("Wrap with, ")
  if delim == "" then return end
  wrap_selection(delim, delim)()
end, "Wrap selection with custom delimiter")

-- Clear formatting, best effort. Strips the most common markdown
-- delimiter pairs from the line. The line gets padded with a space on
-- both ends before matching, so delimiters right at the start or end
-- of the line are still caught. Doesn't handle nested or overlapping
-- markers perfectly, undoing by hand is more reliable for that.
local function clear_formatting_line(line_nr)
  local line = vim.api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)[1] or ""
  local padded = " " .. line .. " "
  padded = padded:gsub("%*%*(.-)%*%*", "%1")
  padded = padded:gsub("__(.-)__", "%1")
  padded = padded:gsub("%*(.-)%*", "%1")
  padded = padded:gsub("(%A)_(.-)_(%A)", "%1%2%3")
  padded = padded:gsub("~~(.-)~~", "%1")
  padded = padded:gsub("==(.-)==", "%1")
  padded = padded:gsub("`(.-)`", "%1")
  line = padded:sub(2, -2)
  vim.api.nvim_buf_set_lines(0, line_nr - 1, line_nr, false, { line })
end

map("n", "<leader>mf", function()
  clear_formatting_line(vim.fn.line("."))
end, "Clear formatting")

map("v", "<leader>mf", function()
  for l = vim.fn.line("'<"), vim.fn.line("'>") do
    clear_formatting_line(l)
  end
end, "Clear formatting")

-- Lists, bullet, numbered, blockquote, checkbox, cycle, move up/down.
-- Each operation takes a line number and edits the buffer directly, so
-- the same function serves normal mode, current line, and visual mode,
-- looping over the '< '> range.
local function get_line(n)
  return vim.api.nvim_buf_get_lines(0, n - 1, n, false)[1] or ""
end

local function set_line(n, text)
  vim.api.nvim_buf_set_lines(0, n - 1, n, false, { text })
end

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
  map("n", "<leader>" .. key, function() fn(vim.fn.line(".")) end, desc)
  map("v", "<leader>" .. key, function()
    for l = vim.fn.line("'<"), vim.fn.line("'>") do fn(l) end
  end, desc)
end

apply_normal_and_visual("lb", toggle_bullet_line, "Bullet list")
apply_normal_and_visual("ln", toggle_numbered_line, "Numbered list")
apply_normal_and_visual("lq", toggle_blockquote_line, "Blockquote")
apply_normal_and_visual("lt", toggle_checkbox_line, "Toggle checkbox")
apply_normal_and_visual("lc", cycle_list_line, "Cycle list type")

map("n", "<leader>li", ">>", "Indent item")
map("n", "<leader>lu", "<<", "Unindent item")
map("v", "<leader>li", ">gv", "Indent item")
map("v", "<leader>lu", "<gv", "Unindent item")

-- Moves the current line down or up, swapping with its neighbor.
-- Useful for reordering list items without cutting and pasting.
map("n", "<leader>lj", function()
  local n = vim.fn.line(".")
  if n < vim.fn.line("$") then
    vim.cmd("move +1")
  end
end, "Move list item down")

map("n", "<leader>lk", function()
  local n = vim.fn.line(".")
  if n > 1 then
    vim.cmd("move -2")
  end
end, "Move list item up")

-- Links. Wraps the visual selection as a markdown link, cursor ready
-- inside the parentheses to type the URL.
map("v", "<leader>il", function()
  local sp, ep = vim.fn.getpos("'<"), vim.fn.getpos("'>")
  local s_line, s_col = sp[2], sp[3]
  local e_line, e_col = ep[2], ep[3]

  if s_line ~= e_line then
    vim.notify("Markdown link, select a single line", vim.log.levels.WARN)
    return
  end

  local line = vim.fn.getline(s_line)
  if e_col > #line then e_col = #line end

  local before = line:sub(1, s_col - 1)
  local selected = line:sub(s_col, e_col)
  local after = line:sub(e_col + 1)

  vim.fn.setline(s_line, before .. "[" .. selected .. "]()" .. after)
  vim.api.nvim_win_set_cursor(0, { s_line, #before + #selected + 3 })
  vim.cmd("startinsert")
end, "Wrap selection as markdown link")

-- Normal mode version, no selection needed. Inserts an empty link and
-- leaves the cursor between the brackets to type the text first.
map("n", "<leader>il", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local after = line:sub(col + 1)
  vim.api.nvim_set_current_line(before .. "[]()" .. after)
  vim.api.nvim_win_set_cursor(0, { row, col + 1 })
  vim.cmd("startinsert")
end, "Insert markdown link")

-- One off insertions, horizontal rule, code block, math block, table,
-- callout. All in normal mode, inserting below the current line.
map("n", "<leader>ih", function()
  local row = vim.fn.line(".")
  vim.api.nvim_buf_set_lines(0, row, row, false, { "", "---", "" })
end, "Insert horizontal rule")

map("n", "<leader>ik", function()
  local row = vim.fn.line(".")
  vim.api.nvim_buf_set_lines(0, row, row, false, { "```", "", "```" })
  vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
  vim.cmd("startinsert")
end, "Insert code block")

-- Visual mode counterpart, wraps the selected lines in a fenced block
-- instead of inserting an empty one.
map("v", "<leader>ik", function()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  vim.api.nvim_buf_set_lines(0, end_line, end_line, true, { "```" })
  vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, true, { "```" })
end, "Wrap selection as code block")

map("n", "<leader>im", function()
  local row = vim.fn.line(".")
  vim.api.nvim_buf_set_lines(0, row, row, false, { "$$", "", "$$" })
  vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
  vim.cmd("startinsert")
end, "Insert math block")

-- Simple table skeleton, 2 columns, 1 data row. There is no cell
-- navigation without a plugin.
map("n", "<leader>it", function()
  local row = vim.fn.line(".")
  vim.api.nvim_buf_set_lines(0, row, row, false, {
    "| Column 1 | Column 2 |",
    "| -------- | -------- |",
    "|          |          |",
  })
end, "Insert table skeleton")

-- Obsidian and GFM style callout. Valid syntax anywhere, since it is
-- just a blockquote, but only renders as a special callout in
-- Obsidian, GitHub, and a few others.
map("n", "<leader>ic", function()
  local row = vim.fn.line(".")
  vim.api.nvim_buf_set_lines(0, row, row, false, { "> [!note] ", "> " })
  vim.api.nvim_win_set_cursor(0, { row + 1, 11 })
  vim.cmd("startinsert")
end, "Insert callout, Obsidian and GFM style")

-- Insert mode bold delimiter pair, cursor centered.
vim.keymap.set("i", "<C-b>", "****<Left><Left>", { buffer = true, desc = "Insert bold delimiter pair, cursor centered" })
