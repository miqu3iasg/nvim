-- keymaps/search.lua
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
-- Search word/WORD under cursor without jumping (properly escaped for regex-special chars)
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

-- Grep word under cursor across project (quickfix)
-- Requires ripgrep and: vim.o.grepprg = "rg --vimgrep --smart-case"
km("n", "<leader>sg", function()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return
  end
  vim.cmd("silent grep! " .. vim.fn.shellescape(word))
  vim.cmd("copen")
end, { desc = "Grep word under cursor across project (quickfix)" })

-- Substitute across all quickfix files (pairs with <leader>sg above)
km("n", "<leader>sr", ":cdo s/<C-r><C-w>//gc | update<Left><Left><Left><Left><Left><Left><Left><Left><Left>",
  { desc = "Substitute across all quickfix files" })

-- File/buffer finding and content search (leader+q)
-- Native fuzzy file/buffer finding (options set in options.lua: wildoptions=pum,fuzzy)
-- Grouped under <leader>q ("quick") — free in the user's keymap, unlike f/o/b/sv/sc
km("n", "<leader>qf", ":find ", { desc = "Find file (fuzzy, native)" })
km("n", "<leader>qb", ":b ", { desc = "Find buffer (fuzzy, native)" })

-- Native content search across files (no ripgrep dependency, unlike <leader>qg below)
km("n", "<leader>qs", function()
  local pattern = vim.fn.input("/ ")
  if pattern == "" then
    return
  end
  local ok, err = pcall(function()
    vim.cmd("silent vimgrep /" .. pattern .. "/j **/*")
  end)
  if not ok then
    vim.notify("vimgrep: " .. tostring(err), vim.log.levels.WARN)
    return
  end
  vim.cmd("copen")
end, { desc = "Search file contents (native vimgrep)" })

-- Grep arbitrary typed text across the whole project (ripgrep, quickfix)
km("n", "<leader>qg", function()
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
end, { desc = "Grep typed text across project (quickfix)" })

-- Substitution (word/WORD, buffer-wide/line-wide)
-- Rebuilt in Lua so the word/WORD is escaped before it ever reaches the
-- substitute pattern (avoids breaking on chars like . * $ ^ ~ [ ] / \).
local function sub_prompt(scope, text, use_boundary)
  if text == "" then
    return
  end
  local pattern = vim.fn.escape(text, "\\/.*$^~[]")
  if use_boundary then
    pattern = [[\<]] .. pattern .. [[\>]]
  end
  local cmd = string.format(":keeppatterns %s/%s//gc", scope, pattern)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, false, true), "n", false)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Left><Left><Left>", true, false, true), "n", false)
end

km("n", "cu", function() sub_prompt("%s", vim.fn.expand("<cword>"), true) end, { desc = "Substitute word in buffer" })
km("n", "cU", function() sub_prompt("%s", vim.fn.expand("<cWORD>"), false) end, { desc = "Substitute WORD in buffer" })
km("n", "cd", function() sub_prompt("s", vim.fn.expand("<cword>"), true) end, { desc = "Substitute word in line" })
km("n", "cD", function() sub_prompt("s", vim.fn.expand("<cWORD>"), false) end, { desc = "Substitute WORD in line" })

-- Repeatable "change next occurrence" (search, jump back, change, then `.` repeats)
km("n", "<leader>cn", "*``cgn", { desc = "Change next occurrence of word under cursor (repeat with .)" })

-- Highlight the word under the cursor
km("n", "<leader>hw", function()
    local word = vim.fn.expand("<cword>")

    if word == "" then
      vim.cmd("match none")
      return
    end

    local pattern = [[\M\<]] .. word .. [[\>]]

    vim.cmd([[match CwordHighlight /]] .. pattern .. [[/]])
    vim.fn.setreg("/", pattern)
    vim.opt.hlsearch = true
  end,
  { desc = "Highlight word under cursor" }
)

-- Buffer-local search (loclist), mirrors the project-wide qs/qg pair above
km("n", "ZS", function()
  vim.cmd([[lvimgrep /\M\<]] .. vim.fn.expand("<cword>") .. [[\>/j %]])
  vim.cmd("lwindow")
end, { desc = "Grep word under cursor in buffer" })

km("n", "ZD", function()
  vim.cmd([[lvimgrep /\M]] .. vim.fn.expand("<cWORD>") .. [[/j %]])
  vim.cmd("lwindow")
end, { desc = "Grep WORD under cursor in buffer" })

km("n", "ZC", function()
  local pattern = vim.fn.input("/ ")
  if pattern == "" then return end
  local ok = pcall(vim.cmd, "lvimgrep /" .. pattern .. "/j %")
  if ok then vim.cmd("lwindow") else vim.notify("No match: " .. pattern, vim.log.levels.WARN) end
end, { desc = "Vimgrep in current buffer" })
