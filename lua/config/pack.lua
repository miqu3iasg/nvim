-- lua/config/pack.lua

-- To update, you can use: :lua vim.pack.update()
local gh = function(repo)
	return "https://github.com/" .. repo
end

-- Must be created before plugins installations
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
	{ src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
	{ src = gh("obsidian-nvim/obsidian.nvim"), version = vim.version.range("*") },
	{ src = gh("nvim-treesitter/nvim-treesitter-textobjects"), version = "main" },
	{ src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") }, -- dependency of nvim-lspconfig (capabilities); its own config is not converted yet
	{ src = gh("L3MON4D3/LuaSnip"), version = vim.version.range("2.*") },
	{ src = gh("saghen/blink.compat"), version = vim.version.range("*") },
	gh("stevearc/conform.nvim"),
	gh("ibhagwan/fzf-lua"),
	gh("tpope/vim-fugitive"),
	gh("tpope/vim-rhubarb"), -- dependency of vim-fugitive (:GBrowse)
	gh("lewis6991/gitsigns.nvim"),
	gh("mason-org/mason.nvim"), -- also used by mason-tool-installer for latex configuration
	gh("mason-org/mason-lspconfig.nvim"),
	gh("folke/lazydev.nvim"), -- Needed for .lua files and configurations
	gh("neovim/nvim-lspconfig"),
	gh("micangl/cmp-vimtex"),
	gh("kdheepak/cmp-latex-symbols"),
	gh("nvim-mini/mini.nvim"),
	gh("christoomey/vim-tmux-navigator"),
	gh("catgoose/nvim-colorizer.lua"),
	gh("lervag/vimtex"),
	gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
	gh("Olical/conjure"),
	gh("julienvincent/nvim-paredit"),
	gh("nvim-lua/plenary.nvim"),
	gh("metalelf0/black-metal-theme-neovim"),
	gh("amedoeyes/eyes.nvim"),
})
