-- lua/config/pack.lua

-- Declares and installs plugins through Neovim's built-in package manager.
-- Run :lua vim.pack.update() to update plugins.

-- Must be created before plugin installations.
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if kind ~= "install" and kind ~= "update" then
			return
		end

		if name == "nvim-treesitter" then
			if not ev.data.active then
				vim.cmd.packadd("nvim-treesitter")
			end
			vim.cmd("TSUpdate")
		end

		if name == "LuaSnip" then
			local res = vim.system({ "make", "install_jsregexp" }, { cwd = ev.data.path }):wait()
			if res.code ~= 0 then
				vim.notify("LuaSnip: make install_jsregexp failed:\n" .. (res.stderr or ""), vim.log.levels.WARN)
			end
		end
	end,
})

vim.pack.add({
	-- canola.nvim (Oil.nvim fork)
	-- https://forge.barrettruth.com/barrettruth/canola.nvim
	-- File explorer that lets you edit your filesystem like a normal buffer. It is actually
	-- a fork of oil.nvim, but an improved version.
	{ src = "https://forge.barrettruth.com/barrettruth/canola.nvim" },

	-- blink.compat
	-- https://github.com/saghen/blink.compat
	-- Compatibility layer that lets blink.cmp use nvim-cmp sources. Needed for LaTeX completion.
	{ src = "https://github.com/saghen/blink.compat" },

	-- nvim-treesitter
	-- https://github.com/nvim-treesitter/nvim-treesitter
	-- Treesitter integration for parser management, syntax highlighting, and indentation.
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		version = "main",
	},

	-- nvim-treesitter-textobjects
	-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
	-- Syntax-aware text objects and motions (functions, classes, parameters, etc.).
	-- Significantly increases the speed of writing code.
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		version = "main",
	},

	-- obsidian.nvim
	-- https://github.com/obsidian-nvim/obsidian.nvim
	-- Note-taking workflow for Obsidian vaults. I use Obsidian as my main note taking app, so
	-- having this in my study and work environment really improves my workflow.
	{ src = "https://github.com/obsidian-nvim/obsidian.nvim" },

	-- blink.cmp
	-- https://github.com/saghen/blink.cmp
	-- Fast completion engine with LSP, path, snippet, and buffer sources. I only use it when
	-- I’m coding front-end applications (which is rare).
	{
		-- dependency of nvim-lspconfig (capabilities); its own config is not converted yet
		src = "https://github.com/saghen/blink.cmp",
		version = vim.version.range("1.*"),
	},

	-- LuaSnip
	-- https://github.com/L3MON4D3/LuaSnip
	-- Snippet engine written in Lua, with support for dynamic and LSP-style snippets.
	-- For me, snippets are indispensable in my workflow.
	{
		src = "https://github.com/L3MON4D3/LuaSnip",
		version = vim.version.range("2.*"),
	},

	-- conform.nvim
	-- https://github.com/stevearc/conform.nvim
	-- Lightweight formatter runner that applies external formatters (stylua, prettier, etc.).
	{ src = "https://github.com/stevearc/conform.nvim" },

	-- fzf-lua
	-- https://github.com/ibhagwan/fzf-lua
	-- Fuzzy finder for files, grep, buffers, LSP results, and more, powered by fzf.
	{ src = "https://github.com/ibhagwan/fzf-lua" },

	-- vim-fugitive
	-- https://github.com/tpope/vim-fugitive
	-- Git wrapper for running git commands, staging, committing, diffing, and blaming.
	{ src = "https://github.com/tpope/vim-fugitive" },

	-- gitsigns.nvim
	-- https://github.com/lewis6991/gitsigns.nvim
	-- Shows git diff markers in the sign column and provides hunk staging, preview, and blame.
	-- I use it mainly for staging and checking hunks.
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },

	-- mason.nvim
	-- https://github.com/mason-org/mason.nvim
	-- Package manager that installs LSP servers, formatters, linters, and debuggers.
	{
		-- also used by mason-tool-installer for latex configuration
		src = "https://github.com/mason-org/mason.nvim",
	},

	-- mason-lspconfig.nvim
	-- https://github.com/mason-org/mason-lspconfig.nvim
	-- Bridges mason.nvim and nvim-lspconfig, auto-installing and enabling LSP servers.
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" },

	-- lazydev.nvim
	-- https://github.com/folke/lazydev.nvim
	-- Configures lua_ls for Neovim API and plugin development (completions, types, annotations).
	{
		-- Needed for .lua files and configurations
		src = "https://github.com/folke/lazydev.nvim",
	},

	-- nvim-lspconfig
	-- https://github.com/neovim/nvim-lspconfig
	-- Collection of default configurations for Neovim's built-in LSP client. Used only for the
	-- front-end stack (unfortunately, sometimes it’s necessary).
	-- See: lua/plugins/lsp.lua
	{ src = "https://github.com/neovim/nvim-lspconfig" },

	-- cmp-vimtex
	-- https://github.com/micangl/cmp-vimtex
	-- Completion source for LaTeX (citations, references, commands) using vimtex data.
	{ src = "https://github.com/micangl/cmp-vimtex" },

	-- mini.nvim
	-- https://github.com/nvim-mini/mini.nvim
	-- Library of small, independent modules (surround, pairs, statusline, icons, etc.).
	-- In short, a bunch of unnecessary crap, but cool stuff, nonetheless.
	{ src = "https://github.com/nvim-mini/mini.nvim" },

	-- vim-tmux-navigator
	-- https://github.com/christoomey/vim-tmux-navigator
	-- Seamless navigation between Neovim splits and tmux panes with the same
	-- keybindings (indispensable).
	{ src = "https://github.com/christoomey/vim-tmux-navigator" },

	-- nvim-colorizer.lua
	-- https://github.com/catgoose/nvim-colorizer.lua
	-- Highlights color codes (hex, rgb, names) in the buffer with their actual color. Useful for
	-- creating themes.
	{ src = "https://github.com/catgoose/nvim-colorizer.lua" },

	-- vimtex
	-- https://github.com/lervag/vimtex
	-- Full LaTeX support: compilation, PDF viewer sync, motions, folding, and TOC.
	{ src = "https://github.com/lervag/vimtex" },

	-- mason-tool-installer.nvim
	-- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
	-- Automatically installs and updates a declared list of Mason tools.
	{ src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },

	-- conjure
	-- https://github.com/Olical/conjure
	-- Interactive REPL-driven evaluation for Lisp-family languages (Clojure, Fennel, Scheme, etc.).
	-- I’m currently studying a book that uses Lisp and working on a few projects, so I need this.
	{ src = "https://github.com/Olical/conjure" },

	-- nvim-paredit
	-- https://github.com/julienvincent/nvim-paredit
	-- Structural editing for S-expressions (slurp, barf, raise, etc.) in Lisp code.
	{ src = "https://github.com/julienvincent/nvim-paredit" },

	-- plenary.nvim
	-- https://github.com/nvim-lua/plenary.nvim
	-- Lua utility library (async, paths, jobs, testing) required by many plugins.
	{ src = "https://github.com/nvim-lua/plenary.nvim" },

	-- nvim-jdtls
	-- https://github.com/mfussenegger/nvim-jdtls
	-- Extended Java LSP support for Eclipse JDT Language Server (refactors, test running, debugging).
	{ src = "https://github.com/mfussenegger/nvim-jdtls" },

	-- img-clip.nvim
	-- https://github.com/HakonHarnes/img-clip.nvim
	-- Pastes images from the clipboard into files (Markdown, LaTeX, etc.) and inserts the link. Useful
	-- for taking notes in markdown.
	{ src = "https://github.com/HakonHarnes/img-clip.nvim" },
})
