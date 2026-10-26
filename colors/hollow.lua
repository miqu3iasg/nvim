-- colors/hollow.lua
--
-- A modified version of the quiet colorscheme.
--
-- Copyright (c) Maxence Weynans <neutaaaaan@gmail.com>
-- Copyright (c) Miquéias Alves Medeiros <https://github.com/miqu3iasg>
--
-- See: `:help license`
--
-- Original Vimscript colorscheme converted to Lua for Neovim.
--
-- SPDX-License-Identifier: Vim

vim.cmd("runtime colors/vim.lua")
vim.g.colors_name = "hollow"

local set_hl = vim.api.nvim_set_hl

-- Pallete
local p = {
	-- Neutrals
	black = "#000000",
	white = "#ffffff",
	fg = "#c8c8c8", -- default text
	fg_alt = "#c8c8c8", -- statements, types, preproc
	string = "#c8c8c8",
	punct = "#e2e2e2",
	tailwind = "#e2e2e2",
	dim = "#707070",
	comment = "#6a6a6a",
	doc = "#7a7a7a",
	line_nr = "#585858",

	-- Surfaces
	line = "#111111", -- cursorline, statusline, code blocks
	popup_bg = "#0d0d0d",
	inlay_bg = "#0a0a0a",
	surface = "#1c1c1c",
	surface_hi = "#303030",
	border = "#444444",

	-- Statusline
	statusline_fg = "#e2e2e2",
	statusline_nc_fg = "#636262",

	-- Accent and status
	accent = "#6382eb",
	error = "#b86a6a",
	warn = "#b09b72",
	ok = "#678a67",

	-- Search
	search_fg = "#D6C17A",
	search_bg = "#3D3525",

	-- Diff
	diff = {
		add_bg = "#0f1a12", -- added line
		change_bg = "#101722", -- changed line
		delete_bg = "#1a1112", -- deleted line
		text_bg = "#1f3050", -- changed text inside a line
		add_text_bg = "#1c3324", -- added text inside a line
		delete_text_bg = "#3a1f21", -- deleted text inside a line
		added = "#6f9a73",
		changed = "#6f8fb8",
		removed = "#b87a7a",
		line = "#6f8fb8", -- hunk header
	},

	-- Regex injections
	regex = {
		string = "#8a94a0",
		delimiter = "#946060",
		property = "#5f7f5f",
	},

	-- Markdown
	markdown = {
		italic = "#949494", -- 246
		strike = "#6c6c6c", -- 242
		marker = "#585858", -- 240
		block = "#b2b2b2", -- 249
		string = "#cecece", -- 252 (yaml string values)
		code = "#93a0b4", -- 109, blue-gray tint, brighter than italic
		accent = "#738296", -- 66, same tint, dimmer, exclusive color for markup markers
	},

	terminal = {
		"#000000",
		"#913939",
		"#00af5f",
		"#221cd6",
		"#0087d7",
		"#d787d7",
		"#00afaf",
		"#dadada",
		"#707070",
		"#9c3b3b",
		"#00d75f",
		"#221cd6",
		"#5fafff",
		"#ff87ff",
		"#00d7d7",
		"#ffffff",
	},
}

local md = p.markdown

-- Helpers

local GUI_ATTRS = { "bold", "italic", "underline", "undercurl", "reverse", "strikethrough" }

-- Turns a group spec into `nvim_set_hl` options
local function normalize(spec)
	if type(spec) == "string" then
		return { link = spec, force = true }
	end

	local opts = vim.deepcopy(spec)
	if not opts.cterm then
		opts.cterm = {}
		for _, attr in ipairs(GUI_ATTRS) do
			if opts[attr] then
				opts.cterm[attr] = true
			end
		end
	end
	return opts
end

local function apply(groups)
	for name, spec in pairs(groups) do
		set_hl(0, name, normalize(spec))
	end
end

-- Highlight groups

