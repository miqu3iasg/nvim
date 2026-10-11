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
}
