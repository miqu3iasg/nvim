-- lua/plugins/colorschemes.lua

-- Extra colorschemes installed on top of the two built-in theme groups
--
-- Installation: the vim.pack entries of all extra colorschemes live in the
-- central plugin list of lua/config/pack.lua, which must have run before this
-- file. This module only configures them; the theme itself is applied with
-- :colorscheme (removing the eager load() also avoids applying highlights on
-- every startup).
--
-- See: colors/ (self-maintained schemes)
-- See: https://github.com/metalelf0/black-metal-theme-neovim

-- Color palettes used for colorscheme overrides

-- Palette used for the black-metal overrides below, keyed by its role in
-- the scheme (line background, foreground levels, comments and accents).
---@type table<string, string>
local black_metal_palette = {
	line = "#111111",
	bright = "#ffffff",
	fg = "#e2e2e2",
	mid = "#9e9e9e",
	comment = "#636262",
	teal = "#5f8787",
}

-- Colorscheme configurations

-- Black Metal
-- Only setup() here: it registers config/highlights tables but applies no
-- highlights. The theme is applied with :colorscheme.
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
		["@markup.strong"] = { fg = black_metal_palette.bright, fmt = "bold" },
		["@markup.italic"] = { fg = black_metal_palette.fg, fmt = "italic" },
		["@markup.strikethrough"] = { fg = black_metal_palette.comment, fmt = "strikethrough" },
		["@markup.link"] = { fg = black_metal_palette.bright, fmt = "underline" },
		["@markup.link.label"] = { fg = black_metal_palette.bright },
		["@markup.link.url"] = { fg = black_metal_palette.teal, fmt = "underline" },
		["@markup.list"] = { fg = black_metal_palette.teal },
		["@markup.math"] = { fg = black_metal_palette.bright },
		["@conceal"] = { fg = black_metal_palette.comment },

		["@markup.list.markdown"] = { fg = black_metal_palette.teal, fmt = "bold" },
		["@markup.raw.delimiter.markdown"] = { fg = black_metal_palette.teal },
		["@label.markdown"] = { fg = black_metal_palette.teal, fmt = "italic" },
		["@markup.math.markdown_inline"] = { fg = black_metal_palette.teal, fmt = "italic" },
		["@markup.math.latex"] = { fg = black_metal_palette.teal, fmt = "italic" },

		["@markup.italic.markdown_inline"] = { fg = black_metal_palette.mid, fmt = "italic" },
		["@punctuation.special.markdown_inline"] = { fg = black_metal_palette.bright },
		["@markup.link.markdown_inline"] = { fg = black_metal_palette.comment },
		["@markup.link.label.markdown_inline"] = {
			fg = black_metal_palette.bright,
			bg = black_metal_palette.line,
			fmt = "underline",
		},

		["@markup.heading"] = { fg = black_metal_palette.bright, fmt = "bold" },
		["@markup.heading.marker.markdown"] = { fg = black_metal_palette.bright, underline = false },
		["@markup.heading.1.markdown"] = { fg = black_metal_palette.bright, fmt = "bold" },
		["@markup.heading.2.markdown"] = { fg = black_metal_palette.bright, fmt = "bold" },
		["@markup.heading.3.markdown"] = { fg = black_metal_palette.fg, fmt = "bold" },
		["@markup.heading.4.markdown"] = { fg = black_metal_palette.fg, fmt = "bold" },
		["@markup.heading.5.markdown"] = { fg = black_metal_palette.mid, fmt = "bold" },
		["@markup.heading.6.markdown"] = { fg = black_metal_palette.mid, fmt = "bold" },
	},
})

-- Gruber Darker
require("gruber-darker-renaissance").setup({
	bold = true,
	italic = {
		strings = false,
		comments = false,
		operators = false,
		folds = false,
	},
	undercurl = false,
	underline = false,
	transparent = true, -- leave the window background to the terminal; floats stay opaque
	terminal_colors = true, -- set `g:terminal_color_*`
	sidebars = { "qf", "help" }, -- filetypes with the darker sidebar background
	plugins = {}, -- every integration is on; set one to false, e.g. `snacks = false`
	on_colors = function(c)
		c.syntax.func = "#b0b0b0"
	end,
	on_highlights = function(hl, c)
		hl.Underlined = { fg = "#b0b0b0", underline = false }
		hl.Directory = { fg = "#b0b0b0" }
		hl["@string.special.url"] = { fg = "#b0b0b0" }
	end,
})
