-- /home/miqu3iasg/.config/nvim/lua/plugins/webdevicons.lua
return {
  "nvim-tree/nvim-web-devicons",
  enabled = false,
  config = function()
    require("nvim-web-devicons").setup({})
  end,
  priority = 1000,
}
