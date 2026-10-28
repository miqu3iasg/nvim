-- colors/classic.lua
--
-- For those who keep the tradition.
--
-- Copyright (c) Miquéias Alves Medeiros <https://github.com/miqu3iasg>
--
-- SPDX-License-Identifier: Vim

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.g.colors_name = "classic"

local set_hl = vim.api.nvim_set_hl

-- Pallete
local p = {
	-- Neutrals
	black = "#000000", -- background
	white = "#ffffff",
	fg = "#EFF0F0", -- default text (main, argc, *path, braces), cursor
	bright = "#ffffff", -- bold, titles
	gray = "#8a8a8a",
	ws = "#333333", -- whitespace chars

	-- Surfaces
	surface = "#1a1a1a", -- cursorline, colorcolumn, folds
	line = "#111111", -- statusline
	popup_bg = "#111111",
	popup_sel_bg = "#262626",

	-- Selection
	select_bg = "#a8a8a8",
	select_fg = "#000000",

	-- Statusline
	statusline_fg = "#e2e2e2",
	statusline_nc_fg = "#636262",

	-- Syntax
	comment = "#9292E0", -- comments
	blue = "#9292E0", -- comments, "~" empty lines, directories
	type = "#8dd6a1", -- int, const, char
	pink = "#d975d8", -- #include, special chars like %s
	yellow = "#E4B57F", -- return, if, for...
	orange = "#CD8E7B", -- <stdio.h>, strings
	red = "#d70000",

	-- Diagnostics
	error = "#d06060",

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

	-- Markdown
	markdown = {
		italic = "#a0a0a0",
		quote = "#7f7f7f",
		code = "#b0b0b0", -- inline code (light gray + subtle background)
		code_bg = "#1a1a1a",
		math = "#9aa3b5", -- inline math (very discreet blue-gray)
		meta = "#8fa3ad", -- frontmatter keys
	},
}

local md = p.markdown

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
	NormalNC = { fg = p.fg, bg = p.black },
	SignColumn = { bg = p.black },
	LineNr = { fg = p.gray, bg = p.black },
	CursorLine = { bg = p.surface },
	CursorLineNr = { fg = p.fg, bg = p.black, bold = true },
	ColorColumn = { bg = p.surface },
	Folded = { fg = p.gray, bg = p.surface },
	EndOfBuffer = { fg = p.blue, bg = p.black }, -- "~" at end of file
	NonText = { fg = p.blue },
	Whitespace = { fg = p.ws },
	Directory = { fg = p.blue },
	MatchParen = { fg = p.white, bg = p.red, bold = true },
	VertSplit = { fg = p.gray, bg = p.black },
	WinSeparator = { fg = p.gray, bg = p.black },

	-- Cursor (same color as the default text)
	Cursor = { fg = p.black, bg = p.fg },
	lCursor = { fg = p.black, bg = p.fg },
	TermCursor = { fg = p.black, bg = p.fg },

	-- Selection and search
	Visual = { fg = p.select_fg, bg = p.select_bg },
	Search = { fg = p.search_fg, bg = p.search_bg },
	IncSearch = { fg = p.search_bg, bg = p.search_fg, bold = true },
	CurSearch = { fg = p.search_bg, bg = p.search_fg, bold = true },

	-- Messages
	ModeMsg = { fg = p.fg, bold = true },
	MsgArea = { fg = p.fg, bg = p.black },
	ErrorMsg = { fg = p.white, bg = p.red },
	WarningMsg = { fg = p.yellow },
	Error = { fg = p.white, bg = p.red },
	Todo = { fg = p.black, bg = p.yellow, bold = true },

	-- Statusline
	StatusLine = { fg = p.statusline_fg, bg = p.black },
	StatusLineNC = { fg = p.statusline_nc_fg, bg = p.black },
}

-- Popups and floating windows
local popup = {
	NormalFloat = { fg = p.fg, bg = p.black },
	FloatBorder = { fg = p.gray, bg = p.black },

	Pmenu = { fg = p.fg, bg = p.popup_bg },
	PmenuSel = { fg = p.bright, bg = p.popup_sel_bg },
}

-- Vim syntax groups
local syntax = {
	Comment = { fg = p.comment },
	Constant = { fg = p.fg },
	String = { fg = p.orange },
	Character = { fg = p.orange },
	Number = { fg = p.pink },
	Boolean = { fg = p.fg },
	Float = { fg = p.orange },
	Identifier = { fg = p.fg },
	Function = { fg = p.fg },
	Statement = { fg = p.yellow }, -- return, break, continue...
	Conditional = { fg = p.yellow }, -- if, else, switch
	Repeat = { fg = p.yellow }, -- for, while, do
	Label = { fg = p.yellow }, -- case, default
	Operator = { fg = p.yellow }, -- sizeof (symbols use fg via treesitter)
	Exception = { fg = p.yellow }, -- try, catch, throw
	Keyword = { fg = p.fg }, -- public, class, static...
	PreProc = { fg = p.pink }, -- #include, #define
	Include = { fg = p.pink },
	Define = { fg = p.pink },
	Macro = { fg = p.pink },
	Type = { fg = p.type }, -- int, char
	StorageClass = { fg = p.fg },
	Structure = { fg = p.fg },
	Typedef = { fg = p.fg },
	Special = { fg = p.pink },
	SpecialChar = { fg = p.pink }, -- %s, \n...
	Delimiter = { fg = p.fg },
	Title = { fg = p.blue, bold = true },
}

