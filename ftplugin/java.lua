local ok_jdtls, jdtls = pcall(require, "jdtls")
if not ok_jdtls then
  return
end

local ok_registry, mason_registry = pcall(require, "mason-registry")
if not ok_registry then
  vim.notify("jdtls: mason-registry não encontrado", vim.log.levels.ERROR)
  return
end

local function get_mason_path(pkg)
  local ok, package = pcall(function()
    return mason_registry.get_package(pkg)
  end)
  if not ok or not package:is_installed() then
    return nil
  end
  return package:get_install_path()
end

local jdtls_path = get_mason_path("jdtls")
if not jdtls_path then
  vim.notify(
    "jdtls não instalado. Rode :MasonInstall jdtls java-debug-adapter java-test",
    vim.log.levels.WARN
  )
  return
end

-- OS-specific config directory within the jdtls package
local os_config = "config_linux"
if vim.fn.has("mac") == 1 then
  os_config = "config_mac"
elseif vim.fn.has("win32") == 1 then
  os_config = "config_win"
end

local launcher_jar =
    vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

-- Project root (Maven/Gradle) + workspace isolated by project, stored
-- in the stdpath cache (~/.cache/nvim/jdtls-workspace/<project-name>)
local root_markers = {
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
  ".git",
}
local root_dir = require("jdtls.setup").find_root(root_markers)
if root_dir == "" then
  root_dir = vim.fn.getcwd()
end

local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. project_name

local capabilities = require("blink.cmp").get_lsp_capabilities()

-- debug (java-debug-adapter) and test (java-test) bundles
local bundles = {}

local debug_path = get_mason_path("java-debug-adapter")
if debug_path then
  vim.list_extend(
    bundles,
    vim.split(
      vim.fn.glob(debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"),
      "\n"
    )
  )
end

local test_path = get_mason_path("java-test")
if test_path then
  vim.list_extend(
    bundles,
    vim.split(vim.fn.glob(test_path .. "/extension/server/*.jar"), "\n")
  )
end

local function on_attach(_, bufnr)
  -- needs to run after the client attaches; registers DAP adapters
  -- (main class configs, hot code replace, etc.)
  require("jdtls.dap").setup_dap({ hotcodereplace = "auto" })
  require("jdtls.dap").setup_dap_main_class_configs()

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  map("n", "<leader>jo", jdtls.organize_imports, "Java: organize imports")
  map("n", "<leader>jv", jdtls.extract_variable, "Java: extract variable")
  map("v", "<leader>jv", function() jdtls.extract_variable(true) end, "Java: extract variable")
  map("n", "<leader>jc", jdtls.extract_constant, "Java: extract constant")
  map("v", "<leader>jc", function() jdtls.extract_constant(true) end, "Java: extract constant")
  map("v", "<leader>jm", function() jdtls.extract_method(true) end, "Java: extract method")

  map("n", "<leader>jtc", jdtls.test_class, "Java: rodar classe de teste")
  map("n", "<leader>jtn", jdtls.test_nearest_method, "Java: rodar teste mais próximo")

  map("n", "<leader>ju", "<cmd>JdtUpdateConfig<cr>", "Java: atualizar config do projeto (Maven/Gradle)")
end

local config = {
  cmd = {
    "java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx1g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    "-jar", launcher_jar,
    "-configuration", jdtls_path .. "/" .. os_config,
    "-data", workspace_dir,
  },

  root_dir = root_dir,
  capabilities = capabilities,
  on_attach = on_attach,

  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
      completion = {
        favoriteStaticMembers = {
          "org.junit.jupiter.api.Assertions.*",
          "org.mockito.Mockito.*",
          "java.util.Objects.requireNonNull",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      configuration = {
        updateBuildConfiguration = "interactive",
      },
      format = {
        enabled = true,
        comments = {
          enabled = false,
        },
      },
    },
  },

  init_options = {
    bundles = bundles,
  },
}

jdtls.start_or_attach(config)
