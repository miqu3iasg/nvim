-- lua/langs/java/keymaps.lua

local M = {}

-- Registers jdtls buffer-local keymaps (organize imports, extract var, tests and etc)
function M.attach(jdtls, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  map("n", "<leader>jo", jdtls.organize_imports, "Java: organize imports")
  map("n", "<leader>jv", jdtls.extract_variable, "Java: extract variable")
  map("v", "<leader>jv", function() jdtls.extract_variable(true) end, "Java: extract variable")
  map("n", "<leader>jc", jdtls.extract_constant, "Java: extract constant")
  map("v", "<leader>jc", function() jdtls.extract_constant(true) end, "Java: extract constant")
  map("v", "<leader>jm", function() jdtls.extract_method(true) end, "Java: extract method")

  map("n", "<leader>jtc", jdtls.test_class, "Java: run test class")
  map("n", "<leader>jtn", jdtls.test_nearest_method, "Java: run nearest test")

  map("n", "<leader>ju", "<cmd>JdtUpdateConfig<cr>", "Java: update project configuration (Maven/Gradle)")
end

return M
