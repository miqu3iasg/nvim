-- lua/langs/java/bundles.lua

local mason = require("langs.java.mason")

local M = {}

--- Builds the java-debug-adapter, java-test and Spring Boot LS bundles, when installed.
function M.build()
  local bundles = {}

  local debug_path = mason.get_path("java-debug-adapter")
  if debug_path then
    vim.list_extend(
      bundles,
      vim.split(
        vim.fn.glob(debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"),
        "\n"
      )
    )
  end

  local test_path = mason.get_path("java-test")
  if test_path then
    vim.list_extend(
      bundles,
      vim.split(vim.fn.glob(test_path .. "/extension/server/*.jar"), "\n")
    )
  end

  -- Spring Boot LS (via lua/plugins/java.lua). The plugin elmcgill/springboot-nvim
  -- exposes the extension jars that need to be added to the jdtls bundles.
  local ok_spring_boot, spring_boot = pcall(require, "spring_boot")
  if ok_spring_boot then
    vim.list_extend(bundles, spring_boot.java_extensions())
  end

  return bundles
end

return M
