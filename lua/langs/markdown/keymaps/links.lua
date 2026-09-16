-- lua/langs/markdown/keymaps/links.lua

local utils = require("langs.markdown.utils")

local M = {}

function M.setup(bufnr)
  -- Wraps the visual selection as a markdown link, cursor ready
  -- inside the parentheses to type the URL.
  utils.map(bufnr, "v", "<leader>il", function()
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

  -- Normal mode version, no selection needed. Inserts an empty link
  -- and leaves the cursor between the brackets to type the text
  -- first.
  utils.map(bufnr, "n", "<leader>il", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local before = line:sub(1, col)
    local after = line:sub(col + 1)
    vim.api.nvim_set_current_line(before .. "[]()" .. after)
    vim.api.nvim_win_set_cursor(0, { row, col + 1 })
    vim.cmd("startinsert")
  end, "Insert markdown link")

  -- Wiki link, Obsidian/Zettelkasten style [[..]]. Same shape as
  -- <leader>il above: normal mode inserts an empty pair with the
  -- cursor between the brackets, visual mode wraps the selection.
  utils.map(bufnr, "n", "<leader>iw", function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local before = line:sub(1, col)
    local after = line:sub(col + 1)
    vim.api.nvim_set_current_line(before .. "[[]]" .. after)
    vim.api.nvim_win_set_cursor(0, { row, col + 2 })
    vim.cmd("startinsert")
  end, "Insert wiki link")

  utils.map(bufnr, "v", "<leader>iw", function()
    local sp, ep = vim.fn.getpos("'<"), vim.fn.getpos("'>")
    local s_line, s_col = sp[2], sp[3]
    local e_line, e_col = ep[2], ep[3]

    if s_line ~= e_line then
      vim.notify("Markdown wiki link, select a single line", vim.log.levels.WARN)
      return
    end

    local line = vim.fn.getline(s_line)
    if e_col > #line then e_col = #line end

    local before = line:sub(1, s_col - 1)
    local selected = line:sub(s_col, e_col)
    local after = line:sub(e_col + 1)

    vim.fn.setline(s_line, before .. "[[" .. selected .. "]]" .. after)
  end, "Wrap selection as wiki link")
end

return M
