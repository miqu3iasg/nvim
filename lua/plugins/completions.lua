-- lua/plugins/completions.lua

-- This configuration uses blink.cmp for completion, LuaSnip for snippets,
-- and blink.compat to integrate completion sources that use the nvim-cmp
-- interface. The snippet definitions are stored under lua/snippets/ and
-- are loaded lazily when a buffer of the corresponding filetype is opened.
--
-- Completion works alongside the language servers and formatters configured
-- elsewhere in this Neovim setup. Install the required language servers and
-- formatters through Mason, and make sure the corresponding servers are
-- configured and enabled in lua/plugins/lsp.lua. Mason manages the external
-- tools, while the LSP configuration determines how Neovim starts and uses
-- the language servers.
--
-- On Arch Linux, install the Tree-sitter CLI and the system dependencies
-- required by the supported languages with:
--
-- $ sudo pacman -S tree-sitter-cli nodejs npm jdk-openjdk typst typstyle
-- $ sudo pacman -S texlive-basic texlive-bin texlive-latexextra texlive-fontsextra
--
-- Install the Tree-sitter parsers used by this configuration from Neovim
-- with the following command:
--
-- :TSInstall c java python lua scheme racket sql markdown javascript typescript
-- :TSInstall html css json jsonc yaml toml bash latex typst
--
-- Language servers and formatters are installed separately through Mason.
-- For example, use :Mason to open the Mason interface or :MasonInstall followed
-- by the relevant package names. The exact tools required depend on the
-- languages you use and the configurations in lua/plugins/lsp.lua and
-- lua/plugins/conform.lua.
--
-- The completion menu also integrates with LazyDev for Lua development and
-- VimTeX for LaTeX completion. These sources require their corresponding
-- plugins to be installed and configured. VimTeX's completion integration
-- uses blink.compat to provide compatibility with the nvim-cmp source API.
--
-- See: https://github.com/Saghen/blink.cmp
-- See: https://github.com/L3MON4D3/LuaSnip
-- See: https://github.com/Saghen/blink.compat
-- See: https://github.com/nvim-treesitter/nvim-treesitter
-- See: https://github.com/mason-org/mason.nvim

-- Modules under lua/snippets/, required lazily the first time a buffer of that
-- filetype is opened. `common` is loaded with the first filetype that uses it
local snippet_modules = {
	tex = "snippets.latex",
	typst = "snippets.typst",
	c = "snippets.c",
	python = "snippets.python",
	java = "snippets.java",
	lisp = "snippets.lisp",
	sql = "snippets.sql",
	markdown = "snippets.markdown",
	common = "snippets.common",
}

-- Filetypes that reuse the snippets of another filetype
local aliases = {
	scheme = "lisp",
	mysql = "sql",
	plsql = "sql",
}

-- Filetypes that also inherit the "common" snippets
local common_filetypes = {
	python = true,
	c = true,
	scheme = true,
	lua = true,
	java = true,
	javascript = true,
	typescript = true,
	go = true,
	sh = true,
	markdown = true,
	tex = true,
	typst = true,
	sql = true,
	mysql = true,
	plsql = true,
	html = true,
	css = true,
}

-- Filetypes where the completion menu opens automatically
local auto_show_filetypes = {
	javascript = true,
	javascriptreact = true,
	typescript = true,
	typescriptreact = true,
	htmlangular = true,
	html = true,
	css = true,
	scss = true,
	tex = true,
	json = true,
	jsonc = true,
	yaml = true,
	toml = true,
}

