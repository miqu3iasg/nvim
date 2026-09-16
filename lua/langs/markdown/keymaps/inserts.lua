-- lua/langs/markdown/keymaps/inserts.lua

local utils = require("langs.markdown.utils")

local M = {}

function M.setup(bufnr)
  utils.map(bufnr, "n", "<leader>ih", function()
    local row = vim.fn.line(".")
    vim.api.nvim_buf_set_lines(bufnr, row, row, false, { "", "---", "" })
  end, "Insert horizontal rule")

  utils.map(bufnr, "n", "<leader>ik", function()
    local row = vim.fn.line(".")
    vim.api.nvim_buf_set_lines(bufnr, row, row, false, { "```", "", "```" })
    vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
    vim.cmd("startinsert")
  end, "Insert code block")

  -- Visual mode counterpart, wraps the selected lines in a fenced
  -- block instead of inserting an empty one.
  utils.map(bufnr, "v", "<leader>ik", function()
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")
    vim.api.nvim_buf_set_lines(bufnr, end_line, end_line, true, { "```" })
    vim.api.nvim_buf_set_lines(bufnr, start_line - 1, start_line - 1, true, { "```" })
  end, "Wrap selection as code block")

  utils.map(bufnr, "n", "<leader>im", function()
    local row = vim.fn.line(".")
    vim.api.nvim_buf_set_lines(bufnr, row, row, false, { "$$", "", "$$" })
    vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
    vim.cmd("startinsert")
  end, "Insert math block")

  -- Simple table skeleton, 2 columns, 1 data row. There is no cell
  -- navigation without a plugin.
  utils.map(bufnr, "n", "<leader>it", function()
    local row = vim.fn.line(".")
    vim.api.nvim_buf_set_lines(bufnr, row, row, false, {
      "| Column 1 | Column 2 |",
      "| -------- | -------- |",
      "|          |          |",
    })
  end, "Insert table skeleton")

  -- Obsidian and GFM style callout. Valid syntax anywhere, since it
  -- is just a blockquote, but only renders as a special callout in
  -- Obsidian, GitHub, and a few others.
  utils.map(bufnr, "n", "<leader>ic", function()
    local row = vim.fn.line(".")
    vim.api.nvim_buf_set_lines(bufnr, row, row, false, { "> [!note] ", "> " })
    vim.api.nvim_win_set_cursor(0, { row + 1, 11 })
    vim.cmd("startinsert")
  end, "Insert callout, Obsidian and GFM style")
end

return M
