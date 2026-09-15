-- lua/langs/java/mason.lua

local M = {}

local ok_registry, mason_registry = pcall(require, "mason-registry")

-- Resolves the installation path of a Mason package, or returns nil if it is not installed.
function M.get_path(pkg)
  if not ok_registry then
    vim.notify("jdtls: mason-registry not found", vim.log.levels.ERROR)
    return nil
  end

  local ok, package = pcall(function()
    return mason_registry.get_package(pkg)
  end)

  if not ok or not package:is_installed() then
    return nil
  end

  return package:get_install_path()
end

return M