-- Editor UI
local editor = {
	-- Base
	Normal = { fg = p.fg, bg = p.black, ctermfg = 254, ctermbg = 16 },
	Cursor = { fg = p.black, bg = p.fg, ctermfg = 16, ctermbg = 254 },
	CursorIM = { fg = p.black, bg = p.accent, ctermfg = 16, ctermbg = 62 },
	CursorLine = { bg = p.line, ctermbg = 233 },
	CursorColumn = { bg = p.surface_hi, ctermbg = 236 },
	CursorLineNr = { fg = p.fg, bg = p.line, bold = true, ctermfg = 254, ctermbg = 233 },
	ColorColumn = { bg = p.surface, ctermbg = 234 },
	Conceal = {},
	LineNr = { fg = p.line_nr, ctermfg = 240 },
	SignColumn = { fg = p.fg, bg = p.black, ctermfg = 254, ctermbg = 16 },
	FoldColumn = { fg = p.dim, bg = p.black, ctermfg = 242, ctermbg = 16 },
	Folded = { fg = p.dim, bg = p.black, ctermfg = 242, ctermbg = 16 },
	EndOfBuffer = { fg = p.dim, ctermfg = 242 },
	NonText = { fg = p.dim, ctermfg = 242 },
	SpecialKey = { fg = p.dim, bold = true, ctermfg = 242 },
	Directory = { fg = p.fg, ctermfg = 254 },
	MatchParen = { fg = p.accent, bold = true, ctermfg = 62 },
	QuickFixLine = { bg = p.line, bold = true, ctermbg = 233 },
	VertSplit = { fg = p.dim, bg = p.black, ctermfg = 242, ctermbg = 16 },

	-- Selection and search
	Visual = { bg = p.border, ctermbg = 238 },
	VisualNOS = { bg = p.surface_hi, ctermbg = 236 },
	Search = { fg = p.search_fg, bg = p.search_bg, ctermfg = 135, ctermbg = 53 },
	IncSearch = { fg = p.search_bg, bg = p.search_fg, bold = true, ctermfg = 53, ctermbg = 135 },
	CurSearch = { fg = p.search_bg, bg = p.search_fg, bold = true, ctermfg = 53, ctermbg = 135 },

	-- Messages
	ModeMsg = { fg = p.fg, bg = p.black, bold = true, ctermfg = 254, ctermbg = 16 },
	MoreMsg = { fg = p.fg, bg = p.black, ctermfg = 254, ctermbg = 16 },
	MsgArea = { fg = p.fg, bg = p.black, ctermfg = 254, ctermbg = 16 },
	MsgSeparator = { fg = p.border, bg = p.black, ctermfg = 238, ctermbg = 16 },
	Question = { fg = p.fg, bg = p.black, ctermfg = 254, ctermbg = 16 },
	WarningMsg = { fg = p.warn, bg = p.black, ctermfg = 137, ctermbg = 16 },
	ErrorMsg = { fg = p.error, bg = p.black, bold = true, ctermfg = 131, ctermbg = 16 },
	Error = { fg = p.error, bg = p.black, bold = true, reverse = true, ctermfg = 131, ctermbg = 16 },
	Todo = { fg = p.black, bg = p.warn, bold = true, ctermfg = 16, ctermbg = 137 },

	-- Statusline, tabline, titlebar, toolbar
	StatusLine = { fg = p.statusline_fg, bg = p.line, ctermfg = 254, ctermbg = 233 },
	StatusLineNC = { fg = p.statusline_nc_fg, bg = p.black, ctermfg = 241, ctermbg = 16 },
	TabLine = { fg = p.dim, bg = p.black, ctermfg = 242, ctermbg = 16 },
	TabLineFill = { fg = p.fg, bg = p.black, ctermfg = 254, ctermbg = 16 },
	TabLineSel = { fg = p.fg, bg = p.black, bold = true, ctermfg = 254, ctermbg = 16 },
	TitleBar = { fg = p.fg, bg = p.black, ctermfg = 254, ctermbg = 16 },
	TitleBarNC = { fg = p.dim, bg = p.black, ctermfg = 242, ctermbg = 16 },
	ToolbarButton = { fg = p.fg, bg = p.black, bold = true, ctermfg = 254, ctermbg = 16 },
	ToolbarLine = { bg = p.black, ctermbg = 16 },

	-- Spell
	SpellBad = { fg = p.error, sp = p.error, undercurl = true, ctermfg = 131, cterm = { underline = true } },
	SpellCap = { fg = p.warn, sp = p.warn, undercurl = true, ctermfg = 137, cterm = { underline = true } },
	SpellLocal = { fg = p.dim, sp = p.dim, undercurl = true, ctermfg = 242, cterm = { underline = true } },
	SpellRare = { fg = p.dim, sp = p.dim, undercurl = true, ctermfg = 242, cterm = { underline = true } },
}

