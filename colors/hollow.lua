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

local _ = false

local fg0 = "#c8c8c8"
local fg1 = "#c8c8c8"
local str = "#c8c8c8"
local dim = "#707070"
local cmt = "#6a6a6a"
local doc = "#7a7a7a"

local accent = "#6382eb"
local accent_dim = "#1b2152"

local punct = "#e2e2e2"
local tw = "#e2e2e2"

local err = "#b86a6a"
local warn = "#b09b72"
local ok = "#678a67"

-- Palette used by the status line / search changes (single source of truth)
local c = {
	fg = "#e2e2e2",
	comment = "#636262",
	line = "#111111", -- cursorline, statusline, code blocks
}

local search_fg = "#D6C17A"
local search_bg = "#3D3525"

local function attrs(s)
	local t = {}
	if s then
		for a in s:gmatch("[^,]+") do
			if a ~= "NONE" then
				t[a] = true
			end
		end
	end
	return t
end

local function apply(defs)
	for _, d in ipairs(defs) do
		local name, fg, bg, sp, gui, cfg, cbg, cterm = unpack(d, 1, 8)
		local o = attrs(gui)
		if fg then
			o.fg = fg
		end
		if bg then
			o.bg = bg
		end
		if sp then
			o.sp = sp
		end
		if cfg then
			o.ctermfg = cfg
		end
		if cbg then
			o.ctermbg = cbg
		end
		o.cterm = attrs(cterm)
		set_hl(0, name, o)
	end
end

-- Links (hi! link)
local links = {
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
	MessageWindow = "Pmenu",
	PopupNotification = "Todo",
	PreCondit = "PreProc",
	Repeat = "Statement",
	SpecialChar = "Special",
	SpecialComment = "Special",
	StatusLineTerm = "StatusLine",
	StatusLineTermNC = "StatusLineNC",
	StorageClass = "Type",
	Structure = "Type",
	Tag = "Special",
	Terminal = "Normal",
	Typedef = "Type",
	debugBreakpoint = "ModeMsg",
	debugPC = "CursorLine",
	lCursor = "Cursor",
	TermCursor = "Cursor",

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

	GitSignsAdd = "Added",
	GitSignsChange = "Changed",
	GitSignsDelete = "Removed",
	GitSignsAddNr = "Added",
	GitSignsChangeNr = "Changed",
	GitSignsDeleteNr = "Removed",
	GitSignsAddInline = "DiffAdd",
	GitSignsChangeInline = "DiffChange",
	GitSignsDeleteInline = "DiffDelete",
	GitSignsAddPreview = "DiffAdd",
	GitSignsDeletePreview = "DiffDelete",

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

	CmpItemAbbrMatch = "PmenuMatch",
	CmpItemAbbrMatchFuzzy = "PmenuMatch",
	CmpItemKind = "PmenuKind",
	CmpItemMenu = "PmenuExtra",
}

local function terminal_colors(list)
	for i, c in ipairs(list) do
		vim.g["terminal_color_" .. (i - 1)] = c
	end
end

