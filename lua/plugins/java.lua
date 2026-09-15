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

  -- Provides an HTTP client inside Neovim for working with .http and
  -- .rest files. It supports the JetBrains HTTP client specification, request
  -- variables, environments, scripting, assertions, and response inspection.
  -- This makes it useful for testing Spring Boot endpoints without leaving
  -- the editor.
  --
  -- curl is used as the HTTP transport, while the kulala-core binary handles
  -- request parsing and execution. The binary is downloaded automatically on
  -- first use. jq and xmllint are optional tools used to format JSON and XML
  -- responses when available on PATH.
  --
  -- The configuration enables environment variables, request execution,
  -- response formatting, a split result interface, LSP integration, and
  -- keymaps for HTTP request buffers and result windows.
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    opts = {
      -- curl executes HTTP requests. The -sS flags suppress the progress meter
      -- while preserving error messages when a request fails.
      curl_path = "curl",
      additional_curl_options = { "-sS" },

      -- Variables are scoped to the current buffer by default. The "g" scope
      -- can be used when variables should be shared globally.
      environment_scope = "b",
      default_env = "dev",

      -- When enabled, Kulala also reads environment variables from
      -- .vscode/settings.json.
      vscode_rest_client_environmentvars = false,

      -- Requests are limited to 30 seconds. Setting this to nil disables the
      -- timeout. When halt_on_error is false, subsequent requests continue
      -- executing even if an earlier request fails.
      request_timeout = 30000,
      halt_on_error = false,

      -- URL parameters are always encoded, and the Content-Type header is
      -- inferred from the request body whenever possible.
      urlencode = "always",
      infer_content_type = true,

      -- Format JSON responses when following HTTP redirects.
      format_json_on_redirect = true,

      -- Client certificates and private keys can be configured per host when
      -- testing local HTTPS or mutual TLS endpoints. The table remains empty
      -- because the current setup does not require client certificates.
      certificates = {
        -- ["localhost:8443"] = {
        --   cert = vim.fn.stdpath("config") .. "/certs/localhost.crt",
        --   key = vim.fn.stdpath("config") .. "/certs/localhost.key",
        -- },
      },

      -- Responses are displayed in a vertical split. The body is the default
      -- view, while the winbar provides access to headers, verbose output,
      -- script output, reports, and help.
      ui = {
        display_mode = "split",
        split_direction = "vertical",

        -- Enable line wrapping in the response window. The buffer and window
        -- options are left otherwise unchanged.
        win_opts = {
          bo = {},
          wo = { wrap = true },
        },

        -- Open the response body by default.
        default_view = "body",

        -- Display the response window's winbar.
        winbar = true,

        -- These views are available through the response window's winbar.
        default_winbar_panes = {
          "body",
          "headers",
          "headers_body",
          "verbose",
          "script_output",
          "report",
          "help",
        },

        -- Display variable information in a floating window.
        show_variable_info_text = "float",

        -- Let Kulala choose whether icons are displayed.
        show_icons = nil,

        -- Show a summary of the executed request.
        show_request_summary = true,

        -- Preserve script print output in the result interface.
        disable_script_print_output = false,

        -- Limit the displayed response size to 64,000 bytes.
        max_response_size = 64000,

        -- Include script output, assertion results, and a request summary in
        -- the generated report.
        report = {
          show_script_output = true,
          show_asserts_output = true,
          show_summary = true,
        },

        -- The scratchpad opens with a sample request targeting a local
        -- Spring Boot application. Replace the host, token, endpoint, and
        -- request body with values appropriate for the API being tested.
        scratchpad_default_contents = {
          "@HOST=http://localhost:8080",
          "@TOKEN=",
          "",
          "# @name scratchpad",
          "POST {{HOST}}/api/example HTTP/1.1",
          "accept: application/json",
          "content-type: application/json",
          "authorization: Bearer {{TOKEN}}",
          "",
          "{",
          '  "foo": "bar"',
          "}",
        },

        -- Disable the news popup shown by Kulala.
        disable_news_popup = true,

        -- Enable Lua syntax highlighting in HTTP scripts.
        lua_syntax_hl = true,
      },

      -- Enable language-server support for HTTP files. Kulala's own keymaps
      -- remain disabled so that Neovim's standard LSP mappings can be used
      -- without being overridden.
      lsp = {
        enable = true,
        keymaps = false,

        -- Sort request metadata and variables, preserve command order, and
        -- format JSON bodies. JSON variables are quoted when necessary.
        formatter = {
          sort = {
            metadata = true,
            variables = true,
            commands = false,
            json = true,
          },
          quote_json_variables = true,
        },
      },

      -- Display errors and warnings while keeping informational and debug
      -- messages disabled. Higher levels add more detailed output.
      debug = 2,

      -- Do not automatically generate bug reports.
      generate_bug_report = false,

      -- Enable global keymaps for .http and .rest buffers. The mappings use
      -- <leader>R as their prefix.
      global_keymaps = true,
      global_keymaps_prefix = "<leader>R",

      -- Enable Kulala's keymaps in the response interface without adding a
      -- prefix to the mappings.
      kulala_keymaps = true,
      kulala_keymaps_prefix = "",
    },
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