-- Popups and floating windows
local popup = {
	NormalFloat = { fg = p.fg, bg = p.popup_bg, ctermfg = 254, ctermbg = 233 },
	FloatBorder = { fg = p.border, bg = p.popup_bg, ctermfg = 238, ctermbg = 233 },
	FloatTitle = { fg = p.fg, bg = p.popup_bg, ctermfg = 254, ctermbg = 233 },
	FloatFooter = { fg = p.dim, bg = p.popup_bg, ctermfg = 242, ctermbg = 233 },

	Pmenu = { fg = p.fg, bg = p.popup_bg, ctermfg = 254, ctermbg = 233 },
	PmenuSel = { fg = p.fg, bg = p.surface, ctermfg = 254, ctermbg = 234 },
	PmenuExtra = { fg = p.dim, bg = p.popup_bg, ctermfg = 242, ctermbg = 233 },
	PmenuExtraSel = { fg = p.fg, bg = p.surface_hi, ctermfg = 254, ctermbg = 236 },
	PmenuKind = { fg = p.dim, bg = p.popup_bg, ctermfg = 242, ctermbg = 233 },
	PmenuKindSel = { fg = p.fg, bg = p.surface_hi, ctermfg = 254, ctermbg = 236 },
	PmenuMatch = { fg = p.white, bg = p.popup_bg, bold = true, ctermfg = 231, ctermbg = 233 },
	PmenuMatchSel = { fg = p.white, bg = p.surface_hi, bold = true, ctermfg = 231, ctermbg = 236 },
	PmenuSbar = { bg = p.popup_bg, ctermbg = 233 },
	PmenuThumb = { bg = p.border, ctermbg = 238 },
	WildMenu = { fg = p.fg, bg = p.surface_hi, ctermfg = 254, ctermbg = 236 },
}

-- Vim syntax groups
local syntax = {
	Comment = { fg = p.comment, ctermfg = 241 },
	Constant = { fg = p.fg, ctermfg = 254 },
	Number = { fg = p.fg, ctermfg = 254 },
	String = { fg = p.string, ctermfg = 254 },
	Identifier = { fg = p.fg, ctermfg = 254 },
	Function = { fg = p.fg, ctermfg = 254 },
	Statement = { fg = p.fg_alt, ctermfg = 254 },
	Type = { fg = p.fg_alt, ctermfg = 254 },
	PreProc = { fg = p.fg_alt, ctermfg = 254 },
	Special = { fg = p.fg, ctermfg = 254 },
	Ignore = { fg = p.fg, ctermfg = 254 },
	Underlined = { fg = p.fg, underline = true, ctermfg = 254 },
	Title = { fg = p.fg, bold = true, ctermfg = 254 },

	Delimiter = { fg = p.punct, ctermfg = 254 },
	Operator = { fg = p.fg, ctermfg = 254 },
}

