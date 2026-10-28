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
	fg = "#d6d6d6", -- default text
	fg_alt = "#d6d6d6", -- statements, types, preproc
	string = "#d6d6d6",
	punct = "#e2e2e2",
	tailwind = "#e2e2e2",
	dim = "#707070",
	comment = "#787470",
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
		italic = "#949494",
		strike = "#6c6c6c",
		marker = "#585858",
		block = "#b2b2b2",
		string = "#cecece", -- yaml string values
		code = "#93a0b4", -- blue-gray tint, brighter than italic
		accent = "#738296", -- same tint, dimmer, exclusive color for markup markers
	},

	-- Micro-palette for tiny luminance steps so structure, operations and
	-- values separate without ever reading as "color"
	t = {
		op = "#ebebeb", -- + - = == => && ||
		special = "#f6f6f6", -- ${}, escapes, special regex chars
		const = "#e3e3e3", -- numbers, booleans, nil
		prop = "#c9c9c9", -- fields and properties (obj.field)
		bracket = "#bcbcbc", -- ( ) [ ] { }
		delim = "#989898", -- , ; . :
	},

	-- Constrast version
	-- t = {
	-- 	op = "#f6f6f6", -- + - = == => && ||
	-- 	special = "#ffffff", -- ${}, escapes, special regex chars
	-- 	const = "#ededed", -- numbers, booleans, nil
	-- 	prop = "#b4b4b4", -- fields and properties (obj.field)
	-- 	bracket = "#9a9a9a", -- ( ) [ ] { }
	-- 	delim = "#808080", -- , ; . :
	-- },
}

local md = p.markdown
local t = p.t

-- Helpers

local GUI_ATTRS = { "bold", "italic", "underline", "undercurl", "reverse", "strikethrough" }

-- xterm-256 has a 6x6x6 color cube (levels 0,95,135,175,215,255) and a
-- 24-step gray ramp (8,18,...,238). For every hex we compute the closest
-- candidate in each and keep the nearest one (euclidean RGB distance).
-- Results are cached, so the cost is paid once per distinct color

local CUBE = { 0, 95, 135, 175, 215, 255 }
local cterm_cache = {}

local function rgb(hex)
	return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

local function dist2(r1, g1, b1, r2, g2, b2)
	return (r1 - r2) ^ 2 + (g1 - g2) ^ 2 + (b1 - b2) ^ 2
end

local function nearest_cube_level(v)
	local best_i, best_d = 1, math.huge
	for i, c in ipairs(CUBE) do
		local d = math.abs(v - c)
		if d < best_d then
			best_i, best_d = i, d
		end
	end
	return best_i - 1
end

local function hex_to_256(hex)
	if cterm_cache[hex] then
		return cterm_cache[hex]
	end

	local r, g, b = rgb(hex)

	-- Best color-cube candidate
	local ri, gi, bi = nearest_cube_level(r), nearest_cube_level(g), nearest_cube_level(b)
	local cube_d = dist2(r, g, b, CUBE[ri + 1], CUBE[gi + 1], CUBE[bi + 1])

	-- Best gray-ramp candidate
	local step = math.max(0, math.min(23, math.floor(((r + g + b) / 3 - 8) / 10 + 0.5)))
	local gv = 8 + 10 * step
	local gray_d = dist2(r, g, b, gv, gv, gv)

	local idx = gray_d < cube_d and (232 + step) or (16 + 36 * ri + 6 * gi + bi)
	cterm_cache[hex] = idx
	return idx
end

local function is_hex(v)
	return type(v) == "string" and v:match("^#%x%x%x%x%x%x$") ~= nil
end

-- Turns a group spec into `nvim_set_hl` options.
-- ctermfg/ctermbg are derived from fg/bg unless given explicitly.
local function normalize(spec)
	if type(spec) == "string" then
		return { link = spec, force = true }
	end

	local opts = vim.deepcopy(spec)

	if is_hex(opts.fg) and not opts.ctermfg then
		opts.ctermfg = hex_to_256(opts.fg)
	end
	if is_hex(opts.bg) and not opts.ctermbg then
		opts.ctermbg = hex_to_256(opts.bg)
	end

	if not opts.cterm then
		opts.cterm = {}
		for _, attr in ipairs(GUI_ATTRS) do
			if opts[attr] then
				-- terminals without undercurl support fall back to underline
				opts.cterm[attr == "undercurl" and "underline" or attr] = true
			end
		end
	end
	return opts
