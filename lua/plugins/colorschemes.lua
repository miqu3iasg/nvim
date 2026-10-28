-- lua/plugins/colorschemes.lua

vim.pack.add({
	"https://github.com/jaredgorski/fogbell.vim",
	"https://github.com/amedoeyes/eyes.nvim",
	"https://github.com/metalelf0/black-metal-theme-neovim",
})

-- Color palettes used for colorscheme overrides

local black_metal_pallet = {
	line = "#111111",
	bright = "#ffffff",
	fg = "#e2e2e2",
	mid = "#9e9e9e",
	comment = "#636262",
	teal = "#5f8787",
}

-- Colorsheme configurations

-- Black Metal
require("black-metal").setup({
	transparent = true,
	trve = true, -- switch this to false if you want light variants

	-- Custom highlights, override default colors
	colors = {},

	-- Override highlight groups
	highlights = {
		StatusLine = { fg = "#a8a8a8", bg = "#121212" },
		StatusLineNC = { fg = "#5f5f5f", bg = "#050505" },
		Search = { fg = "#D6C17A", bg = "#3D3525" },
		CurSearch = { fg = "#3D3525", bg = "#D6C17A", fmt = "bold" },
		IncSearch = { fg = "#3D3525", bg = "#D6C17A", fmt = "bold" },

		-- Markdown
		["@markup.strong"] = { fg = black_metal_pallet.bright, fmt = "bold" },
		["@markup.italic"] = { fg = black_metal_pallet.fg, fmt = "italic" },
		["@markup.strikethrough"] = { fg = black_metal_pallet.comment, fmt = "strikethrough" },
		["@markup.link"] = { fg = black_metal_pallet.bright, fmt = "underline" },
		["@markup.link.label"] = { fg = black_metal_pallet.bright },
		["@markup.link.url"] = { fg = black_metal_pallet.teal, fmt = "underline" },
		["@markup.list"] = { fg = black_metal_pallet.teal },
		["@markup.math"] = { fg = black_metal_pallet.bright },
		["@conceal"] = { fg = black_metal_pallet.comment },

		["@markup.list.markdown"] = { fg = black_metal_pallet.teal, fmt = "bold" },
		["@markup.raw.delimiter.markdown"] = { fg = black_metal_pallet.teal },
		["@label.markdown"] = { fg = black_metal_pallet.teal, fmt = "italic" },
		["@markup.math.markdown_inline"] = { fg = black_metal_pallet.teal, fmt = "italic" },
		["@markup.math.latex"] = { fg = black_metal_pallet.teal, fmt = "italic" },

		["@markup.italic.markdown_inline"] = { fg = black_metal_pallet.mid, fmt = "italic" },
		["@punctuation.special.markdown_inline"] = { fg = black_metal_pallet.bright },
		["@markup.link.markdown_inline"] = { fg = black_metal_pallet.comment },
		["@markup.link.label.markdown_inline"] = {
			fg = black_metal_pallet.bright,
			bg = black_metal_pallet.line,
			fmt = "underline",
		},

		["@markup.heading"] = { fg = black_metal_pallet.bright, fmt = "bold" },
		["@markup.heading.marker.markdown"] = { fg = black_metal_pallet.bright, underline = false },
		["@markup.heading.1.markdown"] = { fg = black_metal_pallet.bright, fmt = "bold" },
		["@markup.heading.2.markdown"] = { fg = black_metal_pallet.bright, fmt = "bold" },
		["@markup.heading.3.markdown"] = { fg = black_metal_pallet.fg, fmt = "bold" },
		["@markup.heading.4.markdown"] = { fg = black_metal_pallet.fg, fmt = "bold" },
		["@markup.heading.5.markdown"] = { fg = black_metal_pallet.mid, fmt = "bold" },
		["@markup.heading.6.markdown"] = { fg = black_metal_pallet.mid, fmt = "bold" },
	},
})

require("black-metal").load()
