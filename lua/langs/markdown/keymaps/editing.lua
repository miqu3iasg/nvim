-- lua/langs/markdown/keymaps/editing.lua

local utils = require("langs.markdown.utils")

local M = {}

function M.setup(bufnr)
  -- Break the undo sequence at `,` and `.` in insert mode, so undo
  -- stops at sentence boundaries instead of undoing a whole paragraph
  -- at once.
  utils.map(bufnr, "i", ",", ",<C-g>u", "Break undo sequence at comma")
  utils.map(bufnr, "i", ".", ".<C-g>u", "Break undo sequence at period")

  -- Insert mode bold and italic delimiter pair, cursor centered.
  utils.map(bufnr, "i", "<C-b>", "****<Left><Left>", "Insert bold delimiter pair, cursor centered")
  utils.map(bufnr, "i", "<C-i>", "**<Left>", "Insert italic delimiter pair, cursor centered")

  -- Toggling a delimiter pair. In normal mode it acts on the word
  -- under the cursor, equivalent to viw. In visual mode it acts on
  -- the selection. Restricted to single line selections, since inline
  -- formatting spanning multiple lines is not a well defined
  -- operation in plain markdown.
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

  -- normal! viw<Esc> selects the word under the cursor and, on
  -- leaving visual mode, Neovim sets the '< '> marks as if it were a
  -- manual selection. So toggle_wrap can be reused for both cases.
  local function wrap_word(open, close)
    return function()
      vim.cmd("normal! viw\27")
      toggle_wrap(open, close)
    end
  end

  -- In visual mode the '< '> marks are already correct by the time
  -- the mapping runs, since Neovim always leaves visual mode first.
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
    { key = "mt", open = "==", close = "==", desc = "Highlight" },
    { key = "mm", open = "$",  close = "$",  desc = "Inline math" },
  }

  for _, w in ipairs(inline_wraps) do
    utils.map(bufnr, "n", "<leader>" .. w.key, wrap_word(w.open, w.close), w.desc)
    utils.map(bufnr, "v", "<leader>" .. w.key, wrap_selection(w.open, w.close), w.desc)
  end

  -- Visual mode bold/italic on the same keys as the insert-mode pair
  -- above, but wrapping the selection instead of inserting an empty
  -- pair. NOTE: <C-i> is indistinguishable from <Tab> in most
  -- terminals (they send the same byte); this works reliably in
  -- Neovide or terminals with CSI-u / the Kitty keyboard protocol.
  utils.map(bufnr, "v", "<C-b>", wrap_selection("**", "**"), "Bold selection")
  utils.map(bufnr, "v", "<C-i>", wrap_selection("_", "_"), "Italic selection")

  -- Same idea for inline code and inline math: insert an empty
  -- delimiter pair in insert mode, wrap the selection in visual mode.
  -- <C-e> matches Obsidian's own "inline code" shortcut. <C-l> is
  -- used for math since <C-m> is the same keycode as <CR> in the
  -- terminal and can't be bound separately.
  --
  -- <C-e>'s default insert-mode job (and blink.cmp's default) is
  -- closing/dismissing the completion menu, so this checks for an
  -- open completion menu first and defers to that instead of
  -- clobbering it.
  utils.map(bufnr, "i", "<C-e>", function()
    local ok, blink = pcall(require, "blink.cmp")
    if ok and blink.is_visible and blink.is_visible() then
      blink.hide()
      return ""
    end
    return "``<Left>"
  end, "Insert inline code delimiter pair (or close completion menu)", { expr = true })

  utils.map(bufnr, "i", "<C-l>", "$$<Left>", "Insert inline math delimiter pair, cursor centered")

  utils.map(bufnr, "v", "<C-e>", wrap_selection("`", "`"), "Wrap selection as inline code")
  utils.map(bufnr, "v", "<C-l>", wrap_selection("$", "$"), "Wrap selection as inline math")

  -- Custom inline wrap, asks for the delimiter instead of a fixed
  -- one. Handy for extensions with no dedicated binding, like
  -- footnote markers or a custom highlight syntax.
  utils.map(bufnr, "n", "<leader>mw", function()
    local delim = vim.fn.input("Wrap with, ")
    if delim == "" then return end
    wrap_word(delim, delim)()
  end, "Wrap word with custom delimiter")

  utils.map(bufnr, "v", "<leader>mw", function()
    local delim = vim.fn.input("Wrap with, ")
    if delim == "" then return end
    wrap_selection(delim, delim)()
  end, "Wrap selection with custom delimiter")

  -- Clear formatting, best effort. Strips the most common markdown
  -- delimiter pairs from the line. The line gets padded with a space
  -- on both ends before matching, so delimiters right at the start or
  -- end of the line are still caught. Doesn't handle nested or
  -- overlapping markers perfectly, undoing by hand is more reliable
  -- for that.
  local function clear_formatting_line(line_nr)
    local line = utils.get_line(bufnr, line_nr)
    local padded = " " .. line .. " "
    padded = padded:gsub("%*%*(.-)%*%*", "%1")
    padded = padded:gsub("__(.-)__", "%1")
    padded = padded:gsub("%*(.-)%*", "%1")
    padded = padded:gsub("(%A)_(.-)_(%A)", "%1%2%3")
    padded = padded:gsub("~~(.-)~~", "%1")
    padded = padded:gsub("==(.-)==", "%1")
    padded = padded:gsub("`(.-)`", "%1")
    line = padded:sub(2, -2)
    utils.set_line(bufnr, line_nr, line)
  end

  utils.map(bufnr, "n", "<leader>mf", function()
    clear_formatting_line(vim.fn.line("."))
  end, "Clear formatting")

  utils.map(bufnr, "v", "<leader>mf", function()
    for l = vim.fn.line("'<"), vim.fn.line("'>") do
      clear_formatting_line(l)
    end
  end, "Clear formatting")
end

return M