-- Treesitter and LSP semantic tokens
local treesitter = {
	-- Comments
	["@comment.documentation"] = { fg = p.doc, ctermfg = 243 },

	-- Structure
	["@module"] = { fg = p.fg_alt, ctermfg = 254 },
	["@attribute"] = { fg = p.doc, italic = true, ctermfg = 243 },

	-- Functions (never bold)
	["@function"] = { fg = p.fg, ctermfg = 254 },
	["@function.method"] = { fg = p.fg, ctermfg = 254 },
	["@function.call"] = { fg = p.fg, ctermfg = 254 },
	["@function.method.call"] = { fg = p.fg, ctermfg = 254 },
	["@function.builtin"] = { fg = p.fg, ctermfg = 254 },

	-- LSP semantic tokens
	["@lsp.type.function"] = { fg = p.fg, ctermfg = 254 },
	["@lsp.type.method"] = { fg = p.fg, ctermfg = 254 },
	["@lsp.typemod.function.declaration"] = {},
	["@lsp.typemod.method.declaration"] = {},

	-- Variables
	["@variable.parameter"] = { fg = p.fg, italic = true, ctermfg = 254 },
	["@variable.builtin"] = { fg = p.fg_alt, italic = true, ctermfg = 254 },

	-- Literals
	["@constant.builtin"] = { fg = p.fg, ctermfg = 254 },
	["@string.escape"] = { fg = p.fg, ctermfg = 254 },

	-- Punctuation and operators
	["@punctuation"] = { fg = p.punct, ctermfg = 254 },
	["@punctuation.bracket"] = { fg = p.fg, ctermfg = 254 },
	["@punctuation.delimiter"] = { fg = p.punct, ctermfg = 254 },
	["@operator"] = { fg = p.fg, ctermfg = 254 },

	-- Tags
	["@tag"] = { fg = p.fg_alt, ctermfg = 254 },
	["@tag.delimiter"] = { fg = p.punct, ctermfg = 254 },
	["@tag.attribute"] = { fg = p.fg_alt, italic = true, ctermfg = 254 },

	-- Generic markup
	["@markup.heading"] = { fg = p.fg, bold = true, ctermfg = 254 },
	["@markup.strong"] = { bold = true },
	["@markup.italic"] = { italic = true },
	["@markup.link"] = { fg = p.fg_alt, underline = true, ctermfg = 254 },
	["@markup.raw"] = { fg = p.fg_alt, ctermfg = 254 },

	-- Regex
	["@string.regexp"] = { fg = p.regex.string, ctermfg = 245 },
	["@character.special"] = { fg = p.fg, ctermfg = 254 },
	["@operator.regex"] = { fg = p.warn, ctermfg = 137 },
	["@keyword.operator.regex"] = { fg = p.warn, ctermfg = 137 },
	["@punctuation.bracket.regex"] = { fg = p.dim, ctermfg = 242 },
	["@punctuation.delimiter.regex"] = { fg = p.regex.delimiter, ctermfg = 95 },
	["@property.regex"] = { fg = p.regex.property, italic = true, ctermfg = 65 },
	["@variable.builtin.regex"] = { fg = p.fg_alt, ctermfg = 254 },
}

-- Diagnostics and LSP
local diagnostics = {
	DiagnosticError = { fg = p.error, ctermfg = 131 },
	DiagnosticWarn = { fg = p.warn, ctermfg = 137 },
	DiagnosticInfo = { fg = p.fg_alt, ctermfg = 254 },
	DiagnosticHint = { fg = p.comment, ctermfg = 241 },
	DiagnosticOk = { fg = p.ok, ctermfg = 65 },
	DiagnosticUnnecessary = { fg = p.comment, ctermfg = 241 },

	DiagnosticUnderlineError = { sp = p.error, undercurl = true, cterm = { underline = true } },
	DiagnosticUnderlineWarn = { sp = p.warn, undercurl = true, cterm = { underline = true } },
	DiagnosticUnderlineInfo = { sp = p.fg_alt, undercurl = true, cterm = { underline = true } },
	DiagnosticUnderlineHint = { sp = p.comment, undercurl = true, cterm = { underline = true } },

	LspInlayHint = { fg = p.comment, bg = p.inlay_bg, italic = true, ctermfg = 241, ctermbg = 233 },
	LspReferenceText = { bg = p.surface, ctermbg = 234 },
	LspReferenceRead = { bg = p.surface, ctermbg = 234 },
	LspReferenceWrite = { bg = p.surface, underline = true, ctermbg = 234 },
}

