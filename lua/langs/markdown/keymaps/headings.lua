-- lua/langs/markdown/keymaps/headings.lua

local utils = require("langs.markdown.utils")

local M = {}

function M.setup(bufnr)
  -- Headings from leader h0 to leader h6. Rewrites the current line,
  -- replacing any existing leading hashes.
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
    utils.map(bufnr, "n", "<leader>h" .. level, set_heading(level), desc)
  end

  -- Increase or decrease the heading level relative to the current
  -- one. Useful when restructuring a document without retyping the
  -- level.
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

  utils.map(bufnr, "n", "<leader>h]", shift_heading(1), "Increase heading level")
  utils.map(bufnr, "n", "<leader>h[", shift_heading(-1), "Decrease heading level")

  -- Heading navigation, next/previous. Skips any line that looks like
  -- a heading but sits inside a fenced code block (e.g. a shell
  -- comment starting with #). O(n) per jump, walking fence state from
  -- the top of the buffer; fine for normal document sizes.
  local function jump_heading(reverse)
    return function()
      local total = vim.api.nvim_buf_line_count(bufnr)
      local step = reverse and -1 or 1
      local l = vim.fn.line(".") + step
      while l >= 1 and l <= total do
        if utils.get_line(bufnr, l):match("^#+%s") and not utils.in_code_fence(bufnr, l) then
          vim.api.nvim_win_set_cursor(0, { l, 0 })
          return
        end
        l = l + step
      end
    end
  end

  utils.map(bufnr, "n", "]]", jump_heading(false), "Next heading")
  utils.map(bufnr, "n", "[[", jump_heading(true), "Previous heading")
end

return M