local dark = {
	{ "Normal", fg0, "#000000", _, "NONE", 254, 16, "NONE" },
	{ "ColorColumn", _, "#1c1c1c", _, "NONE", _, 234, "NONE" },
	{ "Conceal", _, _, _, "NONE", _, _, "NONE" },
	{ "Constant", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "Number", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "String", str, _, _, "NONE", 254, _, "NONE" },
	{ "CurSearch", search_bg, search_fg, _, "bold", 53, 135, "bold" },
	{ "CursorColumn", _, "#303030", _, "NONE", _, 236, "NONE" },
	{ "CursorIM", "#000000", accent, _, "NONE", 16, 62, "NONE" },
	{ "CursorLine", _, c.line, _, "NONE", _, 233, "NONE" },
	{ "CursorLineNr", fg0, c.line, _, "bold", 254, 233, "bold" },

	-- Diff backgrounds: very dark tints, close to the black background
	{ "DiffAdd", fg0, "#070f07", _, "NONE", 254, 233, "NONE" },
	{ "DiffChange", fg0, "#070b11", _, "NONE", 254, 233, "NONE" },
	{ "DiffDelete", err, "#100707", _, "NONE", 131, 233, "NONE" },
	{ "DiffText", fg0, "#120c1a", _, "NONE", 254, 234, "NONE" },

	-- Diff signs / text (gitsigns, `diff` filetype, treesitter): muted tones
	{ "Added", "#335533", _, _, "NONE", 22, _, "NONE" },
	{ "Changed", "#334a60", _, _, "NONE", 60, _, "NONE" },
	{ "Removed", "#7a4a4a", _, _, "NONE", 95, _, "NONE" },
	{ "diffFile", fg0, _, _, "bold", 254, _, "bold" },
	{ "diffLine", "#4a3560", _, _, "NONE", 60, _, "NONE" },

	{ "Directory", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "EndOfBuffer", dim, _, _, "NONE", 242, _, "NONE" },
	{ "Error", err, "#000000", _, "bold,reverse", 131, 16, "bold,reverse" },
	{ "ErrorMsg", err, "#000000", _, "bold", 131, 16, "bold" },
	{ "FoldColumn", dim, "#000000", _, "NONE", 242, 16, "NONE" },
	{ "Folded", dim, "#000000", _, "NONE", 242, 16, "NONE" },
	{ "Identifier", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "Ignore", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "IncSearch", search_bg, search_fg, _, "bold", 53, 135, "bold" },
	{ "LineNr", "#585858", _, _, "NONE", 240, _, "NONE" },
	{ "MatchParen", accent, _, _, "bold", 62, _, "bold" },
	{ "ModeMsg", fg0, "#000000", _, "bold", 254, 16, "bold" },
	{ "MoreMsg", fg0, "#000000", _, "NONE", 254, 16, "NONE" },
	{ "MsgArea", fg0, "#000000", _, "NONE", 254, 16, "NONE" },
	{ "MsgSeparator", "#444444", "#000000", _, "NONE", 238, 16, "NONE" },
	{ "NonText", dim, _, _, "NONE", 242, _, "NONE" },
	{ "PreProc", fg1, _, _, "NONE", 254, _, "NONE" },
	{ "Question", fg0, "#000000", _, "NONE", 254, 16, "NONE" },
	{ "QuickFixLine", _, c.line, _, "bold", _, 233, "bold" },
	{ "Search", search_fg, search_bg, _, "NONE", 135, 53, "NONE" },
	{ "SignColumn", fg0, "#000000", _, "NONE", 254, 16, "NONE" },
	{ "Special", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "SpecialKey", dim, _, _, "bold", 242, _, "bold" },
	{ "SpellBad", err, _, err, "undercurl", 131, _, "underline" },
	{ "SpellCap", warn, _, warn, "undercurl", 137, _, "underline" },
	{ "SpellLocal", dim, _, dim, "undercurl", 242, _, "underline" },
	{ "SpellRare", dim, _, dim, "undercurl", 242, _, "underline" },
	{ "StatusLine", c.fg, c.line, _, "NONE", 254, 233, "NONE" },
	{ "StatusLineNC", c.comment, c.line, _, "NONE", 241, 233, "NONE" },
	{ "TabLine", dim, "#000000", _, "NONE", 242, 16, "NONE" },
	{ "TabLineFill", fg0, "#000000", _, "NONE", 254, 16, "NONE" },
	{ "TabLineSel", fg0, "#000000", _, "bold", 254, 16, "bold" },
	{ "TitleBar", fg0, "#000000", _, "NONE", 254, 16, "NONE" },
	{ "TitleBarNC", dim, "#000000", _, "NONE", 242, 16, "NONE" },
	{ "Todo", "#000000", warn, _, "bold", 16, 137, "bold" },
	{ "ToolbarButton", fg0, "#000000", _, "bold", 254, 16, "bold" },
	{ "ToolbarLine", _, "#000000", _, "NONE", _, 16, "NONE" },
	{ "Underlined", fg0, _, _, "underline", 254, _, "underline" },
	{ "VertSplit", dim, "#000000", _, "NONE", 242, 16, "NONE" },
	{ "Visual", _, "#444444", _, "NONE", _, 238, "NONE" },
	{ "VisualNOS", _, "#303030", _, "NONE", _, 236, "NONE" },
	{ "WarningMsg", warn, "#000000", _, "NONE", 137, 16, "NONE" },
}