end

local function apply(groups, ns)
	for name, spec in pairs(groups) do
		set_hl(ns or 0, name, normalize(spec))
	end
end

-- Highlight groups

-- Editor UI
local editor = {
	-- Base
	Normal = { fg = p.fg, bg = p.black },
	Cursor = { fg = p.black, bg = p.white },
	CursorLine = { bg = p.line },
	CursorColumn = { bg = p.surface_hi },
	CursorLineNr = { fg = p.fg, bg = p.line, bold = true },
	ColorColumn = { bg = p.surface },
	Conceal = {},
	LineNr = { fg = p.line_nr },
	SignColumn = { fg = p.fg, bg = p.black },
	FoldColumn = { fg = p.dim, bg = p.black },
	Folded = { fg = p.dim, bg = p.black },
	EndOfBuffer = { fg = p.dim },
	NonText = { fg = p.dim },
	SpecialKey = { fg = p.dim, bold = true },
	Directory = { fg = p.fg },
	MatchParen = { fg = p.search_fg, bold = true },
	QuickFixLine = { bg = p.line, bold = true },
	VertSplit = { fg = p.dim, bg = p.black },

	-- Selection and search
	Visual = { bg = p.border },
	VisualNOS = { bg = p.surface_hi },
	Search = { fg = p.search_fg, bg = p.search_bg },
	IncSearch = { fg = p.search_bg, bg = p.search_fg, bold = true },
	CurSearch = { fg = p.search_bg, bg = p.search_fg, bold = true },

	-- Messages
	ModeMsg = { fg = p.fg, bg = p.black, bold = true },
	MoreMsg = { fg = p.fg, bg = p.black },
	MsgArea = { fg = p.fg, bg = p.black },
	MsgSeparator = { fg = p.border, bg = p.black },
	Question = { fg = p.fg, bg = p.black },
	WarningMsg = { fg = p.warn, bg = p.black },
	ErrorMsg = { fg = p.error, bg = p.black, bold = true },
	Error = { fg = p.error, bg = p.black, bold = true, reverse = true },
	Todo = { fg = p.black, bg = p.warn, bold = true },

	-- Statusline, tabline, titlebar, toolbar
	StatusLine = { fg = p.statusline_fg, bg = p.line },
	StatusLineNC = { fg = p.statusline_nc_fg, bg = p.black },
	TabLine = { fg = p.dim, bg = p.black },
	TabLineFill = { fg = p.fg, bg = p.black },
	TabLineSel = { fg = p.fg, bg = p.black, bold = true },
	TitleBar = { fg = p.fg, bg = p.black },
	TitleBarNC = { fg = p.dim, bg = p.black },
	ToolbarButton = { fg = p.fg, bg = p.black, bold = true },
	ToolbarLine = { bg = p.black },

	-- Spell
	SpellBad = { fg = p.error, sp = p.error, undercurl = true },
	SpellCap = { fg = p.warn, sp = p.warn, undercurl = true },
	SpellLocal = { fg = p.dim, sp = p.dim, undercurl = true },
	SpellRare = { fg = p.dim, sp = p.dim, undercurl = true },
}

-- Popups and floating windows
local popup = {
	NormalFloat = { fg = p.fg, bg = p.popup_bg },
	FloatBorder = { fg = p.border, bg = p.popup_bg },
	FloatTitle = { fg = p.fg, bg = p.popup_bg },
	FloatFooter = { fg = p.dim, bg = p.popup_bg },

	Pmenu = { fg = p.fg, bg = p.popup_bg },
	PmenuSel = { fg = p.fg, bg = p.surface },
	PmenuExtra = { fg = p.dim, bg = p.popup_bg },
	PmenuExtraSel = { fg = p.fg, bg = p.surface_hi },
	PmenuKind = { fg = p.dim, bg = p.popup_bg },
	PmenuKindSel = { fg = p.fg, bg = p.surface_hi },
	PmenuMatch = { fg = p.white, bg = p.popup_bg, bold = true },
	PmenuMatchSel = { fg = p.white, bg = p.surface_hi, bold = true },
	PmenuSbar = { bg = p.popup_bg },
	PmenuThumb = { bg = p.border },
	WildMenu = { fg = p.fg, bg = p.surface_hi },
}

