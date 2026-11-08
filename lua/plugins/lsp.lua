-- lua/plugins/lsp.lua

-- Language servers for frontend development (HTML, CSS, Tailwind CSS, Emmet and
-- TypeScript/JavaScript), LaTeX, Typst and Markdown. Backend language servers
-- are intentionally excluded. Java's `jdtls` is installed through Mason but
-- started separately by the Java ftplugin (see after/ftplugin/java.lua).
--
-- nvim-lspconfig, mason.nvim, mason-lspconfig.nvim and lazydev.nvim must be
-- installed through the plugin manager. Mason manages the language servers, but
-- some of them rely on external runtimes and command-line tools. On Arch Linux,
-- install Node.js and npm for the JavaScript-based servers, a JDK for Java, and
-- the Typst CLI and typstyle for Typst compilation and formatting:
--
-- $ sudo pacman -S nodejs npm jdk-openjdk typst typstyle
--
-- Texlab provides the LaTeX language-server features, but compiling LaTeX
-- documents needs a TeX Live installation. These packages provide the core
-- distribution, LaTeX packages and additional build utilities:
--
-- $ sudo pacman -S texlive-basic texlive-latex texlive-latexextra texlive-binextra
--
-- The configuration requests the installation of the language servers at
-- startup. They can also be installed manually from Neovim:
--
-- :MasonInstall css-lsp emmet-language-server eslint-lsp html-lsp marksman tailwindcss-language-server texlab tinymist vtsls jdtls
--
-- Tinymist uses `typstyle` for formatting, and its PDF export also requires the
-- `typst` executable. Mason only installs the servers, so each one is still
-- configured individually in this file, and only the servers in `servers` are
-- enabled.
--
-- See: lua/shared/exports.lua
-- See: https://github.com/mason-org/mason.nvim
-- See: https://github.com/mason-org/mason-lspconfig.nvim
-- See: https://github.com/neovim/nvim-lspconfig
-- See: https://github.com/folke/lazydev.nvim
-- See: https://github.com/latex-lsp/texlab
-- See: https://github.com/Myriad-Dreamin/tinymist
-- See: https://github.com/artempyanykh/marksman
-- See: :help lsp

local servers = {
	"cssls",
	"emmet_language_server",
	"eslint",
	"html",
	"marksman",
	"tailwindcss",
	"texlab",
	"tinymist",
	"vtsls",
}

require("mason").setup()

-- Only used to install servers, so it can wait until startup is done.
vim.schedule(function()
	require("mason-lspconfig").setup({
		automatic_enable = false,
		ensure_installed = vim.list_extend({ "jdtls" }, servers),
	})
end)

-- Provides the Neovim runtime types to Lua files.
require("lazydev").setup({
	library = {
		{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
		{ path = "${3rd}/love2d/library", words = { "love%." } },
	},
})

-- Disabling dynamic file watching avoids servers registering thousands of
-- watchers in large projects.
vim.lsp.config("*", {
	capabilities = vim.lsp.protocol.make_client_capabilities(),
	workspace = { didChangeWatchedFiles = { dynamicRegistration = false } },
})

-- Validation only produces diagnostics, so it is disabled.
vim.lsp.config("cssls", {
	settings = {
		css = { validate = false },
		scss = { validate = false },
		less = { validate = false },
	},
})

vim.lsp.config("html", {
	filetypes = { "templ", "html", "php" },
})

vim.lsp.config("emmet_language_server", {
	filetypes = { "templ", "html", "css", "scss", "php", "javascriptreact", "typescriptreact" },
})

-- Any folder with a README is a workspace, falling back to the file's directory.
vim.lsp.config("marksman", {
	root_dir = function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, { ".git", "README.md", "README.markdown", ".marksman.toml" })
		on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
	end,
})

-- vtsls replaces ts_ls. Never enable both, or every diagnostic and completion
-- shows up twice.
local ts_shared = {
	updateImportsOnFileMove = { enabled = "always" },
	suggest = { completeFunctionCalls = true },
	preferences = {
		-- Use "non-relative" if the project relies on path aliases (@/...).
		importModuleSpecifier = "shortest",
		preferTypeOnlyAutoImports = true,
	},
	inlayHints = {
		parameterNames = { enabled = "literals" },
		parameterTypes = { enabled = false },
		variableTypes = { enabled = false },
		propertyDeclarationTypes = { enabled = true },
		functionLikeReturnTypes = { enabled = true },
		enumMemberValues = { enabled = true },
	},
}

vim.lsp.config("vtsls", {
	commands = {
		["_typescript.didOrganizeImports"] = function() end,
	},
	settings = {
		typescript = vim.tbl_deep_extend("force", ts_shared, {
			tsserver = { maxTsServerMemory = 8192 },
		}),
		javascript = ts_shared,
		vtsls = { autoUseWorkspaceTsdk = true },
	},
})

-- Formatting stays with conform and prettier, so the server's formatter is off.
vim.lsp.config("eslint", {
	settings = { format = false, run = "onSave" },
})