local popups = {
	{ "NormalFloat", fg0, "#000000", _, "NONE", 254, 16, "NONE" },
	{ "FloatBorder", "#444444", "#000000", _, "NONE", 238, 16, "NONE" },
	{ "FloatTitle", fg0, "#000000", _, "NONE", 254, 16, "NONE" },
	{ "FloatFooter", dim, "#000000", _, "NONE", 242, 16, "NONE" },
	{ "Pmenu", fg0, "#000000", _, "NONE", 254, 16, "NONE" },
	{ "PmenuExtra", dim, "#000000", _, "NONE", 242, 16, "NONE" },
	{ "PmenuExtraSel", fg0, "#303030", _, "NONE", 254, 236, "NONE" },
	{ "PmenuKind", dim, "#000000", _, "NONE", 242, 16, "NONE" },
	{ "PmenuKindSel", fg0, "#303030", _, "NONE", 254, 236, "NONE" },
	{ "PmenuMatch", "#ffffff", "#000000", _, "bold", 231, 16, "bold" },
	{ "PmenuMatchSel", "#ffffff", "#303030", _, "bold", 231, 236, "bold" },
	{ "PmenuSbar", _, "#000000", _, "NONE", _, 16, "NONE" },
	{ "PmenuSel", fg0, c.line, _, "NONE", 254, 233, "NONE" },
	{ "PmenuThumb", _, "#444444", _, "NONE", _, 238, "NONE" },
	{ "WildMenu", fg0, "#303030", _, "NONE", 254, 236, "NONE" },
}

