-- lua/langs/markdown/keymaps/codeblock.lua

local utils = require("langs.markdown.utils")

local M = {}

function M.setup(bufnr)
  utils.map(bufnr, "n", "yc", function()
    local cur = vim.fn.line(".")
    local start_l, end_l

    for l = cur, 1, -1 do
      if utils.get_line(bufnr, l):match("^```") then
        start_l = l + 1
        break
      end
    end
    if not start_l then
      vim.notify("Markdown, cursor is not inside a code block", vim.log.levels.WARN)
      return
    end

    for l = cur, vim.api.nvim_buf_line_count(bufnr) do
      if utils.get_line(bufnr, l):match("^```") then
        end_l = l - 1
        break
      end
    end
    if not end_l or end_l < start_l then
      vim.notify("Markdown, could not find closing fence", vim.log.levels.WARN)
      return
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, start_l - 1, end_l, false)
    vim.fn.setreg("+", table.concat(lines, "\n") .. "\n")
  end, "Yank code block content to clipboard")
end

return M
