-- lua/langs/markdown/keymaps.lua

local M = {}

local ESC = "\27"

local function visual_range()
  local mode = vim.fn.mode()
  local p1, p2 = vim.fn.getpos("v"), vim.fn.getpos(".")
  local s_line, s_col, e_line, e_col = p1[2], p1[3], p2[2], p2[3]
  if s_line > e_line or (s_line == e_line and s_col > e_col) then
    s_line, s_col, e_line, e_col = e_line, e_col, s_line, s_col
  end
  return mode, s_line, s_col, e_line, e_col
end

local function get_line(bufnr, n)
  return vim.api.nvim_buf_get_lines(bufnr, n - 1, n, false)[1] or ""
end

local function exit_visual()
  vim.cmd("normal! " .. ESC)
end

local function single_line_selection(what)
  local mode, s_line, s_col, e_line, e_col = visual_range()
  exit_visual()

  if s_line ~= e_line then
    vim.notify("Markdown " .. what .. ", select a single line", vim.log.levels.WARN)
    return nil
  end

  local line = vim.fn.getline(s_line)
  if line == "" then return nil end

  if mode == "V" then
    s_col = line:find("%S") or 1
    e_col = #line
  else
    e_col = math.min(e_col, #line)
    -- columns are bytes; extend to the end of a multibyte character
    e_col = e_col + vim.str_utf_end(line, e_col)
  end

  return s_line, line:sub(1, s_col - 1), line:sub(s_col, e_col), line:sub(e_col + 1)
end

-- Finds fenced code blocks (``` or ~~~, optionally indented). Returns
-- a list of { start, stop } line pairs; an unclosed fence runs to EOF.
local function fence_blocks(lines)
  local blocks, open = {}, nil
  for i, line in ipairs(lines) do
    local ch = line:match("^%s*([`~])%1%1")
    if ch then
      if not open then
        open = { start = i, ch = ch }
      elseif ch == open.ch then
        blocks[#blocks + 1] = { start = open.start, stop = i, closed = true }
        open = nil
      end
    end
  end
  if open then
    blocks[#blocks + 1] = { start = open.start, stop = #lines, closed = false }
  end
  return blocks
end

local function block_at(blocks, l)
  for _, b in ipairs(blocks) do
    if l >= b.start and l <= b.stop then
      return b
    end
  end
end

local function is_heading(line)
  local hashes = line:match("^(#+)%s")
  return hashes ~= nil and #hashes <= 6
end

function M.setup(bufnr)
  local function map(mode, lhs, rhs, desc, opts)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", {
      buffer = bufnr,
      silent = true,
      desc = desc,
    }, opts or {}))
  end

  -- Editing

  -- Break the undo sequence at `,` and `.` so undo stops at sentence
  -- boundaries instead of undoing a whole paragraph at once.
  map("i", ",", ",<C-g>u", "Break undo sequence at comma")
  map("i", ".", ".<C-g>u", "Break undo sequence at period")

  -- Empty bold pair in insert mode.
  map("i", "<C-b>", "****<Left><Left>", "Insert bold delimiter pair")

  -- Toggles a delimiter pair around the visual selection (single line
  -- only, multi-line inline formatting isn't well defined in markdown).
  local function toggle_wrap(open, close)
    local mode, s_line, s_col, e_line, e_col = visual_range()
    exit_visual()

    if s_line ~= e_line then
      vim.notify("Markdown, select a single line to apply inline formatting", vim.log.levels.WARN)
      return
    end

    local line = vim.fn.getline(s_line)
    if line == "" then return end

    if mode == "V" then
      -- linewise: wrap the text, not the indentation
      s_col = line:find("%S") or 1
      e_col = #line
    else
      e_col = math.min(e_col, #line)
      -- columns are bytes; extend to the end of a multibyte character
      -- (ã, é, ç...) so it doesn't get cut in half
      e_col = e_col + vim.str_utf_end(line, e_col)
    end

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
      new_line = before .. open .. selected .. close .. after
    end

    vim.fn.setline(s_line, new_line)
  end

  local function wrap(open, close)
    return function() toggle_wrap(open, close) end
  end

  local function wrap_word(open, close)
    return function()
      vim.cmd("normal! viw")
      toggle_wrap(open, close)
    end
  end

  map("x", "<C-b>", wrap("**", "**"), "Bold selection")
  map("x", "<leader>mb", wrap("**", "**"), "Bold selection")
  map("x", "<leader>mi", wrap("_", "_"), "Italic selection")
  map("n", "<leader>mb", wrap_word("**", "**"), "Bold word")
  map("n", "<leader>mi", wrap_word("_", "_"), "Italic word")

  -- Code blocks
  map("n", "<leader>ik", function()
    local row = vim.fn.line(".")
    vim.api.nvim_buf_set_lines(bufnr, row, row, false, { "```", "", "```" })
    vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
    vim.cmd("startinsert")
  end, "Insert code block")

  map("x", "<leader>ik", function()
    local _, s_line, _, e_line = visual_range()
    exit_visual()
    -- bottom fence first so the top insertion doesn't shift it
    vim.api.nvim_buf_set_lines(bufnr, e_line, e_line, false, { "```" })
    vim.api.nvim_buf_set_lines(bufnr, s_line - 1, s_line - 1, false, { "```" })
  end, "Wrap selection as code block")

  map("n", "yc", function()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local block = block_at(fence_blocks(lines), vim.fn.line("."))

    if not block then
      vim.notify("Markdown, cursor is not inside a code block", vim.log.levels.WARN)
      return
    end

    local first = block.start + 1
    local last = block.closed and block.stop - 1 or block.stop
    local content = first <= last and vim.list_slice(lines, first, last) or {}
    vim.fn.setreg("+", table.concat(content, "\n") .. "\n")
  end, "Yank code block content to clipboard")

  -- Links
  map("x", "<leader>il", function()
    local l, before, selected, after = single_line_selection("link")
    if not l then return end
    vim.fn.setline(l, before .. "[" .. selected .. "]()" .. after)
    vim.api.nvim_win_set_cursor(0, { l, #before + #selected + 3 })
    vim.cmd("startinsert")
  end, "Wrap selection as markdown link")

  map("n", "<leader>il", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    vim.api.nvim_set_current_line(line:sub(1, col) .. "[]()" .. line:sub(col + 1))
    vim.api.nvim_win_set_cursor(0, { row, col + 1 })
    vim.cmd("startinsert")
  end, "Insert markdown link")

  -- Wiki link
  map("x", "<leader>iw", function()
    local l, before, selected, after = single_line_selection("wiki link")
    if not l then return end
    vim.fn.setline(l, before .. "[[" .. selected .. "]]" .. after)
  end, "Wrap selection as wiki link")

  map("n", "<leader>iw", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    vim.api.nvim_set_current_line(line:sub(1, col) .. "[[]]" .. line:sub(col + 1))
    vim.api.nvim_win_set_cursor(0, { row, col + 2 })
    vim.cmd("startinsert")
  end, "Insert wiki link")

  -- Checkbox
  local function toggle_checkbox_line(n)
    local line = get_line(bufnr, n)
    local new

    local pre, post = line:match("^(%s*[%-%*%+]%s+%[)[xX](%].*)$")
    if pre then
      new = pre .. " " .. post
    else
      pre, post = line:match("^(%s*[%-%*%+]%s+%[) (%].*)$")
      if pre then
        new = pre .. "x" .. post
      else
        local marker, rest = line:match("^(%s*[%-%*%+]%s+)(.*)$")
        if not marker then
          marker, rest = line:match("^(%s*%d+[%.%)]%s+)(.*)$")
        end
        if marker then
          new = marker .. "[ ] " .. rest
        else
          local indent, text = line:match("^(%s*)(.*)$")
          new = indent .. "- [ ] " .. text
        end
      end
    end

    vim.api.nvim_buf_set_lines(bufnr, n - 1, n, false, { new })
  end

  map("n", "<leader>lt", function()
    toggle_checkbox_line(vim.fn.line("."))
  end, "Toggle checkbox")

  map("x", "<leader>lt", function()
    local _, s_line, _, e_line = visual_range()
    exit_visual()
    for l = s_line, e_line do
      toggle_checkbox_line(l)
    end
  end, "Toggle checkbox")

  -- Movement

  -- Visual-line motion (matters with 'wrap'); a count keeps physical lines.
  map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", "Move down by visual line", { expr = true })
  map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", "Move up by visual line", { expr = true })

  -- Next/previous heading
  local function jump_heading(reverse)
    return function()
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local blocks = fence_blocks(lines)
      local step = reverse and -1 or 1
      local target, moved = vim.fn.line("."), false

      for _ = 1, vim.v.count1 do
        local l, hit = target + step, nil
        while l >= 1 and l <= #lines do
          if is_heading(lines[l]) and not block_at(blocks, l) then
            hit = l
            break
          end
          l = l + step
        end
        if not hit then break end
        target, moved = hit, true
      end

      if moved then
        vim.cmd("normal! m'")
        vim.api.nvim_win_set_cursor(0, { target, 0 })
      end
    end
  end

  map("n", "]]", jump_heading(false), "Next heading")
  map("n", "[[", jump_heading(true), "Previous heading")
end

return M