-- Modern groups
local modern = {
	-- Comments
	{ "Comment", cmt, _, _, "NONE", 241, _, "NONE" },
	{ "@comment.documentation", doc, _, _, "NONE", 243, _, "NONE" },

	-- Structure
	{ "Statement", fg1, _, _, "NONE", 254, _, "NONE" },
	{ "Type", fg1, _, _, "NONE", 254, _, "NONE" },
	{ "@module", fg1, _, _, "NONE", 254, _, "NONE" },
	{ "@attribute", doc, _, _, "italic", 243, _, "italic" },

	-- Functions never bold
	{ "Function", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@function", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@function.method", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@function.call", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@function.method.call", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@function.builtin", fg0, _, _, "NONE", 254, _, "NONE" },
	-- LSP semantic tokens
	{ "@lsp.type.function", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@lsp.type.method", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@lsp.typemod.function.declaration", _, _, _, "NONE", _, _, "NONE" },
	{ "@lsp.typemod.method.declaration", _, _, _, "NONE", _, _, "NONE" },

	-- Variables
	{ "@variable.parameter", fg0, _, _, "italic", 254, _, "italic" },
	{ "@variable.builtin", fg1, _, _, "italic", 254, _, "italic" },

	-- Literal values (no accent: everything shares the default fg)
	{ "@constant.builtin", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@string.escape", fg0, _, _, "NONE", 254, _, "NONE" },

	-- Punctuation and operators: brackets and operators use the default text
	-- color; only separators (, ; :) are dimmed
	{ "Delimiter", punct, _, _, "NONE", 254, _, "NONE" },
	{ "@punctuation", punct, _, _, "NONE", 254, _, "NONE" },
	{ "@punctuation.bracket", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@punctuation.delimiter", punct, _, _, "NONE", 254, _, "NONE" },
	{ "Operator", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@operator", fg0, _, _, "NONE", 254, _, "NONE" },

	-- Tags
	{ "@tag", fg1, _, _, "NONE", 254, _, "NONE" },
	{ "@tag.delimiter", punct, _, _, "NONE", 254, _, "NONE" },
	{ "@tag.attribute", fg1, _, _, "italic", 254, _, "italic" },

	-- Diagnostics
	{ "DiagnosticError", err, _, _, "NONE", 131, _, "NONE" },
	{ "DiagnosticWarn", warn, _, _, "NONE", 137, _, "NONE" },
	{ "DiagnosticInfo", fg1, _, _, "NONE", 254, _, "NONE" },
	{ "DiagnosticHint", cmt, _, _, "NONE", 241, _, "NONE" },
	{ "DiagnosticOk", ok, _, _, "NONE", 65, _, "NONE" },
	{ "DiagnosticUnderlineError", _, _, err, "undercurl", _, _, "underline" },
	{ "DiagnosticUnderlineWarn", _, _, warn, "undercurl", _, _, "underline" },
	{ "DiagnosticUnderlineInfo", _, _, fg1, "undercurl", _, _, "underline" },
	{ "DiagnosticUnderlineHint", _, _, cmt, "undercurl", _, _, "underline" },
	{ "DiagnosticUnnecessary", cmt, _, _, "NONE", 241, _, "NONE" },

	-- LSP
	{ "LspInlayHint", cmt, "#0a0a0a", _, "italic", 241, 233, "italic" },
	{ "LspReferenceText", _, "#1c1c1c", _, "NONE", _, 234, "NONE" },
	{ "LspReferenceRead", _, "#1c1c1c", _, "NONE", _, 234, "NONE" },
	{ "LspReferenceWrite", _, "#1c1c1c", _, "underline", _, 234, "underline" },

	-- Markup, markdown (generic)
	{ "Title", fg0, _, _, "bold", 254, _, "bold" },
	{ "@markup.heading", fg0, _, _, "bold", 254, _, "bold" },
	{ "@markup.strong", _, _, _, "bold", _, _, "bold" },
	{ "@markup.italic", _, _, _, "italic", _, _, "italic" },
	{ "@markup.link", fg1, _, _, "underline", 254, _, "underline" },
	{ "@markup.raw", fg1, _, _, "NONE", 254, _, "NONE" },

	-- Regex
	{ "@string.regexp", "#8a94a0", _, _, "NONE", 245, _, "NONE" },
	{ "@character.special", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@operator.regex", warn, _, _, "NONE", 137, _, "NONE" },
	{ "@keyword.operator.regex", warn, _, _, "NONE", 137, _, "NONE" },
	{ "@punctuation.bracket.regex", dim, _, _, "NONE", 242, _, "NONE" },
	{ "@punctuation.delimiter.regex", "#946060", _, _, "NONE", 95, _, "NONE" },
	{ "@property.regex", "#5f7f5f", _, _, "italic", 65, _, "italic" },
	{ "@variable.builtin.regex", fg1, _, _, "NONE", 254, _, "NONE" },
}

-- JSX, TSX, React and Tailwind only
--
-- These groups are only produced by the treesitter queries in
-- after/queries/{tsx,javascript}/highlights.scm, so every other filetype is
-- unaffected. Without those query files they simply never match
local jsx = {
	{ "@tag.component", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@tag.intrinsic", fg1, _, _, "NONE", 254, _, "NONE" },
	{ "@function.call.hook", fg1, _, _, "NONE", 254, _, "NONE" },
	{ "@string.tailwind", tw, _, _, "NONE", 254, _, "NONE" },
}

-- Oil (stevearc/oil.nvim)
--
-- All entries share the default fg color (#e2e2e2). Only status indicators
-- (hidden, errors, warnings) keep their semantic colors.
local oil = {
	{ "OilDir", fg0, _, _, "bold", 254, _, "bold" },
	{ "OilDirIcon", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "OilFile", fg1, _, _, "NONE", 254, _, "NONE" },
	{ "OilLink", fg1, _, _, "italic", 254, _, "italic" },
	{ "OilLinkTarget", dim, _, _, "italic", 242, _, "italic" },
	{ "OilOrphanLink", err, _, _, "italic", 131, _, "italic" },
	{ "OilOrphanLinkTarget", err, _, _, "italic", 131, _, "italic" },
	{ "OilHidden", cmt, _, _, "NONE", 241, _, "NONE" },

	{ "OilCreate", fg0, _, _, "bold", 254, _, "bold" },
	{ "OilCopy", fg0, _, _, "bold", 254, _, "bold" },
	{ "OilMove", warn, _, _, "NONE", 137, _, "NONE" },
	{ "OilChange", warn, _, _, "NONE", 137, _, "NONE" },
	{ "OilDelete", err, _, _, "NONE", 131, _, "NONE" },
	{ "OilPurge", err, _, _, "bold", 131, _, "bold" },
	{ "OilRestore", fg0, _, _, "bold", 254, _, "bold" },
	{ "OilTrash", dim, _, _, "NONE", 242, _, "NONE" },
	{ "OilTrashSourcePath", cmt, _, _, "NONE", 241, _, "NONE" },

	{ "OilTypeDir", fg0, _, _, "bold", 254, _, "bold" },
	{ "OilTypeFile", dim, _, _, "NONE", 242, _, "NONE" },
	{ "OilTypeLink", fg1, _, _, "NONE", 254, _, "NONE" },
	{ "OilTypeFifo", dim, _, _, "NONE", 242, _, "NONE" },
	{ "OilTypeSocket", dim, _, _, "NONE", 242, _, "NONE" },
	{ "OilTypeUnknown", dim, _, _, "NONE", 242, _, "NONE" },

	{ "OilPermissionNone", cmt, _, _, "NONE", 241, _, "NONE" },
	{ "OilPermissionRead", warn, _, _, "NONE", 137, _, "NONE" },
	{ "OilPermissionWrite", err, _, _, "NONE", 131, _, "NONE" },
	{ "OilPermissionExecute", "#5f9a5f", _, _, "NONE", 71, _, "NONE" },

	{ "OilExecutable", "#9e9e9e", _, _, "bold", 247, _, "bold" },
	{ "OilSocket", dim, _, _, "NONE", 242, _, "NONE" },
	{ "OilDirHidden", cmt, _, _, "bold", 241, _, "bold" },
	{ "OilFileHidden", cmt, _, _, "NONE", 241, _, "NONE" },
	{ "OilLinkHidden", cmt, _, _, "italic", 241, _, "italic" },
	{ "OilOrphanLinkHidden", err, _, _, "italic", 131, _, "italic" },
}

-- Markdown only

-- Exact xterm-256 values, so cterm matches GUI
local md = {
	italic = "#a8a8a8", -- 248
	strike = "#6c6c6c", -- 242
	marker = "#585858", -- 240
	block = "#b2b2b2", -- 249
	string = "#cecece", -- 252 (yaml string values)
	code = "#98a4f2", -- 111, light tint of the accent family
	link_url = accent, -- 62
	accent = "#af87af", -- 139, exclusive color for markup markers
}

-- Heading gradient
local heading_levels = {
	{ "#ffffff", 231 },
	{ fg0, 254 },
	{ fg1, 254 },
	{ str, 254 },
	{ str, 254 },
	{ str, 254 },
}

local markdown = {
	-- Frontmatter fences (---)
	{ "@keyword.directive.markdown", md.accent, _, _, "NONE", 139, _, "NONE" },

	-- Structural punctuation
	{ "@punctuation.special.markdown", fg0, _, _, "NONE", 254, _, "NONE" },
	{ "@punctuation.delimiter.markdown", fg0, _, _, "NONE", 254, _, "NONE" },

	-- Lists and task items
	{ "@markup.list.markdown", md.accent, _, _, "bold", 139, _, "bold" },
	{ "@markup.list.checked.markdown", md.accent, _, _, "bold", 139, _, "bold" },
	{ "@markup.list.unchecked.markdown", md.accent, _, _, "bold", 139, _, "bold" },

	-- Blockquote
	{ "@markup.quote.markdown", md.italic, _, _, "italic", 248, _, "italic" },

	-- Code blocks
	{ "@markup.raw.block.markdown", md.block, _, _, "NONE", 249, _, "NONE" },
	{ "@markup.raw.delimiter.markdown", md.accent, _, _, "NONE", 139, _, "NONE" },
	{ "@label.markdown", md.accent, _, _, "italic", 139, _, "italic" },

	-- Inline emphasis
	{ "@markup.strong.markdown_inline", "#ffffff", _, _, "bold", 231, _, "bold" },
	{ "@markup.italic.markdown_inline", md.italic, _, _, "italic", 248, _, "italic" },
	{ "@markup.strikethrough.markdown_inline", md.strike, _, _, "strikethrough", 242, _, "NONE" },

	-- Inline code and math
	{ "@markup.raw.markdown_inline", md.code, _, _, "NONE", 111, _, "NONE" },
	{ "@markup.math.markdown_inline", md.code, _, _, "NONE", 111, _, "NONE" },
	{ "@markup.math.markdown", md.code, _, _, "NONE", 111, _, "NONE" },
	{ "@markup.math.latex", md.code, _, _, "NONE", 111, _, "NONE" }, -- injected latex inside math (also affects .tex)
	{ "@punctuation.special.markdown_inline", md.code, _, _, "NONE", 111, _, "NONE" }, -- $ delimiters

	-- Inline links
	{ "@markup.link.markdown_inline", md.marker, _, _, "NONE", 240, _, "NONE" },
	{ "@markup.link.label.markdown_inline", md.code, _, _, "underline", 111, _, "underline" },
	{ "@markup.link.url.markdown_inline", md.link_url, _, _, "underline", 62, _, "underline" },

	-- Inline escapes and conceal
	{ "@string.escape.markdown_inline", md.accent, _, _, "NONE", 139, _, "NONE" },
	{ "@conceal.markdown_inline", md.marker, _, _, "NONE", 240, _, "NONE" },
}

-- Headings (generated from the gradient table)
do
	local first = heading_levels[1]
	table.insert(markdown, { "@markup.heading.markdown", first[1], _, _, "bold", first[2], _, "bold" })
	table.insert(markdown, { "@markup.heading.marker.markdown", first[1], _, _, "NONE", first[2], _, "NONE" })
	for i, h in ipairs(heading_levels) do
		table.insert(markdown, { ("@markup.heading.%d.markdown"):format(i), h[1], _, _, "bold", h[2], _, "bold" })
		table.insert(
			markdown,
			{ ("@markup.heading.%d.marker.markdown"):format(i), h[1], _, _, "NONE", h[2], _, "NONE" }
		)
	end
end

-- Markdown-specific links
local markdown_links = {
	-- Legacy :syntax groups (regex highlighter)
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

-- Frontmatter (YAML injected into markdown)
local frontmatter_ns = vim.api.nvim_create_namespace("hollow_markdown")

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

for name, o in pairs(frontmatter) do
	set_hl(frontmatter_ns, name, o)
end

for from, to in pairs(links) do
	set_hl(0, from, { link = to, force = true })
end

for from, to in pairs(markdown_links) do
	set_hl(0, from, { link = to, force = true })
end

vim.o.background = "dark"

terminal_colors({
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
})

apply(dark)
apply(oil)
apply(popups)
apply(modern)
apply(jsx)
apply(markdown)

-- Attach the frontmatter namespace only to windows showing markdown buffers
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

set_hl(0, "Cursor", { fg = "#000000", bg = fg0, ctermfg = 16, ctermbg = 254 })

vim.api.nvim_create_autocmd({ "FileType", "ColorScheme" }, {
	group = vim.api.nvim_create_augroup("HollowOil", { clear = true }),
	pattern = { "oil", "*" },
	callback = function(ev)
		if ev.event == "ColorScheme" and vim.g.colors_name ~= "hollow" then
			return
		end
		if ev.event == "FileType" and ev.match ~= "oil" then
			return
		end
		apply(oil)
	end,
})
