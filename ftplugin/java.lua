-- ftplugin/java.lua

-- This module configures every Java buffer: editor options, buffer-local
-- keymaps and a lightweight jdtls (Eclipse JDT Language Server) setup. The
-- language server is used only for code navigation, such as jumping to the
-- declaration of a method, so completion, diagnostics, formatting and other
-- editing features are disabled to keep startup fast and memory usage low.
-- Several features depend on the components listed below being installed.
--
-- nvim-jdtls is the Neovim client for jdtls. It must be declared in
-- `pack.lua` and installed through the plugin manager. The repository is:
-- https://github.com/mfussenegger/nvim-jdtls
--
-- The jdtls server itself is installed through Mason, which must already be
-- set up. From Neovim:
--
-- :MasonInstall jdtls
--
-- This installs the launcher at `~/.local/share/nvim/mason/bin/jdtls` and the
-- package at `~/.local/share/nvim/mason/packages/jdtls`. The package also
-- ships `lombok.jar`, which is loaded as a Java agent when present so that
-- generated members such as getters and builders resolve correctly. The
-- launcher is a Python script, so Python 3 must be available on PATH.
--
-- The server requires JDK 21 or newer to run. On Arch Linux:
--
-- $ sudo pacman -S jdk21-openjdk
--
-- Additional JDKs are optional. Every JDK found in `/usr/lib/jvm`
-- (directories named `java-<version>-openjdk`) is registered as a runtime, so
-- projects can compile against their own Java version, for example:
--
-- $ sudo pacman -S jdk17-openjdk
--
-- The system default JDK is managed with `archlinux-java` and does not need
-- to match the server JDK, because this file points jdtls to the highest
-- installed JDK 21+ through `JAVA_HOME`. To verify the installation:
--
-- $ archlinux-java status
-- $ java -version
--
-- To confirm that the server was installed, open `:Mason` and check that
-- `jdtls` is listed as installed.
--
-- Maven projects are supported out of the box: jdtls imports them through the
-- m2e integration bundled with the server, so no extra plugin is required.
-- The `mvn` command is only needed by the task keymaps when a project has no
-- Maven wrapper (`mvnw`). On Arch Linux:
--
-- $ sudo pacman -S maven
-- $ mvn -v
--
-- Gradle projects are supported as well, but Maven takes precedence when a
-- project root contains both. Because file watching is disabled to save
-- resources, jdtls does not notice changes to `pom.xml` or `build.gradle` on
-- its own. Saving one of these files reloads the project configuration
-- automatically, and `<leader>ju` does the same on demand.
--
-- Each project gets an isolated workspace under
-- `~/.cache/nvim/jdtls-workspace/`, named after the project root. The
-- workspace only holds the index and can be deleted safely. If jdtls fails to
-- start, for example because of a corrupted workspace, `<leader>jW` stops the
-- server, wipes the current project's workspace and restarts it.
--
-- See: https://github.com/mfussenegger/nvim-jdtls
-- See: https://github.com/eclipse-jdtls/eclipse.jdt.ls
-- See: :h lsp

---@class JavaJdk
---@field name string Java execution environment identifier advertised to jdtls.
---@field path string Filesystem path to the JDK installation.

---@alias JavaTask "run"|"test"|"build"

local jdtls = require("jdtls")
local opt = vim.opt_local
local mason = vim.fn.stdpath("data") .. "/mason"
local pkg = mason .. "/packages"

-- Options
opt.wrap = false
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = -1
opt.textwidth = 120
opt.colorcolumn = "120"
opt.spell = false
opt.formatoptions:remove("t")
opt.formatoptions:append({ "r", "o" })
opt.suffixesadd:append(".java")

---Create a buffer-local keymap.
---@param mode string|string[] Mode or list of modes the mapping applies to.
---@param lhs string Key sequence to map.
---@param rhs string|fun() Mapping target, either a command or a callback.
---@param desc string Human-readable description shown by Neovim.
---@param opts? table Extra mapping options merged over the defaults.
---@return nil
local function map(mode, lhs, rhs, desc, opts)
	vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { buffer = true, silent = true, desc = desc }, opts or {}))
end

