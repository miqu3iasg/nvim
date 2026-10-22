-- ftplugin/java.lua

local jdtls = require("jdtls")
local mason = vim.fn.stdpath("data") .. "/mason"
local pkg = mason .. "/packages"

if vim.fn.isdirectory(pkg .. "/jdtls") == 0 then
	vim.notify("Run :MasonInstall jdtls", vim.log.levels.WARN)
	return
end

local jdks = {
	{
		name = "JavaSE-17",
		path = "/usr/lib/jvm/java-17-openjdk",
	},
	{
		name = "JavaSE-21",
		path = "/usr/lib/jvm/java-21-openjdk",
		default = true,
	},
}

local runtimes = vim.tbl_filter(function(j)
	return vim.fn.isdirectory(j.path) == 1
end, jdks)

local server_jdk = "/usr/lib/jvm/java-21-openjdk"

local root = vim.fs.root(0, {
	"mvnw",
	"gradlew",
	"pom.xml",
	"build.gradle",
	"build.gradle.kts",
	".git",
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

local function on_attach(client, bufnr)
	client.server_capabilities.semanticTokensProvider = nil

	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, {
			buffer = bufnr,
			silent = true,
			desc = desc,
		})
	end

	map("<leader>jr", function()
		build("run")
	end, "Java: run")

	map("<leader>jt", function()
		build("test")
	end, "Java: test")

	map("<leader>jb", function()
		build("build")
	end, "Java: build")
end

jdtls.start_or_attach({
	cmd = {
		mason .. "/bin/jdtls",
		"--jvm-arg=-javaagent:" .. pkg .. "/jdtls/lombok.jar",
		"--jvm-arg=-Xms256m",
		"--jvm-arg=-Xmx2g",
		"--jvm-arg=-XX:+UseParallelGC",
		"--jvm-arg=-XX:GCTimeRatio=4",
		"--jvm-arg=-XX:AdaptiveSizePolicyWeight=90",
		"-data",
		vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. vim.fs.basename(root),
	},
	cmd_env = { JAVA_HOME = server_jdk },
	root_dir = root,
	capabilities = require("blink.cmp").get_lsp_capabilities(),
	on_attach = on_attach,
	flags = { debounce_text_changes = 300 },
	settings = {
		java = {
			autobuild = { enabled = false },
			format = { enabled = false },
			signatureHelp = { enabled = false },
			referencesCodeLens = { enabled = false },
			implementationsCodeLens = { enabled = false },
			inlayHints = { parameterNames = { enabled = "none" } },
			references = { includeDecompiledSources = false },
			configuration = {
				runtimes = runtimes,
				updateBuildConfiguration = "automatic",
			},
			eclipse = { downloadSources = false },
			maven = { downloadSources = false },
			sources = {
				organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
			},
			completion = {
				maxResults = 50,
				favoriteStaticMembers = {
					"org.hamcrest.MatcherAssert.assertThat",
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
					"org.junit.jupiter.api.Assertions.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
					"org.mockito.Mockito.*",
				},
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"javax.swing.*",
					"jdk.*",
					"sun.*",
				},
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
})
