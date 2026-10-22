-- lua/plugins/lsp.lua

-- LSP is enabled only for the frontend stack (HTML, CSS, Tailwind, Emmet,
-- TypeScript/JavaScript) plus a few document-format tools (LaTeX, Typst,
-- Markdown). Backend languages (Lua, C, Python, Go, etc.) are intentionally
-- left without an LSP: constant type hints, completions and inline
-- diagnostics make it too easy to skim code without actually reading it.
-- Hover, go-to-definition and rename stay where the structure is mostly
-- declarative.

-- jdtls is installed here but started elsewhere
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

-- Only used to install servers, so it can wait until startup is done
vim.schedule(function()
	require("mason-lspconfig").setup({
		automatic_enable = false,
		ensure_installed = vim.list_extend({ "jdtls" }, servers),
	})
end)

-- Needed for .lua files and configurations
require("lazydev").setup({
	library = {
		{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
		{ path = "${3rd}/love2d/library", words = { "love%." } },
	},
})

-- Applied to every server. Disabling dynamic file watching avoids the
-- server registering thousands of watchers in large projects
vim.lsp.config("*", {
	capabilities = require("blink.cmp").get_lsp_capabilities({
		workspace = { didChangeWatchedFiles = { dynamicRegistration = false } },
	}),
})

-- Validation only produces diagnostics, so it is disabled
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

-- Emmet only where markup lives
vim.lsp.config("emmet_language_server", {
	filetypes = { "templ", "html", "css", "scss", "php", "javascriptreact", "typescriptreact" },
})

-- Notes: any folder with a README is a workspace, falling back to the file's dir
vim.lsp.config("marksman", {
	root_dir = function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, { ".git", "README.md", "README.markdown", ".marksman.toml" })
		on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
	end,
})

-- vtsls replaces ts_ls. Never enable both, or every diagnostic and
-- completion shows up twice
local ts_shared = {
	updateImportsOnFileMove = { enabled = "always" },
	suggest = { completeFunctionCalls = true },
	preferences = {
		-- Use "non-relative" if the project relies on path aliases (@/...)
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

-- Formatting stays with conform/prettier, so the server's formatter is off
vim.lsp.config("eslint", {
	settings = { format = false, run = "onSave" },
})

-- Run `LspEslintFixAll` before conform formats. The autocmd is created on
-- attach so it is registered before conform's. Same toggles as <leader>uf
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("EslintFixOnSave", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client or client.name ~= "eslint" then
			return
		end
		vim.api.nvim_create_autocmd("BufWritePre", {
			-- one group per buffer: re-attaching replaces the autocmd instead of stacking it
			group = vim.api.nvim_create_augroup("EslintFix" .. args.buf, { clear = true }),
			buffer = args.buf,
			callback = function()
				if not (vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat) then
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
			-- Class detection inside helper calls: cn("..."), cva("..."), etc.
			classFunctions = { "cn", "clsx", "cx", "cva", "tv", "twMerge" },
		},
	},
})

-- Fuzzy matching so abbreviations like "thm" and "eqn" find "\theorem" and
-- "\begin{equation}", consistent with blink's other fuzzy sources
vim.lsp.config("texlab", {
	settings = { texlab = { completion = { matcher = "fuzzy-ignore-case" } } },
})

vim.lsp.config("tinymist", {
	settings = {
		formatterMode = "typstyle",
		exportPdf = "onSave",
		-- Keep in sync with pdf_path() in after/ftplugin/typst.lua
		outputPath = "$root/build/$dir/$name",
		-- Highlighting comes from treesitter only
		semanticTokens = "disable",
		lint = { enabled = false },
	},
})

vim.lsp.enable(servers)
