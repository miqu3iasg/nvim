-- lua/keymaps/search.lua

local km = vim.keymap.set

-- Scrolling, centered on cursor
km("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center cursor" })
km("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center cursor" })
km("n", "<C-f>", "<C-f>zz", { desc = "Page down and center cursor" })
km("n", "<C-b>", "<C-b>zz", { desc = "Page up and center cursor" })

-- Search navigation, centered on match
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

-- Word and highlight search
km("n", "<leader>sw", function()
  local word = vim.fn.escape(vim.fn.expand("<cword>"), "\\/.*$^~[]")
  vim.fn.setreg("/", [[\<]] .. word .. [[\>]])
  vim.o.hlsearch = true
end, { desc = "Search word under cursor" })
