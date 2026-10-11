-- ftplugin/java.lua

local jdtls = require("jdtls")
local mason = vim.fn.stdpath("data") .. "/mason"

if vim.fn.isdirectory(mason .. "/packages/jdtls") == 0 then
  vim.notify("Run :MasonInstall jdtls java-debug-adapter java-test vscode-spring-boot-tools", vim.log.levels.WARN)
  return
end

local jdks = {
  { name = "JavaSE-1.8", path = "/usr/lib/jvm/java-8-openjdk" },
  { name = "JavaSE-11",  path = "/usr/lib/jvm/java-11-openjdk" },
  { name = "JavaSE-17",  path = "/usr/lib/jvm/java-17-openjdk" },
  { name = "JavaSE-21",  path = "/usr/lib/jvm/java-21-openjdk", default = true },
}
local runtimes = vim.tbl_filter(function(j) return vim.fn.isdirectory(j.path) == 1 end, jdks)

local server_jdk = "/usr/lib/jvm/java-21-openjdk"

local root = vim.fs.root(0, { "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts", ".git" })
    or vim.fn.getcwd()

local bundles = vim.fn.glob(
  mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true, true)
vim.list_extend(bundles, vim.fn.glob(mason .. "/packages/java-test/extension/server/*.jar", true, true))
vim.list_extend(bundles, require("spring_boot").java_extensions())

local function build(action)
  local function has(f) return vim.uv.fs_stat(root .. "/" .. f) ~= nil end
  local gradle = has("gradlew") or has("build.gradle") or has("build.gradle.kts")
  local tool = has("mvnw") and "./mvnw" or has("gradlew") and "./gradlew" or (gradle and "gradle" or "mvn")
  local tasks = {
    run = gradle and "bootRun" or "spring-boot:run",
    test = "test",
    build = gradle and "build -x test" or "clean install -DskipTests",
  }
  vim.cmd(("botright vnew | lcd %s | terminal %s %s"):format(vim.fn.fnameescape(root), tool, tasks[action]))
end

local function on_attach(_, bufnr)
  local dap = require("dap")
  local widgets = require("dap.ui.widgets")
  require("jdtls.dap").setup_dap({ hotcodereplace = "auto" })
  require("jdtls.dap").setup_dap_main_class_configs()

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  -- Debug
  map("n", "<F5>", dap.continue, "DAP: continue/start")
  map("n", "<F10>", dap.step_over, "DAP: step over")
  map("n", "<F11>", dap.step_into, "DAP: step into")
  map("n", "<F12>", dap.step_out, "DAP: step out")
  map("n", "<leader>db", dap.toggle_breakpoint, "DAP: toggle breakpoint")
  map("n", "<leader>dB", function() dap.set_breakpoint(vim.fn.input("Condition: ")) end, "DAP: conditional breakpoint")
  map("n", "<leader>ds", function() widgets.centered_float(widgets.scopes) end, "DAP: scopes")
  map("n", "<leader>df", function() widgets.centered_float(widgets.frames) end, "DAP: call stack")
  map({ "n", "v" }, "<leader>dh", widgets.hover, "DAP: hover")

  -- Refactor
  map("n", "<leader>jv", jdtls.extract_variable, "Java: extract variable")
  map("v", "<leader>jv", function() jdtls.extract_variable(true) end, "Java: extract variable")
  map("v", "<leader>jm", function() jdtls.extract_method(true) end, "Java: extract method")

  -- Tests
  map("n", "<leader>jtc", jdtls.test_class, "Java: test class")
  map("n", "<leader>jtn", jdtls.test_nearest_method, "Java: nearest test")

  -- Build
  map("n", "<leader>br", function() build("run") end, "Build: run app")
  map("n", "<leader>bt", function() build("test") end, "Build: run tests")
  map("n", "<leader>bb", function() build("build") end, "Build: skip tests")
end

jdtls.start_or_attach({
  cmd = {
    mason .. "/bin/jdtls",
    "--jvm-arg=-javaagent:" .. mason .. "/packages/jdtls/lombok.jar",
    "-data", vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. vim.fs.basename(root),
  },
  cmd_env = { JAVA_HOME = server_jdk },
  root_dir = root,
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
  on_attach = on_attach,
  settings = {
    java = {
      configuration = { runtimes = runtimes },
      sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
    },
  },
  init_options = {
    bundles = bundles,
    extendedClientCapabilities = jdtls.extendedClientCapabilities,
  },
})

vim.api.nvim_create_autocmd("BufWritePre", { buffer = 0, callback = jdtls.organize_imports })
