-- lua/plugins/java.lua

-- This file contains the plugins used for Java development in Neovim. It
-- provides Java language-server integration and a graphical debugging
-- interface. The language-server setup itself lives in ftplugin/java.lua.
--
-- The required external tools (jdtls, java-debug-adapter, java-test) must be
-- installed separately through Mason.

return {
  -- Integrates Eclipse JDTLS with Neovim and provides Java-specific
  -- language features such as completion, diagnostics, code navigation,
  -- refactoring, and other language-server functionality. It also integrates
  -- with nvim-dap for debugging Java applications.
  --
  -- The plugin is loaded only for Java buffers. The debugging dependencies
  -- provide the core DAP client and a graphical debugging interface.
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = {
      -- nvim-dap provides the Debug Adapter Protocol client used to control
      -- debugging sessions. The keymaps defined in ftplugin/java.lua use its
      -- API to start or continue execution, step through code, and manage
      -- breakpoints.
      "mfussenegger/nvim-dap",

      {
        -- nvim-dap-ui provides a graphical interface for nvim-dap. It displays
        -- variables, scopes, call stacks, breakpoints, and other debugging
        -- information in dedicated Neovim windows.
        --
        -- The interface is opened automatically when a debugging session
        -- starts and closed when the session terminates or the process exits.
        "rcarriga/nvim-dap-ui",

        -- nvim-nio provides the asynchronous I/O functionality required by
        -- nvim-dap-ui.
        dependencies = { "nvim-neotest/nvim-nio" },

        config = function()
          local dap, dapui = require("dap"), require("dapui")

          -- Initialize the debugging interface with its default configuration.
          dapui.setup()

          -- Open the debugging interface after a session is initialized.
          dap.listeners.after.event_initialized["dapui"] = dapui.open

          -- Close the debugging interface when the debugged process terminates.
          dap.listeners.before.event_terminated["dapui"] = dapui.close

          -- Close the debugging interface when the debugged process exits.
          dap.listeners.before.event_exited["dapui"] = dapui.close
        end,
      },
    },
  },
}