-- Diff
local diff = {
	-- Lines
	DiffAdd = { fg = p.fg, bg = p.diff.add_bg, ctermfg = 254, ctermbg = 22 },
	DiffChange = { fg = p.fg, bg = p.diff.change_bg, ctermfg = 254, ctermbg = 17 },
	DiffDelete = { fg = p.diff.removed, bg = p.diff.delete_bg, ctermfg = 138, ctermbg = 52 },

	-- Text inside a line
	DiffText = { fg = p.white, bg = p.diff.text_bg, bold = true, ctermfg = 231, ctermbg = 24 },
	DiffAddText = { fg = p.white, bg = p.diff.add_text_bg, bold = true, ctermfg = 231, ctermbg = 29 },
	DiffDeleteText = { fg = p.white, bg = p.diff.delete_text_bg, bold = true, ctermfg = 231, ctermbg = 88 },

	-- Signs and diff syntax
	Added = { fg = p.diff.added, ctermfg = 108 },
	Changed = { fg = p.diff.changed, ctermfg = 110 },
	Removed = { fg = p.diff.removed, ctermfg = 138 },
	diffFile = { fg = p.fg, bold = true, ctermfg = 254 },
	diffLine = { fg = p.diff.line, ctermfg = 110 },
}

-- Markdown

local markdown = {
	-- Frontmatter fences (---)
	["@keyword.directive.markdown"] = { fg = md.accent, ctermfg = 139 },

	-- Structural punctuation
	["@punctuation.special.markdown"] = { fg = p.fg, ctermfg = 254 },
	["@punctuation.delimiter.markdown"] = { fg = p.fg, ctermfg = 254 },

	-- Lists and task items
	["@markup.list.markdown"] = { fg = md.accent, bold = true, ctermfg = 139 },
	["@markup.list.checked.markdown"] = { fg = md.accent, bold = true, ctermfg = 139 },
	["@markup.list.unchecked.markdown"] = { fg = md.accent, bold = true, ctermfg = 139 },

	-- Blockquote
	["@markup.quote.markdown"] = { fg = md.italic, italic = true, ctermfg = 248 },

	-- Code blocks
	["@markup.raw.block.markdown"] = { fg = md.block, ctermfg = 249 },
	["@markup.raw.delimiter.markdown"] = { fg = md.accent, ctermfg = 139 },
	["@label.markdown"] = { fg = md.accent, italic = true, ctermfg = 139 },

	-- Inline emphasis
	["@markup.strong.markdown_inline"] = { fg = p.white, bold = true, ctermfg = 231 },
	["@markup.italic.markdown_inline"] = { fg = md.italic, italic = true, ctermfg = 248 },
	["@markup.strikethrough.markdown_inline"] = {
		fg = md.strike,
		strikethrough = true,
		ctermfg = 242,
		cterm = {},
	},

	-- Inline code and math
	["@markup.raw.markdown_inline"] = { fg = md.code, ctermfg = 111 },
	["@markup.math.markdown_inline"] = { fg = md.code, ctermfg = 111 },
	["@markup.math.markdown"] = { fg = md.code, ctermfg = 111 },
	["@markup.math.latex"] = { fg = md.code, ctermfg = 111 }, -- injected latex inside math (also affects .tex)
	["@punctuation.special.markdown_inline"] = { fg = md.code, ctermfg = 111 }, -- $ delimiters

	-- Inline links
	["@markup.link.markdown_inline"] = { fg = md.marker, ctermfg = 240 },
	["@markup.link.label.markdown_inline"] = { fg = md.code, underline = true, ctermfg = 111 },
	["@markup.link.url.markdown_inline"] = { fg = p.accent, underline = true, ctermfg = 62 },

	-- Inline escapes and conceal
	["@string.escape.markdown_inline"] = { fg = md.accent, ctermfg = 139 },
	["@conceal.markdown_inline"] = { fg = md.marker, ctermfg = 240 },
}

