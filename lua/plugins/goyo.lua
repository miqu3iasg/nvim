-- plugins/goyo.lua

return {
  "junegunn/goyo.vim",
  cmd = "Goyo",
  keys = {},
  init = function()
    vim.g.goyo_width = 100
    vim.g.goyo_height = "100%"
    vim.g.goyo_linenr = 0
  end,
  config = function()
    -- local group = vim.api.nvim_create_augroup("GoyoHooks", { clear = true })
  end,
}