-- Runs `LspEslintFixAll` before conform formats. The autocmd is created on
-- attach so that it is registered before conform's, and it respects the
-- autoformat toggle.
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("EslintFixOnSave", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client or client.name ~= "eslint" then
			return
		end
		vim.api.nvim_create_autocmd("BufWritePre", {
			-- One group per buffer, so re-attaching replaces the autocmd instead
			-- of stacking it.
			group = vim.api.nvim_create_augroup("EslintFix" .. args.buf, { clear = true }),
			buffer = args.buf,
			callback = function()
				if require("shared.autoformat").enabled(args.buf) then
					vim.cmd("silent! LspEslintFixAll")
				end
			end,
		})
	end,
})

vim.lsp.config("tailwindcss", {
	filetypes = { "templ", "html", "css", "javascriptreact", "typescriptreact" },
	settings = {
		tailwindCSS = {
			includeLanguages = { templ = "html" },
			-- Detects classes inside helper calls such as `cn("...")`.
			classFunctions = { "cn", "clsx", "cx", "cva", "tv", "twMerge" },
		},
	},
})

-- Fuzzy matching lets abbreviations such as "thm" and "eqn" find "\theorem" and
-- "\begin{equation}".
vim.lsp.config("texlab", {
	settings = { texlab = { completion = { matcher = "fuzzy-ignore-case" } } },
})

vim.lsp.config("tinymist", {
	-- Uses the same root as the other exporters.
	root_dir = function(bufnr, on_dir)
		on_dir(require("shared.exports").root(bufnr))
	end,
	settings = {
		formatterMode = "typstyle",
		exportPdf = "onSave",
		-- Mirrors `exports.output_path()`.
		outputPath = require("shared.exports").output_pattern(),
		-- Highlighting comes from treesitter only.
		semanticTokens = "disable",
		lint = { enabled = false },
	},
})

-- Buffer-local mappings set once a server attaches. The native LSP and
-- diagnostic mappings, such as hover, rename and diagnostic navigation, are
-- intentionally not redefined, except where fzf-lua replaces them.
-- See: :help lsp-defaults
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(ev)
		local fzf = require("fzf-lua")

		local function km(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
		end

		km("n", "gd", fzf.lsp_definitions, "Go to definition")
		km("i", "<C-j>", vim.lsp.buf.signature_help, "Signature help")

		km("n", "grp", vim.lsp.buf.signature_help, "Show signature help")
		km("n", "grc", fzf.lsp_declarations, "Go to declaration")
		km("n", "gri", fzf.lsp_implementations, "Go to implementation")
		km("n", "grt", fzf.lsp_typedefs, "Go to type definition")
		km("n", "grr", fzf.lsp_references, "Go to references")
		km("n", "grm", fzf.lsp_document_symbols, "Document symbols")
		km("n", "grw", fzf.lsp_live_workspace_symbols, "Workspace symbols")
		km("n", "grf", fzf.lsp_finder, "LSP finder")
		km("n", "grd", fzf.diagnostics_document, "Document diagnostics")
		km("n", "grD", fzf.diagnostics_workspace, "Workspace diagnostics")
		km({ "n", "v" }, "gra", fzf.lsp_code_actions, "Code action")

		km("n", "grs", function()
			vim.cmd("vsplit")
			vim.lsp.buf.implementation()
		end, "Go to implementation in split")

		km("n", "gro", function()
			vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
		end, "Organize imports")

		km("n", "gre", function()
			vim.diagnostic.open_float({ scope = "cursor" })
		end, "Show diagnostic under cursor")

		km("n", "[e", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end, "Go to previous diagnostic")

		km("n", "]e", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end, "Go to next diagnostic")
	end,
})

vim.diagnostic.config({
	virtual_text = false,
	severity_sort = true,
	underline = true,
	float = { border = vim.o.winborder },
})

vim.lsp.enable(servers)

local lsp_enabled = true

---Enable or disable every language server in `servers` at once. `jdtls` is
---started elsewhere and is deliberately left alone.
---
---Disabling prevents new clients from starting and also stops the ones still
---alive, so their diagnostics are cleared. Enabling starts the servers again and
---re-attaches them to the buffers that are already open.
---@param enable? boolean Forces a state. When omitted, the current state is toggled.
---@return boolean enabled The new state.
local function toggle_lsp(enable)
	if enable == nil then
		lsp_enabled = not lsp_enabled
	else
		lsp_enabled = enable
	end

	if lsp_enabled then
		vim.lsp.enable(servers)
	else
		vim.lsp.enable(servers, false)

		for _, client in ipairs(vim.lsp.get_clients()) do
			if vim.tbl_contains(servers, client.name) then
				client:stop()
			end
		end
	end

	vim.notify("LSP " .. (lsp_enabled and "enabled" or "disabled"), vim.log.levels.INFO)

	return lsp_enabled
end

vim.keymap.set("n", "<leader>ul", function()
	toggle_lsp()
end, { desc = "Toggle LSP" })
