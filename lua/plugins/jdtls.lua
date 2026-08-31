return {
  "mfussenegger/nvim-jdtls",
  ft = "java",
  dependencies = {
    "mfussenegger/nvim-dap",
    {
      "rcarriga/nvim-dap-ui",
      dependencies = { "nvim-neotest/nvim-nio" },
      config = function()
        local dap, dapui = require("dap"), require("dapui")
        dapui.setup()
        dap.listeners.after.event_initialized["dapui_config"] = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
          dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
          dapui.close()
        end
      end,
    },
    {
      "theHamsta/nvim-dap-virtual-text",
      config = function()
        require("nvim-dap-virtual-text").setup()
      end,
    },
  },
  config = function()
    local dap = require("dap")
    local km = vim.keymap.set

    -- DAP Keymaps
    km("n", "<F5>", dap.continue, { desc = "DAP: continue/start" })
    km("n", "<F10>", dap.step_over, { desc = "DAP: step over" })
    km("n", "<F11>", dap.step_into, { desc = "DAP: step into" })
    km("n", "<F12>", dap.step_out, { desc = "DAP: step out" })
    km("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: toggle breakpoint" })
    km("n", "<leader>dr", dap.repl.open, { desc = "DAP: abrir REPL" })
    km("n", "<leader>dl", dap.run_last, { desc = "DAP: rodar última config" })
  end,
}