-- Vim syntax groups
local syntax = {
	Comment = { fg = p.comment },
	Constant = { fg = t.const },
	Number = { fg = t.const },
	String = { fg = p.string },
	Identifier = { fg = p.fg },
	Function = { fg = p.fg },
	Statement = { fg = p.fg_alt },
	Type = { fg = p.fg_alt },
	PreProc = { fg = p.fg_alt },
	Special = { fg = p.fg },
	Ignore = { fg = p.fg },
	Underlined = { fg = p.fg, underline = true },
	Title = { fg = p.fg, bold = true },

	Delimiter = { fg = t.delim },
	Operator = { fg = t.op },
}

-- Treesitter and LSP semantic tokens
local treesitter = {
	-- Comments
	["@comment.documentation"] = { fg = p.doc },

	-- Structure
	["@module"] = { fg = p.fg_alt },
	["@attribute"] = { fg = p.doc, italic = true },

	-- Functions (never bold)
	["@function"] = { fg = p.fg },
	["@function.method"] = { fg = p.fg },
	["@function.call"] = { fg = p.fg },
	["@function.method.call"] = { fg = p.fg },
	["@function.builtin"] = { fg = p.fg },

	-- LSP semantic tokens
	["@lsp.type.function"] = { fg = p.fg },
	["@lsp.type.method"] = { fg = p.fg },
	["@lsp.typemod.function.declaration"] = {},
	["@lsp.typemod.method.declaration"] = {},
	["@lsp.type.operator"] = { fg = t.op },
	["@lsp.type.property"] = { fg = t.prop },

	-- Variables
	["@variable.parameter"] = { fg = p.fg, italic = true },
	["@variable.builtin"] = { fg = p.fg_alt, italic = true },
	["@variable.member"] = { fg = t.prop },
	["@property"] = { fg = t.prop },

	-- Literals
	["@boolean"] = { fg = p.fg },
	["@constant.builtin"] = { fg = t.const },
	["@string.escape"] = { fg = t.special },
	["@string.special"] = { fg = t.special },

	-- Punctuation and operators
	["@punctuation"] = { fg = t.delim },
	["@punctuation.bracket"] = { fg = t.bracket },
	["@punctuation.delimiter"] = { fg = t.delim },
	["@punctuation.special"] = { fg = t.special }, -- ${ } in template strings
	["@operator"] = { fg = t.op },
	["@keyword.operator"] = { fg = t.op }, -- and, or, not, in, instanceof

	-- Tags
	["@tag"] = { fg = p.fg_alt },
	["@tag.delimiter"] = { fg = t.bracket },
	["@tag.attribute"] = { fg = p.fg_alt, italic = true },

	-- Generic markup
	["@markup.heading"] = { fg = p.fg, bold = true },
	["@markup.strong"] = { bold = true },
	["@markup.italic"] = { italic = true },
	["@markup.link"] = { fg = p.fg_alt, underline = true },
	["@markup.raw"] = { fg = p.fg_alt },

	-- Regex
	["@string.regexp"] = { fg = p.regex.string },
	["@character.special"] = { fg = t.special },
	["@operator.regex"] = { fg = p.warn },
	["@keyword.operator.regex"] = { fg = p.warn },
	["@punctuation.bracket.regex"] = { fg = p.dim },
	["@punctuation.delimiter.regex"] = { fg = p.regex.delimiter },
	["@property.regex"] = { fg = p.regex.property, italic = true },
	["@variable.builtin.regex"] = { fg = p.fg_alt },
}

-- Diagnostics and LSP
local diagnostics = {
	DiagnosticError = { fg = p.error },
	DiagnosticWarn = { fg = p.warn },
	DiagnosticInfo = { fg = p.fg_alt },
	DiagnosticHint = { fg = p.comment },
	DiagnosticOk = { fg = p.ok },
	DiagnosticUnnecessary = { fg = p.comment },

	DiagnosticUnderlineError = { sp = p.error, undercurl = true },
	DiagnosticUnderlineWarn = { sp = p.warn, undercurl = true },
	DiagnosticUnderlineInfo = { sp = p.fg_alt, undercurl = true },
	DiagnosticUnderlineHint = { sp = p.comment, undercurl = true },

	LspInlayHint = { fg = p.comment, bg = p.inlay_bg, italic = true },
	LspReferenceText = { bg = p.surface },
	LspReferenceRead = { bg = p.surface },
	LspReferenceWrite = { bg = p.surface, underline = true },
}

