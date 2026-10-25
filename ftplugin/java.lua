-- ftplugin/java.lua

local jdtls = require("jdtls")
local mason = vim.fn.stdpath("data") .. "/mason"
local pkg = mason .. "/packages"

if vim.fn.isdirectory(pkg .. "/jdtls") == 0 then
	vim.notify("Run :MasonInstall jdtls", vim.log.levels.WARN)
	return
end

local jdks = {
	{ name = "JavaSE-17", path = "/usr/lib/jvm/java-17-openjdk" },
	{ name = "JavaSE-21", path = "/usr/lib/jvm/java-21-openjdk", default = true },
}

local runtimes = vim.tbl_filter(function(j)
	return vim.fn.isdirectory(j.path) == 1
end, jdks)

local server_jdk = "/usr/lib/jvm/java-21-openjdk"

local root = vim.fs.root(0, {
	{ "mvnw", "gradlew", "settings.gradle", "settings.gradle.kts" },
	".git",
	{ "pom.xml", "build.gradle", "build.gradle.kts" },
}) or vim.fn.getcwd()

local ecc = vim.deepcopy(jdtls.extendedClientCapabilities)
ecc.resolveAdditionalTextEditsSupport = true

local function build(action)
	local function has(f)
		return vim.uv.fs_stat(root .. "/" .. f) ~= nil
	end

	local gradle = has("gradlew") or has("build.gradle") or has("build.gradle.kts")
	local tool = has("mvnw") and "./mvnw" or has("gradlew") and "./gradlew" or (gradle and "gradle" or "mvn")

	local tasks = {
		run = gradle and "bootRun" or "spring-boot:run",
		test = "test",
		build = gradle and "build -x test" or "clean install -DskipTests",
	}

	vim.cmd(("botright vnew | lcd %s | terminal %s %s"):format(vim.fn.fnameescape(root), tool, tasks[action]))
end

local function bmap(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = 0, silent = true, desc = desc })
end

bmap("<leader>jL", function()
	for _, c in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
		c:stop()
	end
end, "Java: stop LSP")

local function on_attach(client, bufnr)
	client.server_capabilities.semanticTokensProvider = nil

	-- client.server_capabilities.completionProvider = nil

	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
	end

	map("<leader>jo", jdtls.organize_imports, "Java: organize imports")
end

local workspace = vim.fn.stdpath("cache")
	.. "/jdtls-workspace/"
	.. vim.fn.sha256(root):sub(1, 8)
	.. "-"
	.. vim.fs.basename(root)

local cmd = {
	mason .. "/bin/jdtls",
	"--jvm-arg=-Xms256m",
	"--jvm-arg=-Xmx1g",
	"--jvm-arg=-XX:+UseParallelGC",
	"--jvm-arg=-XX:GCTimeRatio=4",
	"--jvm-arg=-XX:AdaptiveSizePolicyWeight=90",
	"-data",
	workspace,
}

local lombok = pkg .. "/jdtls/lombok.jar"
if vim.uv.fs_stat(lombok) then
	table.insert(cmd, 2, "--jvm-arg=-javaagent:" .. lombok)
end

local config = {
	cmd = cmd,
	cmd_env = { JAVA_HOME = server_jdk },
	root_dir = root,
	capabilities = require("blink.cmp").get_lsp_capabilities({
		workspace = { didChangeWatchedFiles = { dynamicRegistration = false } },
	}),
	on_attach = on_attach,
	flags = { debounce_text_changes = 800 },
	settings = {
		java = {
			autobuild = { enabled = false },
			format = { enabled = false },
			signatureHelp = { enabled = true, description = { enabled = true } },
			referencesCodeLens = { enabled = false },
			implementationsCodeLens = { enabled = false },
			inlayHints = { parameterNames = { enabled = "none" } },
			references = { includeDecompiledSources = false },
			edit = { validateAllOpenBuffersOnChanges = false },
			configuration = {
				runtimes = runtimes,
				updateBuildConfiguration = "automatic",
			},
			project = {
				outputPath = "out",
				resourceFilters = {
					"node_modules",
					".git",
					".gradle",
					"target",
					"build",
					"out",
				},
			},
			eclipse = { downloadSources = true },
			maven = { downloadSources = true },
			sources = {
				organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
			},
			codeGeneration = {
				toString = {
					template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
				},
				hashCodeEquals = { useJava7Objects = true },
				useBlocks = true,
			},
		},
	},
	init_options = {
		extendedClientCapabilities = ecc,
	},
}

jdtls.start_or_attach(config)
