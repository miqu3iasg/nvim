-- lua/plugins/lspconfig.lua

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
        -- Servers are enabled explicitly in the nvim-lspconfig block below
        automatic_enable = false,
        ensure_installed = {
          "fortls",
          "bashls",
          "omnisharp",
          "lua_ls",
          "gopls",
          "sqlls",
          "jdtls",
          "templ",
          "html",
          "cssls",
          "emmet_ls",
          "tailwindcss",
          "ts_ls",
          "astro",
          "ols",
          "tinymist",
          "pyright",
          "ruff",
          "clangd",
          "prismals",
          "yamlls",
          "jsonls",
          "marksman",
          "wgsl_analyzer",
          "texlab",
          "intelephense",
          "nim_langserver",
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
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Applied to every server.
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- Diagnostic UI is configured centrally in options.lua

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

      vim.lsp.config("fortls", {
        root_dir = root({ "*.f90" }, true),
      })

      vim.lsp.config("ols", {
        root_dir = root({ "*.odin" }, true),
      })

      vim.lsp.config("cmake", {
        cmd = {
          vim.fn.expand("~/.local/share/cmake-language-server/bin/cmake-language-server"),
        },
      })

      vim.lsp.config("zls", {
        cmd = { "zls" },
      })

      vim.lsp.config("c3_lsp", {
        cmd = { "c3lsp" },
        root_dir = root({ "project.json", "*.c3" }, true),
      })

      vim.lsp.config("purescriptls", {
        settings = {
          purescript = {
            addSpagoSources = true,
          },
        },
      })

      vim.lsp.config("ocamllsp", {
        cmd = { "ocamllsp", "--stdio" },
        filetypes = { "ocaml", "reason" },
        root_dir = root({ "*.opam", "esy.json", "package.json" }, true),
      })

      vim.lsp.config("roc_ls", {
        cmd = { "roc_language_server", "--stdio" },
        filetypes = { "roc" },
      })

      vim.lsp.config("fennel_ls", {
        cmd = { "fennel-ls" },
      })

      vim.lsp.config("rescriptls", {
        cmd = { "rescript-language-server", "--stdio" },
        root_dir = root({ "rescript.json" }, false),
      })

      -- The language server runs from a dedicated Julia environment, which is
      -- instantiated on startup. The linter is disabled because it only
      -- produces diagnostics
      vim.lsp.config("julials", {
        cmd = {
          "julia",
          "--project=" .. vim.fn.expand("~/.julia/environments/lsp/"),
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
            server = LanguageServer.LanguageServerInstance(
              stdin,
              stdout,
              project_path,
              depot_path
            )
            server.runlinter = false
            run(server)
          ]],
        },
        root_dir = root({ "*.jl" }, true),
      })

      -- Diagnostics are disabled entirely. Inlay hints stay on
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              enable = false,
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
      -- instead of the whole workspace.
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

      vim.lsp.config("emmet_ls", {
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

      vim.lsp.config("tailwindcss", {
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
        "astro",
        "bashls",
        "c3_lsp",
        "clangd",
        "cmake",
        "cssls",
        "emmet_ls",
        "fennel_ls",
        "fortls",
        "gleam",
        "gopls",
        "hls",
        "html",
        "intelephense",
        "jsonls",
        "sqlls",
        "lua_ls",
        "marksman",
        "nil_ls",
        "nim_langserver",
        "ocamllsp",
        "ols",
        "omnisharp",
        "prismals",
        "purescriptls",
        "pyright",
        "rescriptls",
        "roc_ls",
        "ruff",
        "tailwindcss",
        "templ",
        "texlab",
        "tinymist",
        "ts_ls",
        "wgsl_analyzer",
        "yamlls",
        "zls",
      })
    end,
  },
}
