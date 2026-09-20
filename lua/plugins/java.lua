-- lua/plugins/java.lua

-- This file contains the plugins and configuration used for Java development
-- in Neovim. It provides Java language-server integration, debugging tools,
-- HTTP client support for testing APIs, Spring Boot tooling, and an integrated
-- terminal for running development commands.
--
-- The required external tools and language-server setup must be installed
-- separately on the system.

return {
  -- Integrates Eclipse JDTLS with Neovim and provides Java-specific
  -- language features such as completion, diagnostics, code navigation,
  -- refactoring, and other language-server functionality. It also integrates
  -- with nvim-dap for debugging Java applications.
  --
  -- The plugin is loaded only for Java buffers. The debugging dependencies
  -- provide the core DAP client, a graphical debugging interface, and inline
  -- variable information. The Java debugger must still be configured through
  -- the JDTLS setup.
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    dependencies = {
      -- nvim-dap provides the Debug Adapter Protocol client used to control
      -- debugging sessions. The keymaps below use its API to start or continue
      -- execution, step through code, manage breakpoints, and open the REPL.
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
          dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
          end

          -- Close the debugging interface when the debugged process terminates.
          dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
          end

          -- Close the debugging interface when the debugged process exits.
          dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
          end
        end,
      },

      {
        -- nvim-dap-virtual-text displays runtime information directly beside
        -- the relevant lines of code during debugging. This makes it possible
        -- to inspect variable values without constantly switching to the
        -- debugging interface.
        "theHamsta/nvim-dap-virtual-text",

        config = function()
          -- Enable inline debugging information.
          require("nvim-dap-virtual-text").setup()
        end,
      },
    },

    config = function()
      local dap = require("dap")
      local km = vim.keymap.set

      -- Start a debugging session or continue execution.
      km("n", "<F5>", dap.continue, { desc = "DAP: continue/start" })

      -- Execute the next line without entering function calls.
      km("n", "<F10>", dap.step_over, { desc = "DAP: step over" })

      -- Enter the function called at the current execution point.
      km("n", "<F11>", dap.step_into, { desc = "DAP: step into" })

      -- Finish the current function and return to its caller.
      km("n", "<F12>", dap.step_out, { desc = "DAP: step out" })

      -- Add or remove a breakpoint on the current line.
      km("n", "<leader>db", dap.toggle_breakpoint, {
        desc = "DAP: toggle breakpoint",
      })

      -- Open the debugging REPL for evaluating expressions and inspecting state.
      km("n", "<leader>dr", dap.repl.open, {
        desc = "DAP: open REPL",
      })

      -- Run the last debugging configuration again.
      km("n", "<leader>dl", dap.run_last, {
        desc = "DAP: run last config",
      })
    end,
  },

  -- Adds Spring Boot-specific functionality to Java buffers.
  -- It complements nvim-jdtls with framework-oriented editor features for
  -- projects built with Spring Boot.
  --
  -- nvim-jdtls is declared as a dependency because the plugin relies on Java
  -- language-server integration.
  {
    "elmcgill/springboot-nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "mfussenegger/nvim-jdtls"
    },
    config = function()
      local springboot_nvim = require("springboot-nvim")
      vim.keymap.set('n', '<leader>Jr', springboot_nvim.boot_run, { desc = "Spring Boot Run Project" })
      vim.keymap.set('n', '<leader>Jc', springboot_nvim.generate_class, { desc = "Java Create Class" })
      vim.keymap.set('n', '<leader>Ji', springboot_nvim.generate_interface, { desc = "Java Create Interface" })
      vim.keymap.set('n', '<leader>Je', springboot_nvim.generate_enum, { desc = "Java Create Enum" })
      springboot_nvim.setup({})
    end
  },

  -- Dependency for lua/langs/java/build.lua.
  {
    "akinsho/toggleterm.nvim",

    -- Use the latest available version.
    version = "*",

    -- Load the plugin when one of its commands is executed.
    cmd = { "ToggleTerm", "TermExec" },

    opts = {
      -- Open or close the default terminal with Ctrl+\.
      open_mapping = [[<c-\>]],

      -- Display terminals in a horizontal split.
      direction = "horizontal",

      -- Set the default terminal height to 15 lines.
      size = 15,

      -- Apply shading to terminal windows.
      shade_terminals = true,

      -- Enter insert mode automatically when opening a terminal.
      start_in_insert = true,

      -- Preserve the terminal size between openings.
      persist_size = true,

      -- Keep the terminal window open after the process exits.
      close_on_exit = false,
    },
  },
}
