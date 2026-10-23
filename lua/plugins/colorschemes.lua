-- lua/plugins/colorschemes.lua

vim.pack.add({
	"https://github.com/jaredgorski/fogbell.vim",
	"https://github.com/amedoeyes/eyes.nvim",
	"https://github.com/metalelf0/black-metal-theme-neovim",
})

require("black-metal").setup({
	theme = "darkthrone",
	variant = "dark",
	alt_bg = true,
	colored_docstrings = true,
	cursorline_gutter = false,
	dark_gutter = false,
	favor_treesitter_hl = false,
	plain_float = false,
	show_eob = true,
	term_colors = true,
	transparent = true,
	trve = false,

	-- Plugin appearance
	plugin = {
		cmp = {
			plain = false,
			reverse = false,
		},
	},

	-- Custom highlights, override default colors
	colors = {},

	-- Override highlight groups
	highlights = {
		StatusLine = { fg = "#a8a8a8", bg = "#121212" },
		StatusLineNC = { fg = "#5f5f5f", bg = "#050505" },
	},
})

require("black-metal").load()
