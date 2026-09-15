-- lua/langs/java/build.lua

local M = {}

-- Detects the build tool from the project root (cwd). Prefers the wrappers
-- (mvnw/gradlew) over globally installed binaries.
local function build_tool()
  local cwd = vim.fn.getcwd()

  if vim.fn.filereadable(cwd .. "/mvnw") == 1 then
    return "./mvnw", false
  elseif vim.fn.filereadable(cwd .. "/gradlew") == 1 then
    return "./gradlew", true
  elseif vim.fn.filereadable(cwd .. "/pom.xml") == 1 then
    return "mvn", false
  end

  return "gradle", true
end

local function run(cmd)
  local ok, toggleterm = pcall(require, "toggleterm.terminal")
  if not ok then
    vim.notify("toggleterm.nvim not found", vim.log.levels.ERROR)
    return
  end

  local Terminal = toggleterm.Terminal
  local term = Terminal:new({ cmd = cmd, direction = "horizontal", close_on_exit = false })
  term:toggle()
end

--- Runs the application: `mvn spring-boot:run` or `gradle bootRun`.
function M.run_app()
  local tool, is_gradle = build_tool()
  run(tool .. " " .. (is_gradle and "bootRun" or "spring-boot:run"))
end

--- Runs the test suite.
function M.test()
  local tool = build_tool()
  run(tool .. " test")
end

--- Full build, skipping tests.
function M.build_skip_tests()
  local tool, is_gradle = build_tool()
  if is_gradle then
    run(tool .. " build -x test")
  else
    run(tool .. " clean install -DskipTests")
  end
end

--- Registers the build/run/test keymaps, buffer-local.
function M.attach(bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  map("n", "<leader>mr", M.run_app, "Maven/Gradle: run application")
  map("n", "<leader>mt", M.test, "Maven/Gradle: run tests")
  map("n", "<leader>mb", M.build_skip_tests, "Maven/Gradle: build (skip tests)")
end

return M