-- Diff
local diff = {
	-- Lines
	DiffAdd = { fg = p.fg, bg = p.diff.add_bg },
	DiffChange = { fg = p.fg, bg = p.diff.change_bg },
	DiffDelete = { fg = p.diff.removed, bg = p.diff.delete_bg },

	-- Text inside a line
	DiffText = { fg = p.white, bg = p.diff.text_bg, bold = true },
	DiffAddText = { fg = p.white, bg = p.diff.add_text_bg, bold = true },
	DiffDeleteText = { fg = p.white, bg = p.diff.delete_text_bg, bold = true },

	-- Signs and diff syntax
	Added = { fg = p.diff.added },
	Changed = { fg = p.diff.changed },
	Removed = { fg = p.diff.removed },
	diffFile = { fg = p.fg, bold = true },
	diffLine = { fg = p.diff.line },
}

-- Markdown

local markdown = {
	-- Frontmatter fences (---)
	["@keyword.directive.markdown"] = { fg = md.accent },

	-- Structural punctuation
	["@punctuation.special.markdown"] = { fg = p.fg },
	["@punctuation.delimiter.markdown"] = { fg = p.fg },

	-- Lists and task items
	["@markup.list.markdown"] = { fg = md.accent, bold = true },
	["@markup.list.checked.markdown"] = { fg = md.accent, bold = true },
	["@markup.list.unchecked.markdown"] = { fg = md.accent, bold = true },

	-- Blockquote
	["@markup.quote.markdown"] = { fg = md.italic, italic = true },

	-- Code blocks
	["@markup.raw.block.markdown"] = { fg = md.block },
	["@markup.raw.delimiter.markdown"] = { fg = md.accent },
	["@label.markdown"] = { fg = md.accent, italic = true },

	-- Inline emphasis
	["@markup.strong.markdown_inline"] = { fg = p.white, bold = true },
	["@markup.italic.markdown_inline"] = { fg = md.italic, italic = true },
	["@markup.strikethrough.markdown_inline"] = { fg = md.strike, strikethrough = true },

	-- Inline code and math
	["@markup.raw.markdown_inline"] = { fg = md.code },
	["@markup.math.markdown_inline"] = { fg = md.code },
	["@markup.math.markdown"] = { fg = md.code },
	["@markup.math.latex"] = { fg = md.code }, -- injected latex inside math (also affects .tex)
	["@punctuation.special.markdown_inline"] = { fg = md.code }, -- $ delimiters

	-- Inline links
	["@markup.link.markdown_inline"] = { fg = md.marker },
	["@markup.link.label.markdown_inline"] = { fg = md.code, underline = true },
	["@markup.link.url.markdown_inline"] = { fg = p.accent, underline = true },

	-- Inline escapes and conceal
	["@string.escape.markdown_inline"] = { fg = md.accent },
	["@conceal.markdown_inline"] = { fg = md.marker },
}

-- Headings (generated from the gradient table)
do
	local levels = {
		p.white,
		p.fg,
		p.fg_alt,
		p.string,
		p.string,
		p.string,
	}

	markdown["@markup.heading.markdown"] = { fg = levels[1], bold = true }
	markdown["@markup.heading.marker.markdown"] = { fg = levels[1] }

	for i, color in ipairs(levels) do
		markdown[("@markup.heading.%d.markdown"):format(i)] = { fg = color, bold = true }
		markdown[("@markup.heading.%d.marker.markdown"):format(i)] = { fg = color }
	end
end

-- Frontmatter (YAML injected into markdown), applied through its own namespace
local frontmatter = {
	["@property.yaml"] = { fg = md.accent }, -- keys
	["@string.yaml"] = { fg = md.string }, -- string values
	["@number.yaml"] = { fg = md.accent },
	["@number.float.yaml"] = { fg = md.accent },
	["@boolean.yaml"] = { fg = md.accent },
	["@constant.builtin.yaml"] = { fg = md.accent }, -- null
	["@label.yaml"] = { fg = md.accent }, -- anchors / aliases
	["@type.yaml"] = { fg = md.accent }, -- tags
	["@punctuation.delimiter.yaml"] = { fg = md.marker }, -- : - ,
	["@punctuation.bracket.yaml"] = { fg = md.marker }, -- [ ] { }
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

apply(frontmatter, frontmatter_ns)

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
