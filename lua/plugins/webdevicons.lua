-- lua/plugins/webdevicons.lua

return {
  "nvim-tree/nvim-web-devicons",
  enabled = false, -- I don't like icons btw
  config = function()
    require("nvim-web-devicons").setup({})
  end,
  priority = 1000,
}
