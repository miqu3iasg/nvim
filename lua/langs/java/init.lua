-- lua/langs/java/init.lua

local mason = require("langs.java.mason")
local bundles = require("langs.java.bundles")
local keymaps = require("langs.java.keymaps")
local build = require("langs.java.build")
local settings = require("langs.java.settings")

local M = {}

local root_markers = {
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
  ".git",
}

local function get_os_config_dir()
  if vim.fn.has("mac") == 1 then
    return "config_mac"
  elseif vim.fn.has("win32") == 1 then
    return "config_win"
  end
  return "config_linux"
end

local function get_workspace_dir(root_dir)
  local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  return vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. project_name
end

function M.setup()
  local ok_jdtls, jdtls = pcall(require, "jdtls")
  if not ok_jdtls then
    return
  end

  local jdtls_path = mason.get_path("jdtls")
  if not jdtls_path then
    vim.notify(
      "jdtls is not installed. Run :MasonInstall jdtls java-debug-adapter java-test",
      vim.log.levels.WARN
    )
    return
  end

  local launcher_jar =
      vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

  -- The jdtls package installed via Mason already ships with a bundled
  -- lombok.jar. If your version doesn't include one, download lombok.jar
  -- manually and adjust the path below.
  local lombok_jar = jdtls_path .. "/lombok.jar"
  local has_lombok = vim.fn.filereadable(lombok_jar) == 1

  local root_dir = require("jdtls.setup").find_root(root_markers)
  if root_dir == "" then
    root_dir = vim.fn.getcwd()
  end

  local function on_attach(_, bufnr)
    require("jdtls.dap").setup_dap({ hotcodereplace = "auto" })
    require("jdtls.dap").setup_dap_main_class_configs()
    keymaps.attach(jdtls, bufnr)
    build.attach(bufnr)
  end

  local cmd = {
    "java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx1g",
  }

  if has_lombok then
    table.insert(cmd, "-javaagent:" .. lombok_jar)
  else
    vim.notify(
      "lombok.jar not found at " .. jdtls_path .. " — Lombok annotations may fail to resolve.",
      vim.log.levels.WARN
    )
  end

  vim.list_extend(cmd, {
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    "-jar", launcher_jar,
    "-configuration", jdtls_path .. "/" .. get_os_config_dir(),
    "-data", get_workspace_dir(root_dir),
  })

  jdtls.start_or_attach({
    cmd = cmd,

    root_dir = root_dir,
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    on_attach = on_attach,
    settings = settings,
    init_options = {
      bundles = bundles.build(),
      -- Required for the full set of jdtls code actions: generate
      -- constructor, getters/setters, override/implement methods, delegate
      -- methods, move to a new file, etc.
      extendedClientCapabilities = jdtls.extendedClientCapabilities,
    },
  })
end

return M
