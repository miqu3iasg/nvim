-- lua/plugins/lsp.lua

local function root(patterns, single_file)
  local function match(name)
    for _, p in ipairs(patterns) do
      if p:sub(1, 1) == "*" then
        if name:sub(-(#p - 1)) == p:sub(2) then
          return true
        end
      elseif name == p then
        return true
      end
    end
    return false
  end

  return function(bufnr, on_dir)
    local found = vim.fs.root(bufnr, match)
    if found then
      on_dir(found)
    elseif single_file then
      on_dir(vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
    end
  end
end

-- Resolves the Python interpreter for pyright. An active VIRTUAL_ENV wins,
-- then a virtual environment inside the workspace (.venv, venv, env, .env),
-- then the python3 found on PATH
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

return {
  {
    "mason-org/mason.nvim",
    config = function()
      require("mason").setup({
        PATH = "prepend",
      })
    end,
  },

  {
    "mason-org/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        -- Servers are enabled explicitly in the nvim-lspconfig block below
        automatic_enable = false,
        ensure_installed = {
          "bashls",
          "omnisharp",
          "lua_ls",
          "gopls",
          "nim_langserver",
          "templ",
          "jdtls",
          "html",
          "cssls",
          "emmet_language_server",
          "tailwindcss",
          "vtsls",
          "eslint",
          "tinymist",
          "pyright",
          "ruff",
          "clangd",
          "prismals",
          "yamlls",
          "jsonls",
          "marksman",
          "texlab",
        },
      })
    end,
  },

  -- Precise Neovim/Lua API support for lua_ls. It also manages the lua_ls
  -- workspace library, so none is configured by hand below
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library",    words = { "vim%.uv" } },
        { path = "${3rd}/love2d/library", words = { "love%." } },
      },
    },
  },

  -- Provides schemas for jsonls and yamlls
  {
    "b0o/schemastore.nvim",
    lazy = true,
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Applied to every server
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- clang-tidy only produces diagnostics
      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy=false",
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
        root_dir = root({
          "compile_commands.json",
          "compile_flags.txt",
          ".clangd",
          "CMakeLists.txt",
          "Makefile",
          ".git",
        }, true),
        init_options = { fallbackFlags = { "-std=c++2a" } },
      })

      -- staticcheck and the extra analyzers only produce diagnostics
      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            gofumpt = true,
            staticcheck = false,
            usePlaceholders = true,
            completeUnimported = true,
            analyses = {
              unusedparams = false,
              shadow = false,
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

      -- Roslyn analyzers only produce diagnostics. Import completion and
      -- organize-imports on format stay enabled
      vim.lsp.config("omnisharp", {
        cmd = { "OmniSharp" },
        settings = {
          FormattingOptions = {
            OrganizeImports = true,
          },
          RoslynExtensionsOptions = {
            EnableAnalyzersSupport = false,
            EnableImportCompletion = true,
            AnalyzeOpenDocumentsOnly = true,
          },
        },
      })

      vim.lsp.config("cmake", {
        cmd = {
          vim.fn.expand("~/.local/share/cmake-language-server/bin/cmake-language-server"),
        },
      })

      -- Diagnostics are disabled entirely. Inlay hints stay on
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              enable = true,
            },
            workspace = {
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
            hint = {
              enable = true,
            },
          },
        },
      })

      -- Type checking only produces diagnostics, so it is turned off. Hover,
      -- completion and navigation keep working. Only open files are analyzed
      -- instead of the whole workspace
      vim.lsp.config("pyright", {
        before_init = function(_, config)
          config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
            python = { pythonPath = get_python_path(config.root_dir) },
          })
        end,
        settings = {
          python = {
            pythonPath = get_python_path(),
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
              typeCheckingMode = "off",
            },
          },
        },
      })

      -- Hover is left to pyright. If ruff is only used as a formatter, linting
      -- can also be turned off with
      -- init_options = { settings = { lint = { enable = false } } }
      vim.lsp.config("ruff", {
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      })

      -- Schemas are kept for completion, but validation is disabled because
      -- it only produces diagnostics. The same applies to yamlls and cssls
      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = false },
          },
        },
      })

      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            validate = false,
            schemaStore = {
              -- schemastore.nvim is used instead of the built-in store
              enable = false,
              url = "",
            },
            schemas = require("schemastore").yaml.schemas(),
          },
        },
      })

      vim.lsp.config("cssls", {
        settings = {
          css = { validate = false },
          scss = { validate = false },
          less = { validate = false },
        },
      })

      vim.lsp.config("html", {
        filetypes = { "templ", "html", "php" },
      })

      -- TypeScript / JavaScript. vtsls replaces ts_ls: it handles large
      -- monorepos better and exposes extra commands (go to source definition,
      -- move to file, etc). Never enable ts_ls together with it, or every
      -- diagnostic and completion shows up twice
      local function ts_settings()
        return {
          updateImportsOnFileMove = { enabled = "always" },
          suggest = { completeFunctionCalls = true },


          preferences = {
            -- Use "non-relative" if the project relies on path aliases (@/...)
            importModuleSpecifier = "shortest",

            preferTypeOnlyAutoImports = true,
          },
          inlayHints = {
            parameterNames = { enabled = "literals" },
            parameterTypes = { enabled = false },
            variableTypes = { enabled = false },
            propertyDeclarationTypes = { enabled = true },
            functionLikeReturnTypes = { enabled = true },
            enumMemberValues = { enabled = true },
          },
        }
      end

      vim.lsp.config("vtsls", {
        commands = {
          ["_typescript.didOrganizeImports"] = function() end,
        },
        settings = {
          typescript = vim.tbl_deep_extend("force", ts_settings(), {
            tsserver = { maxTsServerMemory = 8192 },
          }),
          javascript = ts_settings(),
          vtsls = {
            autoUseWorkspaceTsdk = true,
            experimental = {
              maxInlayHintLength = 30,
              completion = { enableServerSideFuzzyMatch = false },
            },
          },
        },
      })

      -- ESLint diagnostics and fixes. Formatting stays with conform/prettier,
      -- so the server's own formatter is off. Fixes on save are wired in the
      -- LspAttach autocmd below
      vim.lsp.config("eslint", {
        settings = {
          format = false,
        },
      })

      -- Runs `LspEslintFixAll` before conform formats the buffer (the autocmd
      -- is created on attach, so it is registered before conform's). Respects
      -- the same toggles as autoformat (<leader>uf)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("EslintFixOnSave", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "eslint" then
            return
          end
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = args.buf,
            callback = function()
              if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
                return
              end
              if vim.fn.exists(":LspEslintFixAll") == 2 then
                vim.cmd("silent! LspEslintFixAll")
              end
            end,
          })
        end,
      })

      -- Emmet only where markup lives. Plain .js/.ts files get no emmet noise
      vim.lsp.config("emmet_language_server", {
        filetypes = {
          "templ",
          "html",
          "css",
          "scss",
          "php",
          "javascriptreact",
          "typescriptreact",
        },
        init_options = {
          showExpandedAbbreviation = "always",
          showAbbreviationSuggestions = true,
        },
      })

      vim.lsp.config("tailwindcss", {
        filetypes = {
          "templ",
          "html",
          "css",
          "javascriptreact",
          "typescriptreact",
        },
        settings = {
          tailwindCSS = {
            includeLanguages = { templ = "html" },
            -- Class detection inside helper calls: cn("..."), cva("..."), etc.
            classFunctions = { "cn", "clsx", "cx", "cva", "tv", "twMerge" },
          },
        },
        root_dir = root({
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
          ".git",
        }, false),
      })

      vim.lsp.config("templ", {
        filetypes = { "templ" },
      })

      vim.lsp.config("texlab", {
        settings = {
          texlab = {
            completion = {
              -- Fuzzy, case-insensitive matching instead of the default prefix
              -- matcher. Abbreviations such as "thm" and "eqn" then surface
              -- completions like "\theorem" and "\begin{equation}", which keeps
              -- texlab consistent with blink.cmp's other fuzzy sources (buffer,
              -- ripgrep and VimTeX)
              matcher = "fuzzy-ignore-case",
            },
          },
        },
      })

      vim.lsp.config("tinymist", {
        settings = {
          formatterMode = "typstyle",

          -- One of "onType", "onSave" or "never"
          exportPdf = "onSave",

          -- Keep in sync with pdf_path() in after/ftplugin/typst.lua
          outputPath = "$root/build/$dir/$name",

          -- Highlighting comes from treesitter only.
          semanticTokens = "disable",

          -- Only honored by tinymist versions that support linting
          lint = { enabled = false },
        },
      })

      -- Servers that exist only to produce diagnostics
      vim.lsp.enable({
        "bashls",
        "clangd",
        "cmake",
        "cssls",
        "emmet_language_server",
        "eslint",
        "gopls",
        "html",
        "jsonls",
        "lua_ls",
        "marksman",
        "nil_ls",
        "nim_langserver",
        "ocamllsp",
        "ols",
        "omnisharp",
        "prismals",
        "pyright",
        "ruff",
        "tailwindcss",
        "templ",
        "texlab",
        "tinymist",
        "vtsls",
        "yamlls",
      })
    end,
  },
}
