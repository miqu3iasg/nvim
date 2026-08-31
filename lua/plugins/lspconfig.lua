return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        PATH = "prepend",
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        automatic_enable = false,
        ensure_installed = {
          "fortls",
          "bashls",
          "omnisharp",
          "lua_ls",
          "gopls",
          "jdtls",
          "templ",
          "html",
          "cssls",
          "emmet_ls",
          "tailwindcss",
          "ts_ls",
          "astro",
          "ols",
          "pyright",
          "ruff",
          "clangd",
          "prismals",
          "yamlls",
          "jsonls",
          "eslint",
          "marksman",
          "sqlls",
          "wgsl_analyzer",
          "texlab",
          "intelephense",
          "nim_langserver",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local lspconfig = require("lspconfig")
      local util = require("lspconfig").util
      local configs = require("lspconfig.configs")

      -- Diagnostic float / signcolumn friendly UI on hover-like actions
      -- (visual on/off for diagnostics is handled centrally in options.lua)

      lspconfig.cmake.setup({
        capabilities = capabilities,
      })
      lspconfig.fortls.setup({
        capabilities = capabilities,
        root_dir = require("lspconfig").util.root_pattern("*.f90"),
      })
      lspconfig.purescriptls.setup({
        capabilities = capabilities,
        filetypes = { "purescript" },
        settings = {
          purescript = {
            addSpagoSources = true,
          },
        },
        flags = {
          debounce_text_changes = 150,
        },
      })
      lspconfig.ols.setup({
        capabilities = capabilities,
        root_dir = require("lspconfig").util.root_pattern("*.odin"),
      })
      lspconfig.ocamllsp.setup({
        capabilities = capabilities,
        cmd = { "ocamllsp", "--stdio" },
        filetypes = { "ocaml", "reason" },
        root_dir = require("lspconfig").util.root_pattern("*.opam", "esy.json", "package.json"),
      })
      if not configs.roc_ls then
        configs.roc_ls = {
          default_config = {
            cmd = { "roc_language_server", "--stdio" },
            capabilities = capabilities,
            filetypes = {
              "roc",
            },
            single_file_support = true,
          },
        }
      end
      lspconfig.roc_ls.setup({
        capabilities = capabilities,
      })
      lspconfig.astro.setup({
        capabilities = capabilities,
      })
      lspconfig.nil_ls.setup({
        capabilities = capabilities,
      })

      -- SQL
      lspconfig.sqlls.setup({
        capabilities = capabilities,
      })

      lspconfig.intelephense.setup({
        capabilities = capabilities,
      })
      lspconfig.texlab.setup({
        capabilities = capabilities,
      })
      lspconfig.zls.setup({
        capabilities = capabilities,
        cmd = { "zls" },
      })
      lspconfig.hls.setup({
        capabilities = capabilities,
        single_file_support = true,
      })

      -- BASH
      lspconfig.bashls.setup({
        capabilities = capabilities,
      })

      -- LUA
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = {
                vim.api.nvim_get_runtime_file("", true),
                "${3rd}/love2d/library",
              },
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
            hint = {
              enable = true, -- inlay hints (tipos inferidos, nomes de parâmetro)
            },
          },
        },
      })

      lspconfig.wgsl_analyzer.setup({
        capabilities = capabilities,
      })

      -- JSON
      lspconfig.jsonls.setup({
        capabilities = capabilities,
        settings = {
          json = {
            validate = { enable = true },
          },
        },
      })

      -- GO
      lspconfig.gopls.setup({
        capabilities = capabilities,
        settings = {
          gopls = {
            gofumpt = true,
            staticcheck = true,
            usePlaceholders = true,
            completeUnimported = true,
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              constantValues = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      })

      -- CSS
      lspconfig.cssls.setup({
        capabilities = capabilities,
        settings = {
          css = { validate = true },
          scss = { validate = true },
          less = { validate = true },
        },
      })

      lspconfig.prismals.setup({
        capabilities = capabilities,
      })
      lspconfig.yamlls.setup({
        capabilities = capabilities,
      })

      -- HTML
      lspconfig.html.setup({
        capabilities = capabilities,
        single_file_support = true,
        filetypes = {
          "templ",
          "html",
          "php",
        },
      })

      -- EMMET (HTML/CSS/JSX/TSX)
      lspconfig.emmet_ls.setup({
        capabilities = capabilities,
        single_file_support = true,
        filetypes = {
          "templ",
          "html",
          "css",
          "php",
          "javascript",
          "javascriptreact",
          "typescriptreact",
          "typescript",
          "jsx",
          "tsx",
        },
      })

      -- TAILWIND CSS
      lspconfig.tailwindcss.setup({
        capabilities = capabilities,
        filetypes = {
          "templ",
          "html",
          "css",
          "javascriptreact",
          "typescriptreact",
          "javascript",
          "typescript",
          "jsx",
          "tsx",
        },
        root_dir = require("lspconfig").util.root_pattern(
          "tailwind.config.js",
          "tailwind.config.cjs",
          "tailwind.config.mjs",
          "tailwind.config.ts",
          "postcss.config.js",
          "postcss.config.cjs",
          "postcss.config.mjs",
          "postcss.config.ts",
          "package.json",
          "node_modules",
          ".git"
        ),
      })

      lspconfig.templ.setup({
        capabilities = capabilities,
        filetypes = { "templ" },
      })

      -- JAVASCRIPT / TYPESCRIPT
      if not configs.ts_ls then
        configs.ts_ls = {
          default_config = {
            cmd = { "typescript-language-server", "--stdio" },
            capabilities = capabilities,
            filetypes = {
              "javascript",
              "javascriptreact",
              "typescript",
              "typescriptreact",
              "html",
            },
            root_dir = require("lspconfig").util.root_pattern("package.json", "tsconfig.json", ".git"),
            single_file_support = true,
          },
        }
      end
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
      })
      lspconfig.eslint.setup({
        capabilities = capabilities,
      })

      -- C / C++
      lspconfig.clangd.setup({
        cmd = {
          "clangd",
          "--background-index",
          "--pch-storage=memory",
          "--all-scopes-completion",
          "--pretty",
          "--header-insertion=never",
          "-j=4",
          "--inlay-hints",
          "--header-insertion-decorators",
          "--function-arg-placeholders",
          "--completion-style=detailed",
        },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_dir = require("lspconfig").util.root_pattern(
          "compile_commands.json",
          "compile_flags.txt",
          ".clangd",
          "CMakeLists.txt",
          "Makefile",
          ".git"
        ),
        init_options = { fallbackFlags = { "-std=c++2a" } },
        capabilities = capabilities,
        single_file_support = true,
      })

      -- PYTHON
      local function get_python_path(workspace)
        local venv_path = os.getenv("VIRTUAL_ENV")
        if venv_path and venv_path ~= "" then
          return venv_path .. "/bin/python3"
        end

        local cwd = workspace or vim.fn.getcwd()
        local candidates = { ".venv", "venv", "env", ".env" }
        for _, name in ipairs(candidates) do
          local py = cwd .. "/" .. name .. "/bin/python3"
          if vim.fn.executable(py) == 1 then
            return py
          end
        end

        local global_py = vim.fn.exepath("python3")
        if global_py ~= "" then
          return global_py
        end
        return "/usr/bin/python3"
      end

      lspconfig.pyright.setup({
        capabilities = capabilities,
        on_new_config = function(new_config, new_root_dir)
          new_config.settings.python.pythonPath = get_python_path(new_root_dir)
        end,
        settings = {
          python = {
            pythonPath = get_python_path(),
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
              typeCheckingMode = "basic",
            },
          },
        },
      })

      lspconfig.ruff.setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          client.server_capabilities.hoverProvider = false
        end,
      })

      lspconfig.marksman.setup({
        capabilities = capabilities,
      })
      lspconfig.gleam.setup({
        capabilities = capabilities,
      })
      lspconfig.nim_langserver.setup({
        capabilities = capabilities,
      })

      -- C#
      lspconfig.omnisharp.setup({
        capabilities = capabilities,
        cmd = { "OmniSharp" },
        enable_roslyn_analyzers = true,
        organize_imports_on_format = true,
        enable_import_completion = true,
      })
      -- lspconfig.csharp_ls.setup({
      --   capabilities = capabilities,
      -- })

      lspconfig.cmake.setup({
        capabilities = capabilities,
        cmd = {
          os.getenv("HOME")
          .. "/.local/share/cmake-language-server/bin/cmake-language-server",
        },
      })
      lspconfig.fennel_ls.setup({
        capabilities = capabilities,
        cmd = { "fennel-ls" },
      })
      lspconfig.rescriptls.setup({
        capabilities = capabilities,
        cmd = { "rescript-language-server", "--stdio" },
        root_dir = require("lspconfig").util.root_pattern("rescript.json"),
      })

      lspconfig.julials.setup({
        capabilities = capabilities,
        cmd = {
          "julia",
          "--project=" .. "~/.julia/environments/lsp/",
          "--startup-file=no",
          "--history-file=no",
          "-e",
          [[
            using Pkg
            Pkg.instantiate()
            using LanguageServer
        depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
        project_path = let
            dirname(something(
                Base.load_path_expand((
                    p = get(ENV, "JULIA_PROJECT", nothing);
                        p === nothing ? nothing : isempty(p) ? nothing : p
                    )),
                        Base.current_project(),
                        get(Base.load_path(), 1, nothing),
                    Base.load_path_expand("@v#.#"),
                ))
            end
                    @info "Running language server" VERSION pwd() project_path depot_path
                    server = LanguageServer.LanguageServerInstance(stdin, stdout, project_path, depot_path)
        server.runlinter = true
            run(server)
        ]],
        },
        on_attach = function(client, bufnr)
          vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
        end,
        root_dir = require("lspconfig").util.root_pattern("*.jl"),
      })
      lspconfig.c3_lsp.setup({
        capabilities = capabilities,
        cmd = { "c3lsp" },
        root_dir = require("lspconfig").util.root_pattern({ "project.json", "*.c3" }),
      })
    end,
  },
}