-- Headings (generated from the gradient table)
do
	local levels = {
		{ p.white, 231 },
		{ p.fg, 254 },
		{ p.fg_alt, 254 },
		{ p.string, 254 },
		{ p.string, 254 },
		{ p.string, 254 },
	}

	local first = levels[1]
	markdown["@markup.heading.markdown"] = { fg = first[1], bold = true, ctermfg = first[2] }
	markdown["@markup.heading.marker.markdown"] = { fg = first[1], ctermfg = first[2] }

	for i, level in ipairs(levels) do
		markdown[("@markup.heading.%d.markdown"):format(i)] = { fg = level[1], bold = true, ctermfg = level[2] }
		markdown[("@markup.heading.%d.marker.markdown"):format(i)] = { fg = level[1], ctermfg = level[2] }
	end
end

-- Frontmatter (YAML injected into markdown), applied through its own namespace
local frontmatter = {
	["@property.yaml"] = { fg = md.accent, ctermfg = 139 }, -- keys
	["@string.yaml"] = { fg = md.string, ctermfg = 252 }, -- string values
	["@number.yaml"] = { fg = md.accent, ctermfg = 139 },
	["@number.float.yaml"] = { fg = md.accent, ctermfg = 139 },
	["@boolean.yaml"] = { fg = md.accent, ctermfg = 139 },
	["@constant.builtin.yaml"] = { fg = md.accent, ctermfg = 139 }, -- null
	["@label.yaml"] = { fg = md.accent, ctermfg = 139 }, -- anchors / aliases
	["@type.yaml"] = { fg = md.accent, ctermfg = 139 }, -- tags
	["@punctuation.delimiter.yaml"] = { fg = md.marker, ctermfg = 240 }, -- : - ,
	["@punctuation.bracket.yaml"] = { fg = md.marker, ctermfg = 240 }, -- [ ] { }
}