-- Treesitter and LSP semantic tokens
local treesitter = {
	-- Keywords
	["@keyword"] = { fg = p.fg },
	["@keyword.function"] = { fg = p.fg },
	["@keyword.modifier"] = { fg = p.type }, -- const
	["@keyword.type"] = { fg = p.fg },
	["@keyword.storage"] = { fg = p.fg },
	["@keyword.return"] = { fg = p.yellow },
	["@keyword.conditional"] = { fg = p.yellow },
	["@keyword.repeat"] = { fg = p.yellow },
	["@keyword.exception"] = { fg = p.yellow },
	["@keyword.operator"] = { fg = p.yellow }, -- sizeof
	["@keyword.directive"] = { fg = p.pink }, -- #include
	["@keyword.import"] = { fg = p.pink },
	["@conditional"] = { fg = p.yellow },
	["@repeat"] = { fg = p.yellow },
	["@exception"] = { fg = p.yellow },
	["@preproc"] = { fg = p.pink },

	-- Types
	["@type"] = { fg = p.type },
	["@type.builtin"] = { fg = p.type }, -- int, char
	["@type.qualifier"] = { fg = p.type }, -- const (older parsers)
	["@storageclass"] = { fg = p.fg },

	-- Functions
	["@function"] = { fg = p.fg },
	["@function.call"] = { fg = p.fg },
	["@function.builtin"] = { fg = p.fg },

	-- LSP semantic tokens
	["@lsp.type.macro"] = { fg = p.pink },

	-- Variables
	["@variable"] = { fg = p.fg },
	["@property"] = { fg = p.fg },
	["@field"] = { fg = p.fg },
	["@parameter"] = { fg = p.fg },
	["@constant"] = { fg = p.fg },
	["@constant.builtin"] = { fg = p.fg },

	-- Literals
	["@boolean"] = { fg = p.fg },
	["@number"] = { fg = p.pink },
	["@number.float"] = { fg = p.pink },
	["@string"] = { fg = p.orange },
	["@string.special"] = { fg = p.orange },
	["@string.special.path"] = { fg = p.orange }, -- <stdio.h>
	["@string.escape"] = { fg = p.pink }, -- %s, \n
	["@character"] = { fg = p.orange },
	["@character.special"] = { fg = p.pink },

	-- Punctuation and operators (Neovim links @constructor,
	-- @punctuation.special... to Special by default, so set them explicitly)
	["@operator"] = { fg = p.fg },
	["@punctuation"] = { fg = p.fg },
	["@punctuation.bracket"] = { fg = p.fg },
	["@punctuation.delimiter"] = { fg = p.fg },
	["@punctuation.special"] = { fg = p.fg },
	["@constructor"] = { fg = p.fg },
	["@constructor.lua"] = { fg = p.fg },

	-- Tags
	["@tag.delimiter"] = { fg = p.fg },

	-- Generic markup
	["@markup"] = { fg = p.fg },
	["@markup.strong"] = { fg = p.bright, bold = true },
	["@markup.italic"] = { fg = md.italic, italic = true },
	["@markup.strikethrough"] = { fg = p.gray, strikethrough = true },
	["@markup.underline"] = { fg = p.fg, underline = true },
	["@markup.heading"] = { fg = p.bright, bold = true },
	["@markup.quote"] = { fg = md.quote, italic = true },
	["@markup.list"] = { fg = p.gray },
	["@markup.list.checked"] = { fg = p.type },
	["@markup.list.unchecked"] = { fg = p.gray },
	["@markup.raw"] = { fg = md.code, bg = md.code_bg }, -- inline code
	["@markup.raw.block"] = { fg = p.fg },
	["@markup.math"] = { fg = md.math }, -- inline math ($...$)
	["@markup.link"] = { fg = p.gray },
	["@markup.link.label"] = { fg = p.blue },
	["@markup.link.url"] = { fg = p.gray, underline = true },
}

-- Diagnostics
local diagnostics = {
	DiagnosticError = { fg = p.error },
	DiagnosticWarn = { fg = p.yellow },
	DiagnosticInfo = { fg = p.blue },
	DiagnosticHint = { fg = p.gray },

	DiagnosticUnderlineError = { sp = p.error, undercurl = true },
	DiagnosticUnderlineWarn = { sp = p.yellow, undercurl = true },
}

