-- lua/plugins/lsp.lua

-- LSP is enabled only for the frontend stack (HTML, CSS, Tailwind, Emmet,
-- TypeScript/JavaScript) plus a few document-format tools (Java, LaTeX, Typst).
-- Backend languages (Lua, C, Python, Go, etc.) are intentionally left without
-- an LSP, the constant type hints, completions and inline diagnostics make it
-- too easy to skim code without actually reading it, which gets in the way of
-- understanding what a program really does. Forcing myself to read the code,
-- trace types manually and keep the relevant signatures in my head is the
-- point. Hover, go-to-definition and rename are still useful in markup and
-- documents where the structure is mostly declarative, so those stay.

local function root(patterns, single_file)
	local function match(name)
		for _, p in ipairs(patterns) do
			if p:sub(1, 1) == "*" then
				if name:sub(-(#p - 1)) == p:sub(2) then
					return true
				end
			elseif name == p then
				return true
			end
		end
		return false
	end

	return function(bufnr, on_dir)
		local found = vim.fs.root(bufnr, match)
		if found then
			on_dir(found)
		elseif single_file then
			on_dir(vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
		end
	end
end

return {
	{
		"mason-org/mason.nvim",
		config = function()
			require("mason").setup({
				PATH = "prepend",
			})
		end,
	},

	{
		"mason-org/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				-- Servers are enabled explicitly in the nvim-lspconfig block below
				automatic_enable = false,
				ensure_installed = {
					"jdtls",
					"html",
					"cssls",
					"emmet_language_server",
					"tailwindcss",
					"vtsls",
					"eslint",
					"texlab",
					"tinymist",
					"marksman",
				},
			})
		end,
	},

	-- Needed for .lua files and configurations
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				{ path = "${3rd}/love2d/library", words = { "love%." } },
			},
		},
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = { "saghen/blink.cmp" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Applied to every server
			vim.lsp.config("*", {
				capabilities = capabilities,
			})

			-- Validation only produces diagnostics, so it is disabled. Completion
			-- and navigation stay on
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

			-- Emmet only where markup lives. Plain .js/.ts files get no emmet noise
			vim.lsp.config("emmet_language_server", {
				filetypes = {
					"templ",
					"html",
					"css",
					"scss",
					"php",
					"javascriptreact",
					"typescriptreact",
				},
				init_options = {
					showExpandedAbbreviation = "always",
					showAbbreviationSuggestions = true,
				},
			})

			-- Important for me to take notes
			vim.lsp.config("marksman", {
				root_dir = root({
					".git",
					"README.md",
					"README.markdown",
					".marksman.toml",
				}, true),
			})

			-- TypeScript / JavaScript. vtsls replaces ts_ls: it handles large
			-- monorepos better and exposes extra commands (go to source definition,
			-- move to file, etc). Never enable ts_ls together with it, or every
			-- diagnostic and completion shows up twice
			local function ts_settings()
				return {
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
			end

			vim.lsp.config("vtsls", {
				commands = {
					["_typescript.didOrganizeImports"] = function() end,
				},
				settings = {
					typescript = vim.tbl_deep_extend("force", ts_settings(), {
						tsserver = { maxTsServerMemory = 8192 },
					}),
					javascript = ts_settings(),
					vtsls = {
						autoUseWorkspaceTsdk = true,
						experimental = {
							maxInlayHintLength = 30,
							completion = { enableServerSideFuzzyMatch = false },
						},
					},
				},
			})

			-- ESLint diagnostics and fixes. Formatting stays with conform/prettier,
			-- so the server's own formatter is off. Fixes on save are wired in the
			-- LspAttach autocmd below
			vim.lsp.config("eslint", {
				settings = {
					format = false,
				},
			})

			-- Runs `LspEslintFixAll` before conform formats the buffer (the autocmd
			-- is created on attach, so it is registered before conform's). Respects
			-- the same toggles as autoformat (<leader>uf)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("EslintFixOnSave", { clear = true }),
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if not client or client.name ~= "eslint" then
						return
					end
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = args.buf,
						callback = function()
							if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
								return
							end
							if vim.fn.exists(":LspEslintFixAll") == 2 then
								vim.cmd("silent! LspEslintFixAll")
							end
						end,
					})
				end,
			})

			vim.lsp.config("tailwindcss", {
				filetypes = {
					"templ",
					"html",
					"css",
					"javascriptreact",
					"typescriptreact",
				},
				settings = {
					tailwindCSS = {
						includeLanguages = { templ = "html" },
						-- Class detection inside helper calls: cn("..."), cva("..."), etc.
						classFunctions = { "cn", "clsx", "cx", "cva", "tv", "twMerge" },
					},
				},
				root_dir = root({
					"tailwind.config.js",
					"tailwind.config.cjs",
					"tailwind.config.mjs",
					"tailwind.config.ts",
					"postcss.config.js",
					"postcss.config.cjs",
					"postcss.config.mjs",
					"postcss.config.ts",
					"package.json",
					"node_modules",
					".git",
				}, false),
			})

			vim.lsp.config("texlab", {
				settings = {
					texlab = {
						completion = {
							-- Fuzzy, case-insensitive matching instead of the default prefix
							-- matcher. Abbreviations such as "thm" and "eqn" then surface
							-- completions like "\theorem" and "\begin{equation}", which keeps
							-- texlab consistent with blink.cmp's other fuzzy sources (buffer,
							-- ripgrep and VimTeX)
							matcher = "fuzzy-ignore-case",
						},
					},
				},
			})

			vim.lsp.config("tinymist", {
				settings = {
					formatterMode = "typstyle",

					-- One of "onType", "onSave" or "never"
					exportPdf = "onSave",

					-- Keep in sync with pdf_path() in after/ftplugin/typst.lua
					outputPath = "$root/build/$dir/$name",

					-- Highlighting comes from treesitter only.
					semanticTokens = "disable",

					-- Only honored by tinymist versions that support linting
					lint = { enabled = false },
				},
			})

			vim.lsp.enable({
				"cssls",
				"emmet_language_server",
				"eslint",
				"html",
				"tailwindcss",
				"texlab",
				"tinymist",
				"marksman",
				"vtsls",
			})
		end,
	},
}
