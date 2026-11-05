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
-- $ sudo pacman -S nodejs npm clang go texlive-basic texlive-bin texlive-latexextra texlive-fontsextra typstyle shfmt taplo-cli astyle nixfmt perltidy scalafmt buf
--
-- JavaScript, TypeScript, HTML, CSS, JSON, Markdown, GraphQL and Vue use
-- Prettier. Prettierd is preferred when available, and Conform falls back to
-- Prettier through `stop_after_first = true`. Both can also come from Mason.
-- SQL and Elm formatting are Node-based too:
--
-- $ npm install -g prettier prettierd sql-formatter elm-format
--
-- Markdown uses `prettier` (not prettierd) so that --tab-width 4 can be passed.
-- The "*" and "+" bullets are preserved by extra steps (see `md_stash_bullets`).
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

local autoformat = require("shared.autoformat")

vim.keymap.set("n", "<leader>k", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })

vim.keymap.set("n", "<leader>uf", autoformat.toggle, { desc = "Toggle autoformat" })

local md_lists = require("features.markdown_lists")

---Bullet markers saved by buffer while a markdown format is running.
---@type table<integer, string[]>
local md_bullets = {}

require("conform").setup({
	notify_on_error = true,
	formatters_by_ft = {
		lua = { "stylua" },
		go = { "goimports-reviser", "golines" },
		c = { "clang_format" },
		cpp = { "clang_format" },
		-- java = { "google-java-format" },
		java = { "astyle" },
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
		markdown = { "md_stash_bullets", "prettier_md", "md_restore" },
		tex = { "latexindent" },
		typst = { "typstyle" },
		asm = { "asmfmt" },

		-- fallback
		["_"] = { "trim_whitespace", "trim_newlines" },
	},
	formatters = {
		["google-java-format"] = {
			prepend_args = { "--aosp", "--skip-javadoc-formatting" },
		},

		astyle = {
			prepend_args = { "--style=allman", "--indent=spaces=4" },
		},

		clang_format = {
			-- this file must be located in `~/.clang-format`. We have an example
			-- of this file in `resources/clang-format.example.yaml`
			prepend_args = { "--style=file" },
		},

		golines = {
			prepend_args = { "--base-formatter=gofumpt", "--max-len=100" },
		},

		-- Markdown

		-- Prettier with 4 columns of indentation (nested lists get 4). It is `prettier`
		-- and not `prettierd` because prettierd does not accept CLI flags.
		prettier_md = require("conform.util").merge_formatter_configs(require("conform.formatters.prettier"), {
			prepend_args = { "--tab-width", "4" },
		}),

		-- Prettier rewrites the "*" and "+" bullets as "-" (or alternates "-" and "*"
		-- between neighbouring lists). These two steps save the markers before
		-- formatting and put them back afterwards, so "-", "*" and "+" stay as written.
		md_stash_bullets = {
			format = function(_, ctx, lines, callback)
				md_bullets[ctx.buf] = md_lists.bullet_markers(lines)
				callback(nil, lines)
			end,
		},

		-- Prettier never writes tabs in lists, so each group of 4 leading spaces is
		-- turned into a tab (the remainder stays as spaces). Disable it with
		-- `vim.g.markdown_use_tabs = false`.
		md_restore = {
			format = function(_, ctx, lines, callback)
				lines = md_lists.restore_bullets(lines, md_bullets[ctx.buf])
				md_bullets[ctx.buf] = nil
				if vim.g.markdown_use_tabs ~= false then
					lines = md_lists.tabify(lines, 4)
				end
				callback(nil, lines)
			end,
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
		if not autoformat.enabled(bufnr) then
			return
		end
		return { timeout_ms = 2000, lsp_format = "fallback" }
	end,
})