-- Editing
map("n", "<leader>jd", function()
	local row = vim.fn.line(".")
	local indent = vim.fn.getline(row):match("^%s*")
	vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { indent .. "/**", indent .. " * ", indent .. " */" })
	vim.api.nvim_win_set_cursor(0, { row + 1, #indent + 3 })
	vim.cmd("startinsert!")
end, "Java: insert Javadoc above")

map("n", "<leader>;", "mzA;<Esc>`z", "Java: append semicolon")

---Open the counterpart of the current file, switching between
---`src/main/.../Foo.java` and `src/test/.../FooTest.java`.
---@return nil
local function toggle_test()
	local path = vim.api.nvim_buf_get_name(0)
	local target
	if path:match("Test%.java$") then
		target = path:gsub("/src/test/", "/src/main/"):gsub("Test%.java$", ".java")
	else
		target = path:gsub("/src/main/", "/src/test/"):gsub("%.java$", "Test.java")
	end
	if vim.uv.fs_stat(target) then
		vim.cmd.edit({ args = { target } })
	else
		vim.notify("Not found: " .. target, vim.log.levels.WARN)
	end
end

map("n", "<leader>jT", toggle_test, "Java: toggle source/test file")

if vim.fn.isdirectory(pkg .. "/jdtls") == 0 then
	vim.notify("Run :MasonInstall jdtls", vim.log.levels.WARN)
	return
end

---@type string
local jvm_dir = "/usr/lib/jvm"

---Installed JDK paths indexed by major version, discovered from `jvm_dir`.
---@type table<integer, string>
local installed = {}

if vim.fn.isdirectory(jvm_dir) == 1 then
	for name in vim.fs.dir(jvm_dir) do
		local version = tonumber(name:match("^java%-(%d+)%-openjdk"))
		if version and version >= 8 and version <= 25 then
			installed[version] = jvm_dir .. "/" .. name
		end
	end
end

---@type JavaJdk[]
local runtimes = {}

---JDK used to run the server itself: the highest installed version >= 21.
---@type string?
local server_jdk
local server_version = 0

for version, path in pairs(installed) do
	table.insert(runtimes, { name = version == 8 and "JavaSE-1.8" or ("JavaSE-" .. version), path = path })
	if version >= 21 and version > server_version then
		server_jdk, server_version = path, version
	end
end

if not server_jdk then
	vim.notify("jdtls requires a JDK 21+ in " .. jvm_dir, vim.log.levels.ERROR)
	return
end

---Project root. Decompiled `jdt://` buffers have no path, so they reuse the
---root of the running server instead of spawning a second one.
---@type string
local root = vim.fs.root(0, {
	{ "mvnw", "gradlew", "settings.gradle", "settings.gradle.kts" },
	".git",
	{ "pom.xml", "build.gradle", "build.gradle.kts" },
}) or (vim.lsp.get_clients({ name = "jdtls" })[1] or {}).root_dir or vim.fn.getcwd()

---@type string
local workspace = vim.fn.stdpath("cache")
	.. "/jdtls-workspace/"
	.. vim.fn.sha256(root):sub(1, 8)
	.. "-"
	.. vim.fs.basename(root)

-- Project tasks

---Open a terminal split and run a project task from the detected project root.
---The build tool and task are selected from the project files found at `root`.
---@param action JavaTask Task to execute: application run, tests, or build.
---@return nil
local function build(action)
	---Check whether a project file exists at the project root.
	---@param f string File name relative to the project root.
	---@return boolean `true` when the file exists.
	local function has(f)
		return vim.uv.fs_stat(root .. "/" .. f) ~= nil
	end

	local maven = has("pom.xml") or has("mvnw")
	local gradle = not maven and (has("gradlew") or has("build.gradle") or has("build.gradle.kts"))
	local tool = maven and (has("mvnw") and "./mvnw" or "mvn") or (has("gradlew") and "./gradlew" or "gradle")

	local tasks = {
		run = gradle and "bootRun" or "spring-boot:run",
		test = "test",
		build = gradle and "build -x test" or "clean install -DskipTests",
	}

	vim.cmd(("botright vnew | lcd %s | terminal %s %s"):format(vim.fn.fnameescape(root), tool, tasks[action]))
end

map("n", "<leader>jr", function()
	build("run")
end, "Java: run application")

map("n", "<leader>jt", function()
	build("test")
end, "Java: run tests")

map("n", "<leader>jb", function()
	build("build")
end, "Java: build project")

map("n", "<leader>jo", jdtls.organize_imports, "Java: organize imports")

-- Server

---Stop every running jdtls client.
---@return nil
local function stop_clients()
	for _, c in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
		c:stop()
	end
end

---Stop jdtls, delete this project's workspace and reload the buffer so the
---server restarts from a clean index.
---@return nil
local function wipe_workspace()
	stop_clients()
	vim.wait(2000, function()
		return #vim.lsp.get_clients({ name = "jdtls" }) == 0
	end)
	vim.fn.delete(workspace, "rf")
	vim.notify("Wiped " .. workspace)
	if vim.bo.modified then
		vim.notify("Save the buffer and run :edit to restart jdtls", vim.log.levels.WARN)
	else
		vim.cmd.edit()
	end
end

---Ask the jdtls client that owns the current buffer to reload the project
---configuration (Maven or Gradle). File watching is disabled, so the server
---does not notice changes to `pom.xml` or `build.gradle` on its own.
---@return nil
local function update_project()
	local path = vim.api.nvim_buf_get_name(0)
	for _, c in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
		if c.root_dir and vim.startswith(path, c.root_dir) then
			c:exec_cmd({
				title = "Update project configuration",
				command = "java.projectConfiguration.update",
				arguments = { vim.uri_from_bufnr(0) },
			})
			return
		end
	end
end

vim.api.nvim_create_autocmd("BufWritePost", {
	group = vim.api.nvim_create_augroup("JavaBuildFile", { clear = true }),
	pattern = { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" },
	callback = update_project,
	desc = "Java: reload project configuration when a build file is saved",
})

map("n", "<leader>ju", update_project, "Java: reload Maven/Gradle project")
map("n", "<leader>jL", stop_clients, "Java: stop LSP")
map("n", "<leader>jW", wipe_workspace, "Java: wipe workspace and restart LSP")

---Configure a jdtls client after it attaches to a Java buffer.
---Disables every provider that navigation does not need, so Neovim never
---requests them from the server.
---@param client vim.lsp.Client LSP client attaching to the buffer.
---@return nil
local function on_attach(client)
	for _, provider in ipairs({
		"semanticTokensProvider",
		"completionProvider",
		"signatureHelpProvider",
		"codeLensProvider",
		"inlayHintProvider",
		"documentHighlightProvider",
	}) do
		client.server_capabilities[provider] = nil
	end
end

---@type string[]
local cmd = {
	mason .. "/bin/jdtls",
	"--jvm-arg=-Xmx1g",
	"--jvm-arg=-XX:+UseSerialGC",
	"-data",
	workspace,
}

---@type string
local lombok = pkg .. "/jdtls/lombok.jar"
if vim.uv.fs_stat(lombok) then
	table.insert(cmd, 2, "--jvm-arg=-javaagent:" .. lombok)
end

---Client capabilities without dynamic file watching, which is expensive on
---large repositories.
---@type table
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

---@type table
local config = {
	cmd = cmd,
	cmd_env = { JAVA_HOME = server_jdk },
	root_dir = root,
	capabilities = capabilities,
	on_attach = on_attach,
	flags = { debounce_text_changes = 800 },
	-- Diagnostics are ignored since the server is used for navigation only.
	handlers = { ["textDocument/publishDiagnostics"] = function() end },
	settings = {
		java = {
			autobuild = { enabled = false },
			completion = { enabled = false },
			format = { enabled = false },
			signatureHelp = { enabled = false },
			referencesCodeLens = { enabled = false },
			implementationsCodeLens = { enabled = false },
			maxConcurrentBuilds = 1,
			compile = { nullAnalysis = { mode = "disabled" } },
			configuration = {
				runtimes = runtimes,
				updateBuildConfiguration = "automatic",
			},
			maven = { downloadSources = true },
			project = {
				resourceFilters = {
					"node_modules",
					".git",
					".gradle",
					"target",
					"build",
					"out",
				},
			},
		},
	},
	-- Required for go-to-definition into library classes (jdt:// URIs).
	init_options = {
		extendedClientCapabilities = jdtls.extendedClientCapabilities,
	},
}

jdtls.start_or_attach(config)
