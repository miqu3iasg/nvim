-- lua/plugins/java.lua

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = {
      "mfussenegger/nvim-dap",
      { "theHamsta/nvim-dap-virtual-text", opts = {} },
    },
  },
  {
    "elmcgill/springboot-nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "mfussenegger/nvim-jdtls"
    },
    config = function()
      -- gain acces to the springboot nvim plugin and its functions
      local springboot_nvim = require("springboot-nvim")

      -- run the setup function with default configuration
      springboot_nvim.setup({})
    end
  },
}