-- Diff
local diff = {
	-- Lines
	DiffAdd = { bg = p.diff.add_bg },
	DiffChange = { bg = p.diff.change_bg },
	DiffDelete = { fg = p.diff.removed, bg = p.diff.delete_bg },

	-- Text inside a line
	DiffText = { bg = p.diff.text_bg },
	DiffTextAdd = { bg = p.diff.add_text_bg }, -- used by diffopt=inline:* in newer versions

	-- Signs
	Added = { fg = p.diff.added },
	Changed = { fg = p.diff.changed },
	Removed = { fg = p.diff.removed },

	-- Diff syntax (treesitter / .diff and .patch files)
	["@diff.plus"] = { fg = p.diff.added },
	["@diff.minus"] = { fg = p.diff.removed },
	["@diff.delta"] = { fg = p.diff.changed },
	diffAdded = { fg = p.diff.added },
	diffChanged = { fg = p.diff.changed },
	diffRemoved = { fg = p.diff.removed },
	diffLine = { fg = p.diff.line }, -- hunk header (@@ ... @@)
	diffSubname = { fg = p.diff.line },

	-- gitsigns.nvim
	GitSignsAdd = { fg = p.diff.added },
	GitSignsChange = { fg = p.diff.changed },
	GitSignsDelete = { fg = p.diff.removed },
	GitSignsAddInline = { bg = p.diff.add_text_bg },
	GitSignsChangeInline = { bg = p.diff.text_bg },
	GitSignsDeleteInline = { bg = p.diff.delete_text_bg },
	GitSignsAddLnInline = { bg = p.diff.add_text_bg },
	GitSignsChangeLnInline = { bg = p.diff.text_bg },
	GitSignsDeleteLnInline = { bg = p.diff.delete_text_bg },
	GitSignsAddPreview = { bg = p.diff.add_bg },
	GitSignsDeletePreview = { bg = p.diff.delete_bg },
}

-- Markdown

local markdown = {
	-- Frontmatter fences (---)
	["@keyword.directive.markdown"] = { fg = p.gray },

	-- Structural punctuation
	["@punctuation.special.markdown"] = { fg = p.gray },

	-- Code blocks
	["@markup.raw.delimiter.markdown"] = { fg = p.gray },
	["@label.markdown"] = { fg = p.gray },

	-- Inline code
	["@markup.raw.markdown_inline"] = { fg = md.code, bg = md.code_bg },

	-- Legacy :syntax groups (when treesitter is not active)
	markdownH1 = { fg = p.bright, bold = true },
	markdownH2 = { fg = p.bright, bold = true },
	markdownH3 = { fg = p.bright, bold = true },
	markdownH4 = { fg = p.bright, bold = true },
	markdownH5 = { fg = p.bright, bold = true },
	markdownH6 = { fg = p.bright, bold = true },
	markdownHeadingDelimiter = { fg = p.gray, bold = true },
	markdownBold = { fg = p.bright, bold = true },
	markdownItalic = { fg = md.italic, italic = true },
	markdownBoldItalic = { fg = p.bright, bold = true, italic = true },
	markdownBlockquote = { fg = md.quote, italic = true },
	markdownCode = { fg = md.code, bg = md.code_bg },
	markdownCodeBlock = { fg = p.fg },
	markdownCodeDelimiter = { fg = p.gray },
	markdownListMarker = { fg = p.gray },
	markdownUrl = { fg = p.gray, underline = true },
	markdownLinkText = { fg = p.blue },
}

-- Headings (generated)
do
	for i = 1, 6 do
		markdown[("@markup.heading.%d.markdown"):format(i)] = { fg = p.bright, bold = true }
		markdown[("@markup.heading.%d.marker.markdown"):format(i)] = { fg = p.gray, bold = true }
	end
end

-- Frontmatter (YAML injected into markdown): discreet, only keys get a soft tone
local frontmatter = {
	["@property.yaml"] = { fg = md.meta }, -- keys
	["@string.yaml"] = { fg = p.fg }, -- string values
	["@string.plain.yaml"] = { fg = p.fg },
	["@number.yaml"] = { fg = p.fg },
	["@number.float.yaml"] = { fg = p.fg },
	["@boolean.yaml"] = { fg = p.fg },
	["@punctuation.delimiter.yaml"] = { fg = p.gray }, -- : - ,
	["@punctuation.special.yaml"] = { fg = p.gray },

	-- Legacy :syntax groups
	yamlBlockMappingKey = { fg = md.meta },
	yamlFlowString = { fg = p.fg },
	yamlPlainScalar = { fg = p.fg },
}

-- Plugins
local plugins = {
	-- render-markdown.nvim
	RenderMarkdownCodeInline = { fg = md.code, bg = md.code_bg },
	RenderMarkdownMath = { fg = md.math },
	RenderMarkdownQuote = { fg = md.quote },
}

-- Links (hi! link)
local links = {
	["@comment"] = "Comment",
	["@comment.yaml"] = "Comment",
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
apply(frontmatter)
apply(plugins)
