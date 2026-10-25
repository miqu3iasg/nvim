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
	{ src = "https://forge.barrettruth.com/barrettruth/canola.nvim" },
	{
		src = "https://github.com/saghen/blink.compat",
	},
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		version = "main",
	},
	{
		src = "https://github.com/obsidian-nvim/obsidian.nvim",
	},
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		version = "main",
	},
	{
		-- dependency of nvim-lspconfig (capabilities); its own config is not converted yet
		src = "https://github.com/saghen/blink.cmp",
		version = vim.version.range("1.*"),
	},
	{
		src = "https://github.com/L3MON4D3/LuaSnip",
		version = vim.version.range("2.*"),
	},
	{
		src = "https://github.com/saghen/blink.compat",
	},
	{
		src = "https://github.com/stevearc/conform.nvim",
	},
	{
		src = "https://github.com/ibhagwan/fzf-lua",
	},
	{
		src = "https://github.com/tpope/vim-fugitive",
	},
	{
		src = "https://github.com/lewis6991/gitsigns.nvim",
	},
	{
		-- also used by mason-tool-installer for latex configuration
		src = "https://github.com/mason-org/mason.nvim",
	},
	{
		src = "https://github.com/mason-org/mason-lspconfig.nvim",
	},
	{
		-- Needed for .lua files and configurations
		src = "https://github.com/folke/lazydev.nvim",
	},
	{
		src = "https://github.com/neovim/nvim-lspconfig",
	},
	{
		src = "https://github.com/micangl/cmp-vimtex",
	},
	{
		src = "https://github.com/nvim-mini/mini.nvim",
	},
	{
		src = "https://github.com/christoomey/vim-tmux-navigator",
	},
	{
		src = "https://github.com/catgoose/nvim-colorizer.lua",
	},
	{
		src = "https://github.com/lervag/vimtex",
	},
	{
		src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	{
		src = "https://github.com/Olical/conjure",
	},
	{
		src = "https://github.com/julienvincent/nvim-paredit",
	},
	{
		src = "https://github.com/nvim-lua/plenary.nvim",
	},
	{
		src = "https://github.com/mfussenegger/nvim-jdtls",
	},
	{
		src = "https://github.com/HakonHarnes/img-clip.nvim",
	},
})
