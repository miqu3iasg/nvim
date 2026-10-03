-- lua/keymaps/search.lua

local km = vim.keymap.set

-- Scrolling, centered on cursor
km("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center cursor" })
km("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center cursor" })
km("n", "<C-f>", "<C-f>zz", { desc = "Page down and center cursor" })
km("n", "<C-b>", "<C-b>zz", { desc = "Page up and center cursor" })

-- Search navigation, centered on match
-- zv makes sure the match is also unfolded, not just centered
km("n", "n", "nzzzv", { desc = "Next search result, center cursor and open fold" })
km("n", "N", "Nzzzv", { desc = "Previous search result, center cursor and open fold" })
km("n", "*", "*zzzv", { desc = "Search word forward and center cursor" })
km("n", "#", "#zzzv", { desc = "Search word backward and center cursor" })
km("n", "g*", "g*zzzv", { desc = "Search partial word forward and center cursor" })
km("n", "g#", "g#zzzv", { desc = "Search partial word backward and center cursor" })
km("n", "}", "}zz", { desc = "Jump to next paragraph and center cursor" })
km("n", "{", "{zz", { desc = "Jump to previous paragraph and center cursor" })

-- Search visual selection
km("v", "*", [[y/\V<C-r>=escape(@", '/\')<CR><CR>]], { desc = "Search selection forward" })
km("v", "#", [[y?\V<C-r>=escape(@", '/\')<CR><CR>]], { desc = "Search selection backward" })

-- Clears all searching selections, as well as match and hlsearch selections.
km("n", "zh", function()
  vim.cmd("match none")
  vim.cmd("nohlsearch")
end, { desc = "Clear search highlights" })

-- Word search
-- Search/highlight word/WORD under cursor without jumping (properly escaped for regex-special chars)
km("n", "<leader>sw", function()
  local word = vim.fn.escape(vim.fn.expand("<cword>"), "\\/.*$^~[]")
  vim.fn.setreg("/", [[\<]] .. word .. [[\>]])
  vim.o.hlsearch = true
end, { desc = "Search word under cursor" })

km("n", "<leader>sW", function()
  local word = vim.fn.escape(vim.fn.expand("<cWORD>"), "\\/.*$^~[]")
  vim.fn.setreg("/", word)
  vim.o.hlsearch = true
end, { desc = "Search WORD under cursor" })

-- Grep word under cursor across project
-- Requires ripgrep and: vim.o.grepprg = "rg --vimgrep --smart-case"
km("n", "<leader>sg", function()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return
  end
  vim.cmd("silent grep! " .. vim.fn.shellescape(word))
  vim.cmd("copen")
end, { desc = "Grep word under cursor across project (quickfix)" })

-- File/buffer finding and content search
-- Search file names/paths across the project
-- Uses `rg --files`, so it searches files rather than file contents and respects .gitignore.
km("n", "<leader>qf", function()
  if vim.fn.executable("rg") == 0 then
    vim.notify("ripgrep (rg) not found in PATH", vim.log.levels.ERROR)
    return
  end

  local pattern = vim.fn.input("/ ")
  if pattern == "" then
    return
  end

  local files = vim.fn.systemlist({
    "rg",
    "--files",
    "--hidden",
    "--glob",
    "!.git",
  })

  local matches = {}
  for _, file in ipairs(files) do
    if file:lower():find(pattern:lower(), 1, true) then
      table.insert(matches, file)
    end
  end

  if #matches == 0 then
    vim.notify("No files found: " .. pattern, vim.log.levels.WARN)
    return
  end

  local items = {}
  for _, file in ipairs(matches) do
    table.insert(items, { filename = file })
  end

  vim.fn.setqflist({}, " ", {
    title = "Files: " .. pattern,
    items = items,
  })

  vim.cmd("copen")
end, { desc = "Search file names across project (quickfix)" })

-- Grep arbitrary typed text across the whole project (ripgrep, quickfix)
km("n", "<leader>qs", function()
  if vim.fn.executable("rg") == 0 then
    vim.notify("ripgrep (rg) not found in PATH", vim.log.levels.ERROR)
    return
  end

  local pattern = vim.fn.input("/ ")
  if pattern == "" then
    return
  end

  vim.cmd("silent grep! " .. vim.fn.shellescape(pattern))
  vim.cmd("copen")
end, { desc = "Search file contents (quickfix)" })

-- Repeatable "change next occurrence" (search, jump back, change, then `.` repeats)
km("n", "<leader>cn", "*``cgn", { desc = "Change next occurrence of word under cursor (repeat with .)" })
