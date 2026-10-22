-- lua/plugins/formatting.lua

-- Conform.nvim runs external formatter executables, so they must be on PATH.
-- Mason can install many of them (stylua, ruff, rustfmt, google-java-format,
-- fourmolu, yamlfmt, ktlint, swiftformat, zigfmt, etc.), but the
-- ones below may need to be installed manually
--
-- On Arch Linux, most system-level formatters come from pacman: Node.js for
-- the web formatters, clang-format (C/C++), Go, a TeX distribution with
-- latexindent (LaTeX), typstyle (Typst), shfmt (shell), taplo (TOML), Elixir,
-- nixfmt, perltidy, scalafmt and buf (Protobuf):
--
-- $ sudo pacman -S nodejs npm clang go texlive-basic texlive-bin texlive-latexextra texlive-fontsextra typstyle shfmt taplo-cli elixir nixfmt perltidy scalafmt buf
--
-- JavaScript, TypeScript, HTML, CSS, JSON, Markdown, GraphQL and Vue use
-- Prettier. Prettierd is preferred when available, and Conform falls back to
-- Prettier through `stop_after_first = true`. Both can also come from Mason.
-- SQL and Elm formatting are Node-based too:
--
-- $ npm install -g prettier prettierd sql-formatter elm-format
--
-- Astro formatting needs the Astro CLI, which should come from the project's
-- own dependencies rather than a global install:
--
-- $ npm install astro
--
-- The remaining formatters come from other package managers:
--
-- $ pip install xmlformatter
--
-- $ gem install rubocop
--
-- $ R -e 'install.packages("styler")'
--
-- Some formatters need no separate install because they ship with their
-- language tooling: `mix format` comes with Elixir and `terraform fmt` with
-- Terraform. Julia (runic), Clojure (cljfmt) and Dockerfile (dockerfmt) need
-- their binaries installed by hand or through Mason
--
-- See: https://github.com/stevearc/conform.nvim

vim.keymap.set("n", "<leader>k", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })

vim.keymap.set("n", "<leader>uf", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	vim.notify("Autoformat: " .. (vim.g.disable_autoformat and "OFF" or "ON"))
end, { desc = "Toggle autoformat" })

require("conform").setup({
	notify_on_error = true,
	formatters_by_ft = {
		lua = { "stylua" },
		go = { "goimports-reviser", "golines" },
		c = { "clang_format" },
		cpp = { "clang_format" },
		java = { "google-java-format" },
		python = { "ruff_organize_imports", "ruff_format" },
		sh = { "shfmt" },
		bash = { "shfmt" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
		javascriptreact = { "prettierd", "prettier", stop_after_first = true },
		typescript = { "prettierd", "prettier", stop_after_first = true },
		typescriptreact = { "prettierd", "prettier", stop_after_first = true },
		html = { "prettierd", "prettier", stop_after_first = true },
		css = { "prettierd", "prettier", stop_after_first = true },
		scss = { "prettierd", "prettier", stop_after_first = true },
		json = { "prettierd", "prettier", stop_after_first = true },
		jsonc = { "prettierd", "prettier", stop_after_first = true },
		yaml = { "yamlfmt" },
		toml = { "taplo" },
		xml = { "xmlformatter" },
		sql = { "sql_formatter" },
		dockerfile = { "dockerfmt" },
		terraform = { "terraform_fmt" },
		markdown = { "prettierd", "prettier", stop_after_first = true },
		tex = { "latexindent" },
		typst = { "typstyle" },
		asm = { "asmfmt" },

		-- fallback
		["_"] = { "trim_whitespace", "trim_newlines" },
	},
	formatters = {
		["google-java-format"] = {
			prepend_args = { "--skip-javadoc-formatting" },
		},
		clang_format = {
			-- this file must be located in `~/.clang-format`. We have an example
			-- of this file in `assets/templates/clang-format.example.yaml`
			prepend_args = { "--style=file" },
		},
		golines = {
			prepend_args = { "--base-formatter=gofumpt", "--max-len=100" },
		},
		shfmt = {
			prepend_args = { "-i", "2", "-ci" },
		},
		sql_formatter = {
			prepend_args = {
				"-l",
				"mysql",
				"-c",
				'{"keywordCase":"upper","dataTypeCase":"upper","functionCase":"upper","tabWidth":4}',
			},
		},
	},
	format_on_save = function(bufnr)
		if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
			return
		end
		return { timeout_ms = 2000, lsp_format = "fallback" }
	end,
})