-- Markdown is prose, so the menu stays closed except while typing a wikilink ([[Note)
local function markdown_auto_show()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	local before = vim.api.nvim_get_current_line():sub(1, col)
	return before:match("%[%[[^%]]*$") ~= nil
end

-- LuaSnip Setup

local luasnip = require("luasnip")

luasnip.setup({
	enable_autosnippets = true,
	store_selection_keys = "<leader>s",
	update_events = "TextChanged,TextChangedI",
	region_check_events = "InsertEnter",
	delete_check_events = "TextChanged",
})

-- `filetype_extend` is cheap, so it stays eager
for ft in pairs(common_filetypes) do
	luasnip.filetype_extend(ft, { "common" })
end

for ft, base in pairs(aliases) do
	luasnip.filetype_extend(ft, { base })
end

-- Lazy Snippet Loading

local loaded = {}

local function load(name)
	local module = snippet_modules[name]

	if not module or loaded[name] then
		return
	end

	loaded[name] = true
	local ok, snippets = pcall(require, module)
	if ok then
		luasnip.add_snippets(name, snippets)
	else
		vim.notify(("Failed to load snippets '%s': %s"):format(module, snippets), vim.log.levels.ERROR)
	end
end

local function load_snippets(ft)
	load(aliases[ft] or ft)
	if common_filetypes[ft] then
		load("common")
	end
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("LazySnippets", { clear = true }),
	callback = function(args)
		load_snippets(args.match)
	end,
})

-- Buffers opened before this file ran missed their FileType event
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
	if vim.api.nvim_buf_is_loaded(buf) then
		load_snippets(vim.bo[buf].filetype)
	end
end

-- blink.compat is still needed for the vimtex source
require("blink.compat").setup({
	impersonate_nvim_cmp = true,
})

-- blink.cmp Setup

-- Navigate LuaSnip choices through blink.cmp's keymap callback chain
local function choice(dir)
	return function()
		if luasnip.choice_active() then
			vim.schedule(function()
				luasnip.change_choice(dir)
			end)
			return true
		end
	end
end

require("blink.cmp").setup({
	-- Preset "none": only the mappings below exist. Each entry is tried in
	-- order and the first one that returns true stops the chain
	keymap = {
		preset = "none",
		["<C-y>"] = { "show" },
		["<CR>"] = { "accept", "fallback" },
		["<C-n>"] = { "select_next", choice(1), "fallback" },
		["<C-p>"] = { "select_prev", choice(-1), "fallback" },
		["<S-Tab>"] = { "snippet_backward", "fallback" },
		["<C-q>"] = {
			"hide",
			function()
				if luasnip.in_snippet() then
					luasnip.unlink_current()
					return true
				end
			end,
			"fallback",
		},
		["<Tab>"] = {
			"accept",
			function()
				if vim.fn.mode() == "i" and luasnip.expandable() then
					vim.schedule(luasnip.expand)
					return true
				end
			end,
			"snippet_forward",
			"fallback",
		},
	},

	-- Completion Behavior
	completion = {
		menu = {
			auto_show = function()
				local ft = vim.bo.filetype
				if ft == "markdown" then
					return markdown_auto_show()
				end
				return auto_show_filetypes[ft] == true
			end,

			border = "none",
			min_width = 70,
			max_height = 18,
			scrollbar = false,

			draw = {
				columns = {
					{ "label", "label_description", gap = 1 },
					{ "kind" },
				},

				components = {
					label = { width = { fill = true, min = 30 } },
					label_description = { width = { min = 20 } },
					kind = { width = { min = 12 } },
				},
			},
		},

		documentation = {
			window = { border = "none" },
		},

		-- Preselect the first item without inserting it (like "noinsert")
		list = {
			selection = { auto_insert = false },
		},

		accept = {
			auto_brackets = { enabled = false },
		},
	},

	-- Snippet Integration
	snippets = {
		preset = "luasnip",
	},

	-- Command-Line Completion
	cmdline = {
		enabled = false,
	},

	-- Completion Sources
	sources = {
		per_filetype = {
			lua = {
				inherit_defaults = true,
				"lazydev",
			},
			tex = {
				inherit_defaults = true,
				"vimtex",
			},
			-- java = {
			-- 	"snippets",
			-- 	"buffer",
			-- },
		},

		providers = {
			snippets = {
				score_offset = -3,
				opts = { show_autosnippets = false },
			},
			path = {
				score_offset = -4,
			},
			buffer = {
				score_offset = -5,
			},
			lazydev = {
				name = "LazyDev",
				module = "lazydev.integrations.blink",
				score_offset = 100,
			},
			vimtex = {
				name = "vimtex",
				module = "blink.compat.source",
				score_offset = -1,
				async = true,
			},
		},
	},
})
