-- lua/plugins/lsp.lua

-- This configuration enables LSP support for frontend development (HTML, CSS,
-- Tailwind CSS, Emmet and TypeScript/JavaScript), LaTeX, Typst and Markdown.
-- Backend language servers are intentionally excluded. Java's `jdtls` is
-- installed through Mason but started separately by another part of the config.
--
-- Mason manages the language servers, but some of them rely on external
-- runtimes and command-line tools. On Arch Linux, install Node.js and npm for
-- the JavaScript-based servers, a JDK for Java, and the Typst CLI and typstyle
-- for Typst compilation and formatting:
--
-- $ sudo pacman -S nodejs npm jdk-openjdk typst typstyle
--
-- Texlab provides LaTeX language-server features. A TeX Live installation is
-- also needed to compile LaTeX documents; the following packages provide the
-- core distribution, LaTeX packages and additional build utilities:
--
-- $ sudo pacman -S texlive-basic texlive-latex texlive-latexextra texlive-binextra
--
-- Install the language servers through Mason. The configuration below
-- automatically requests their installation at startup, but they can also
-- be installed manually with the following command inside Neovim:
--
-- :MasonInstall css-lsp emmet-language-server eslint-lsp html-lsp marksman tailwindcss-language-server texlab tinymist vtsls jdtls
--
-- Marksman handles Markdown navigation, document symbols and diagnostics.
-- Tinymist provides Typst language support and uses `typstyle` for formatting;
-- its PDF export also requires the `typst` executable. Texlab provides LaTeX
-- language support, while the actual compilation depends on the installed TeX
-- tools and packages.
--
-- The LSP servers are configured individually below. `vim.lsp.enable(servers)`
-- enables the servers listed in `servers`, while `jdtls` is deliberately
-- excluded because it is started elsewhere. Mason installation alone does
-- not replace the server-specific configuration in this file.
--
-- See: https://github.com/mason-org/mason.nvim
-- See: https://github.com/mason-org/mason-lspconfig.nvim
-- See: https://github.com/neovim/nvim-lspconfig
-- See: https://github.com/latex-lsp/texlab
-- See: https://github.com/Myriad-Dreamin/tinymist
-- See: https://github.com/artempyanykh/marksman

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
	-- Same root as the other exporters
	-- See: lua/shared/exports.lua
	root_dir = function(bufnr, on_dir)
		on_dir(require("shared.exports").root(bufnr))
	end,
	settings = {
		formatterMode = "typstyle",
		exportPdf = "onSave",
		-- Mirrors exports.output_path(): <root>/exports/<reldir>/<name>
		outputPath = "$root/exports/$dir/$name",
		-- Highlighting comes from treesitter only
		semanticTokens = "disable",
		lint = { enabled = false },
	},
})

-- LSP keymaps, buffer-local and only set once a server attaches
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(ev)
		local fzf = require("fzf-lua")

		local function km(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
		end

		km("n", "gd", fzf.lsp_definitions, "Go to definition")
		km("n", "K", vim.lsp.buf.hover, "Show hover information")
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
		km("n", "grn", vim.lsp.buf.rename, "Rename symbol")
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

vim.lsp.enable(servers)
