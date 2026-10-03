-- ftplugin/java.lua

-- This file configures and starts the Java language server (Eclipse JDTLS)
-- for every Java buffer. It resolves the Mason-installed tools, builds the
-- server command, registers buffer-local keymaps (debugging, refactoring,
-- tests, and build commands), and attaches the server to the project.

local jdtls = require("jdtls")

-- Root directory of the packages installed through Mason.
local mason = vim.fn.stdpath("data") .. "/mason/packages/"
local jdtls_path = mason .. "jdtls"

-- Abort early when jdtls is not installed.
if vim.fn.isdirectory(jdtls_path) == 0 then
  vim.notify("Run :MasonInstall jdtls java-debug-adapter java-test", vim.log.levels.WARN)
  return
end

-- The closest parent directory containing a build file, a
-- wrapper script, or a git repository. Falls back to the current directory.
local root = vim.fs.root(0, {
  "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts", ".git",
}) or vim.fn.getcwd()

-- Debug and test bundles. They are loaded into jdtls as extensions, which
-- enables debugging and test execution when the packages are installed.
local bundles = {}
vim.list_extend(bundles, vim.fn.glob(
  mason .. "java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true, true))
vim.list_extend(bundles, vim.fn.glob(
  mason .. "java-test/extension/server/*.jar", true, true))

-- Platform-specific jdtls configuration directory.
local os_config = (vim.fn.has("mac") == 1 and "config_mac")
    or (vim.fn.has("win32") == 1 and "config_win")
    or "config_linux"

-- Command used to launch the language server. The Mason jdtls package ships
-- with a bundled lombok.jar; when present, it is enabled as a Java agent so
-- Lombok annotations are resolved correctly.
local cmd = { "java", "-Xmx1g" }
local lombok = jdtls_path .. "/lombok.jar"

if vim.fn.filereadable(lombok) == 1 then
  table.insert(cmd, "-javaagent:" .. lombok)
end

vim.list_extend(cmd, {
  "-Declipse.application=org.eclipse.jdt.ls.core.id1",
  "-Dosgi.bundles.defaultStartLevel=4",
  "-Declipse.product=org.eclipse.jdt.ls.core.product",
  "--add-modules=ALL-SYSTEM",
  "--add-opens", "java.base/java.util=ALL-UNNAMED",
  "--add-opens", "java.base/java.lang=ALL-UNNAMED",
  "-jar", vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
  "-configuration", jdtls_path .. "/" .. os_config,
  -- One workspace per project, stored in Neovim's cache directory.
  "-data", vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. vim.fs.basename(root),
})

-- Returns true when the given file exists in the project root.
local function exists(file)
  return vim.fn.filereadable(root .. "/" .. file) == 1
end

-- Runs a build action (run, test or build) in a native terminal split at the
-- bottom of the screen. Prefers the wrappers (mvnw/gradlew) over globally
-- installed binaries.
local function build(action)
  local tool, gradle
  if exists("mvnw") then
    tool, gradle = "./mvnw", false
  elseif exists("gradlew") then
    tool, gradle = "./gradlew", true
  elseif exists("pom.xml") then
    tool, gradle = "mvn", false
  else
    tool, gradle = "gradle", true
  end

  local tasks = {
    run = gradle and "bootRun" or "spring-boot:run",
    test = "test",
    build = gradle and "build -x test" or "clean install -DskipTests",
  }

  -- Open the split, move into the project root, and run the command.
  vim.cmd("botright 15new | lcd " .. vim.fn.fnameescape(root)
    .. " | terminal " .. tool .. " " .. tasks[action])
  vim.cmd("startinsert")
end

-- Runs when jdtls attaches to a buffer: enables debugging support and
-- registers the buffer-local keymaps.
local function on_attach(_, bufnr)
  -- Register the Java debug adapter and discover the main classes.
  require("jdtls.dap").setup_dap({ hotcodereplace = "auto" })
  require("jdtls.dap").setup_dap_main_class_configs()

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end
  local dap = require("dap")

  -- Debug, start/continue, step over/into/out, and toggle breakpoints.
  map("n", "<F5>", dap.continue, "DAP: continue/start")
  map("n", "<F10>", dap.step_over, "DAP: step over")
  map("n", "<F11>", dap.step_into, "DAP: step into")
  map("n", "<F12>", dap.step_out, "DAP: step out")
  map("n", "<leader>db", dap.toggle_breakpoint, "DAP: toggle breakpoint")

  -- Refactor, organize imports, extract variable and extract method.
  map("n", "<leader>jo", jdtls.organize_imports, "Java: organize imports")

  map({ "n", "v" }, "<leader>jv", function()
    jdtls.extract_variable(vim.fn.mode() == "v")
  end, "Java: extract variable")

  map("v", "<leader>jm", function() jdtls.extract_method(true) end, "Java: extract method")

  -- Tests, run the whole class or the test nearest to the cursor.
  map("n", "<leader>jtc", jdtls.test_class, "Java: test class")
  map("n", "<leader>jtn", jdtls.test_nearest_method, "Java: nearest test")

  -- Build, run the application, run the tests, or build skipping tests.
  map("n", "<leader>br", function() build("run") end, "Build: run app")
  map("n", "<leader>bt", function() build("test") end, "Build: run tests")
  map("n", "<leader>bb", function() build("build") end, "Build: skip tests")
end

-- Start the language server, or attach to an existing one for this project.
jdtls.start_or_attach({
  cmd = cmd,
  root_dir = root,
  capabilities = require("blink.cmp").get_lsp_capabilities(),
  on_attach = on_attach,
  settings = {
    java = {
      sources = {
        -- Never collapse imports into wildcards (import foo.*).
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
    },
  },
  init_options = {
    bundles = bundles,
    -- Required for the full set of jdtls code actions: generate
    -- constructor, getters/setters, override/implement methods, delegate
    -- methods, move to a new file, etc.
    extendedClientCapabilities = jdtls.extendedClientCapabilities,
  },
})

-- Organize imports automatically before saving a Java buffer.
vim.api.nvim_create_autocmd("BufWritePre", {
  buffer = 0,
  callback = jdtls.organize_imports,
})