-- Links (hi! link)
local links = {
	-- Vim syntax
	Boolean = "Number",
	Character = "Constant",
	Conditional = "Statement",
	Debug = "Special",
	Define = "PreProc",
	Exception = "Statement",
	Float = "Number",
	Include = "PreProc",
	Keyword = "Statement",
	Label = "Statement",
	Macro = "PreProc",
	PreCondit = "PreProc",
	Repeat = "Statement",
	SpecialChar = "Special",
	SpecialComment = "Special",
	StorageClass = "Type",
	Structure = "Type",
	Tag = "Special",
	Typedef = "Type",

	-- Editor
	MessageWindow = "Pmenu",
	PopupNotification = "Todo",
	StatusLineTerm = "StatusLine",
	StatusLineTermNC = "StatusLineNC",
	Terminal = "Normal",
	TermCursor = "Cursor",
	lCursor = "Cursor",
	debugBreakpoint = "ModeMsg",
	debugPC = "CursorLine",

	-- Diff
	diffAdded = "Added",
	diffRemoved = "Removed",
	diffChanged = "Changed",
	diffNewFile = "Added",
	diffOldFile = "Removed",
	diffIndexLine = "Comment",
	diffSubname = "Comment",
	diffComment = "Comment",
	["@diff.plus"] = "Added",
	["@diff.minus"] = "Removed",
	["@diff.delta"] = "Changed",

	-- gitsigns.nvim
	GitSignsAdd = "Added",
	GitSignsChange = "Changed",
	GitSignsDelete = "Removed",
	GitSignsAddNr = "Added",
	GitSignsChangeNr = "Changed",
	GitSignsDeleteNr = "Removed",
	GitSignsAddLn = "DiffAdd",
	GitSignsChangeLn = "DiffChange",
	GitSignsAddInline = "DiffAddText",
	GitSignsChangeInline = "DiffText",
	GitSignsDeleteInline = "DiffDeleteText",
	GitSignsAddPreview = "DiffAdd",
	GitSignsDeletePreview = "DiffDelete",
	GitSignsDeleteVirtLn = "DiffDelete",
	GitSignsDeleteVirtLnInLine = "DiffDeleteText",

	-- blink.cmp
	BlinkCmpMenu = "Pmenu",
	BlinkCmpMenuBorder = "FloatBorder",
	BlinkCmpMenuSelection = "PmenuSel",
	BlinkCmpScrollBarThumb = "PmenuThumb",
	BlinkCmpScrollBarGutter = "PmenuSbar",
	BlinkCmpLabel = "Pmenu",
	BlinkCmpLabelMatch = "PmenuMatch",
	BlinkCmpKind = "PmenuKind",
	BlinkCmpSource = "PmenuExtra",
	BlinkCmpDoc = "NormalFloat",
	BlinkCmpDocBorder = "FloatBorder",
	BlinkCmpDocSeparator = "FloatBorder",
	BlinkCmpSignatureHelp = "NormalFloat",
	BlinkCmpSignatureHelpBorder = "FloatBorder",

	-- nvim-cmp
	CmpItemAbbrMatch = "PmenuMatch",
	CmpItemAbbrMatchFuzzy = "PmenuMatch",
	CmpItemKind = "PmenuKind",
	CmpItemMenu = "PmenuExtra",

	-- Markdown legacy :syntax groups (regex highlighter)
	markdownH1 = "@markup.heading.1.markdown",
	markdownH2 = "@markup.heading.2.markdown",
	markdownH3 = "@markup.heading.3.markdown",
	markdownH4 = "@markup.heading.4.markdown",
	markdownH5 = "@markup.heading.5.markdown",
	markdownH6 = "@markup.heading.6.markdown",
	markdownHeadingDelimiter = "@markup.heading.marker.markdown",
	markdownHeadingRule = "@markup.heading.marker.markdown",
	markdownCode = "@markup.raw.markdown_inline",
	markdownCodeBlock = "@markup.raw.block.markdown",
	markdownCodeDelimiter = "@markup.raw.delimiter.markdown",
	markdownBlockquote = "@markup.quote.markdown",
	markdownListMarker = "@markup.list.markdown",
	markdownOrderedListMarker = "@markup.list.markdown",
	markdownRule = "@punctuation.special.markdown",
	markdownBold = "@markup.strong.markdown_inline",
	markdownItalic = "@markup.italic.markdown_inline",
	markdownBoldItalic = "@markup.strong.markdown_inline",
	markdownStrike = "@markup.strikethrough.markdown_inline",
	markdownLinkText = "@markup.link.label.markdown_inline",
	markdownUrl = "@markup.link.url.markdown_inline",
	markdownLinkDelimiter = "@markup.link.markdown_inline",
	markdownIdDelimiter = "@markup.link.markdown_inline",
	markdownAutomaticLink = "@markup.link.url.markdown_inline",
	markdownEscape = "@string.escape.markdown_inline",
}

-- Apply

vim.o.background = "dark"

for i, color in ipairs(p.terminal) do
	vim.g["terminal_color_" .. (i - 1)] = color
end

apply(links)
apply(editor)
apply(syntax)
apply(popup)
apply(treesitter)
apply(diagnostics)
apply(diff)
apply(markdown)

-- Autocommands

local frontmatter_ns = vim.api.nvim_create_namespace("hollow_markdown")

for name, spec in pairs(frontmatter) do
	set_hl(frontmatter_ns, name, spec)
end

local function sync_frontmatter_ns()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "markdown" then
			vim.api.nvim_win_set_hl_ns(win, frontmatter_ns)
			vim.w[win].hollow_markdown_ns = true
		elseif vim.w[win].hollow_markdown_ns then
			vim.api.nvim_win_set_hl_ns(win, 0)
			vim.w[win].hollow_markdown_ns = nil
		end
	end
end

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "BufEnter", "WinEnter" }, {
	group = vim.api.nvim_create_augroup("HollowMarkdown", { clear = true }),
	callback = sync_frontmatter_ns,
})

sync_frontmatter_ns()
