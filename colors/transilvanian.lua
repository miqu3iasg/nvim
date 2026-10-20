-- colors/transilvanian.lua
--
-- A theme inspired on Metal Black Darkthrone.
--
-- Copyright (c) Andrea Schiavini <https://github.com/metalelf0>
-- Copyright (c) Miquéias Medeiros <contatomiqueiasalvesdev@gmail.com>
--
-- See: https://github.com/metalelf0/black-metal-theme-neovim
--
-- SPDX-License-Identifier: MIT

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "transilvanian"

local transparent = vim.g.darkthrone_transparent == true
local underline_on = vim.g.darkthrone_underline ~= false

-- Mixes fg over bg with opacity a (0..1).
local function blend(fg, a, bg)
	local function rgb(h)
		return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
	end
	local f, b = { rgb(fg) }, { rgb(bg) }
	local out = {}
	for i = 1, 3 do
		out[i] = math.floor(math.max(0, math.min(255, a * f[i] + (1 - a) * b[i])) + 0.5)
	end
	return string.format("#%02x%02x%02x", out[1], out[2], out[3])
end

local function spec(s)
	local d = { fg = s.fg, bg = s.bg, sp = s.sp }
	for k in (s.fmt or ""):gmatch("%a+") do
		if underline_on or (k ~= "underline" and k ~= "undercurl") then
			d[k] = true
		end
	end
	return d
end

local function hl(name, s, ns)
	vim.api.nvim_set_hl(ns or 0, name, s.link and { link = s.link } or spec(s))
end

local function apply(tbl, ns)
	for name, s in pairs(tbl) do
		hl(name, s, ns)
	end
end

-- Same spec for many groups.
local function paint(s, names)
	for _, name in ipairs(names) do
		hl(name, s)
	end
end

-- Many groups linking to the same target.
local function link(to, names)
	for _, name in ipairs(names) do
		vim.api.nvim_set_hl(0, name, { link = to })
	end
end

-- Palette

local c = {
	bg = "#000000",
	line = "#111111", -- cursorline, statusline, code blocks
	visual = "#262626",
	bright = "#ffffff", -- titles, directories, emphasis
	fg = "#e2e2e2", -- default code color
	keyword = "#e2e2e2", -- keywords (same as fg; change here to separate them)
	mid = "#9e9e9e", -- UI only
	comment = "#636262",
	tag = "#a85f5f", -- TODO/NOTE badges
	teal = "#5f8787", -- numbers, operators, punctuation, accents, warnings
	red = "#8a4a4a",
	str = "#b4a487", -- strings: muted sand/bone
}

local NONE = "NONE"
local bg_main = transparent and NONE or c.bg
local bg_float = transparent and NONE or "#060606"
local faint = blend(c.comment, 0.5, c.bg)

-- Git/diff colors (same as the "artifact" theme).
local git = {
	text = "#e4e4e4",
	green = "#6aa86a",
	yellow = "#c9b458",
	red = "#b85050",
	cyan = "#5f9f9f",
	delete_bg = "#331414",
	delete_fg = "#925a5a",
}
local diff_add = blend(git.text, 0.12, c.bg)
local diff_change = blend(git.cyan, 0.22, c.bg)

-- Editor UI

apply({
	Normal = { fg = c.fg, bg = bg_main },
	SignColumn = { fg = c.fg, bg = bg_main },
	LineNr = { fg = c.comment, bg = bg_main },
	ColorColumn = { bg = c.line },
	CursorLine = { bg = c.line },
	CursorLineNr = { fg = c.bright, bg = c.line, fmt = "bold" },
	CursorLineSign = { bg = c.line },
	CursorLineFold = { fg = c.fg, bg = c.line },
	Conceal = { fg = c.fg },
	Cursor = { fg = c.bg, bg = c.fg },
	CursorIM = { fg = c.bg, bg = c.bright },
	Folded = { fg = c.comment, bg = c.line },
	NonText = { fg = c.comment },
	SpecialKey = { fg = c.comment, fmt = "bold" },
	Whitespace = { fg = faint },
	Directory = { fg = c.bright },
	Title = { fg = c.bright, fmt = "bold" },
	Underlined = { fg = c.fg, fmt = "underline" },

	Visual = { bg = c.visual },
	VisualNOS = { bg = c.visual, fmt = "underline" },
	Search = { fg = "#b065f0", bg = "#321d4d" },
	CurSearch = { fg = "#321d4d", bg = "#b065f0", fmt = "bold" },
	IncSearch = { fg = "#321d4d", bg = "#b065f0", fmt = "bold" },
	Substitute = { fg = c.bg, bg = c.mid },
	MatchParen = { fg = c.bright, bg = c.visual, fmt = "bold" },
	QuickFixLine = { bg = c.line, fmt = "bold" },
	-- vim.hl.on_yank({ higroup = "YankHighlight" })
	YankHighlight = { fg = c.bg, bg = "#d787af" },

	ErrorMsg = { fg = c.red, fmt = "bold" },
	WarningMsg = { fg = c.teal, fmt = "bold" },
	ModeMsg = { fg = c.fg, fmt = "bold" },
	MoreMsg = { fg = c.fg, fmt = "bold" },
	Question = { fg = c.fg },
	MsgSeparator = { fg = c.comment, bg = c.line },

	WinSeparator = { fg = c.comment },
	WinBarNC = { fg = c.comment, bg = bg_main },
	StatusLine = { fg = c.fg, bg = c.line },
	StatusLineNC = { fg = c.comment, bg = c.line },
	TabLineSel = { fg = c.bright, bg = c.visual, fmt = "bold" },
	ToolbarButton = { fg = c.bright, bg = c.line, fmt = "bold" },
	ToolbarLine = { bg = bg_main },

	SpellBad = { sp = c.red, fmt = "undercurl" },
	SpellCap = { sp = c.teal, fmt = "undercurl" },
	SpellRare = { sp = c.comment, fmt = "undercurl" },

	DiffAdd = { fg = git.text, bg = "#1f2f4f" },
	DiffChange = { fg = git.text, bg = "#3f2f4f" },
	DiffDelete = { fg = git.delete_fg, bg = git.delete_bg },
	DiffText = { fg = git.text, bg = "#6f2f2f", fmt = "bold" },
	Added = { fg = git.green },
	Changed = { fg = git.yellow },
	Removed = { fg = git.red },
	diffFile = { fg = git.text, fmt = "bold" },
	diffLine = { fg = git.cyan },

	NormalFloat = { fg = c.fg, bg = bg_float },
	FloatBorder = { fg = c.comment, bg = bg_float },
	FloatTitle = { fg = c.bright, bg = bg_float, fmt = "bold" },
	PmenuSel = { fg = c.bright, bg = c.visual },
	PmenuKindSel = { fg = c.fg, bg = c.visual },
	PmenuMatch = { fg = c.bright, bg = bg_float, fmt = "bold" },
	PmenuMatchSel = { fg = c.bright, bg = c.visual, fmt = "bold" },
	PmenuSbar = { bg = bg_float },
	PmenuThumb = { bg = c.comment },

	debugPC = { bg = c.line },
	debugBreakpoint = { fg = c.red },
})

link("Normal", { "NormalNC", "MsgArea", "TitleBar", "WinBar", "Terminal" })
link("NonText", { "EndOfBuffer", "Ignore" })
link("CursorLine", { "CursorColumn" })
link("LineNr", { "LineNrAbove", "LineNrBelow", "FoldColumn" })
link("WinSeparator", { "VertSplit" })
link("WinBarNC", { "TitleBarNC" })
link("StatusLineNC", { "TabLine", "TabLineFill" })
link("Cursor", { "TermCursor", "lCursor", "vCursor", "iCursor" })
link("SpellRare", { "SpellLocal" })
link("NormalFloat", { "Pmenu" })
link("FloatBorder", { "FloatFooter", "PmenuKind", "PmenuExtra" })
link("PmenuKindSel", { "PmenuExtraSel" })
link("PmenuSel", { "WildMenu" })

-- Syntax (legacy groups). Everything not listed here is plain fg

apply({
	Comment = { fg = c.comment },
	String = { fg = c.str },
	Number = { fg = c.teal },
	Constant = { fg = c.fg },
	Identifier = { fg = c.fg },
	Statement = { fg = c.keyword },
	Label = { fg = c.fg },
	Operator = { fg = c.teal },
	PreProc = { fg = c.fg },
	Macro = { fg = c.fg, fmt = "italic" },
	Type = { fg = c.fg },
	Special = { fg = c.fg },
	SpecialChar = { fg = c.teal },
	Delimiter = { fg = c.teal },
	SpecialComment = { fg = c.comment, fmt = "bold" },
	Debug = { fg = c.teal },
	Error = { fg = c.red, fmt = "bold" },
	Todo = { fg = c.bg, bg = c.tag, fmt = "bold" },
})
link("String", { "Character" })
link("Number", { "Boolean", "Float" })
link("Statement", { "Conditional", "Repeat", "Keyword", "Exception", "Include" })
link("Identifier", { "Function" })
link("PreProc", { "Define", "PreCondit" })
link("Type", { "StorageClass", "Structure", "Typedef" })
link("Special", { "Tag" })

-- Treesitter
apply({
	["@variable.builtin"] = { fg = c.fg, fmt = "italic" },
	["@variable.parameter"] = { fg = c.fg, fmt = "italic" },
	["@constant.builtin"] = { fg = c.teal },
	["@constant.macro"] = { fg = c.fg, fmt = "italic" },
	["@function.macro"] = { fg = c.fg, fmt = "italic" },
	["@attribute"] = { fg = c.comment, fmt = "italic" },
	["@attribute.builtin"] = { fg = c.comment, fmt = "italic" },
	["@tag.attribute"] = { fg = c.fg, fmt = "italic" },

	["@string.documentation"] = { fg = c.str, fmt = "italic" },
	["@string.escape"] = { fg = c.teal },
	["@string.special.url"] = { fg = c.teal, fmt = "underline" },

	-- markup
	["@markup.strong"] = { fg = c.bright, fmt = "bold" },
	["@markup.italic"] = { fg = c.fg, fmt = "italic" },
	["@markup.strikethrough"] = { fg = c.comment, fmt = "strikethrough" },
	["@markup.link"] = { fg = c.bright, fmt = "underline" },
	["@markup.link.label"] = { fg = c.bright },
	["@markup.link.url"] = { fg = c.teal, fmt = "underline" },
	["@markup.quote"] = { fg = c.mid, fmt = "italic" },
	["@markup.list"] = { fg = c.teal },
	["@markup.raw"] = { fg = c.bright, bg = c.line },
	["@markup.raw.block"] = { fg = c.fg },
	["@markup.math"] = { fg = c.bright },
	["@conceal"] = { fg = c.comment },

	-- regex
	["@keyword.operator.regex"] = { fg = c.teal },
	["@property.regex"] = { fg = c.fg, fmt = "italic" },
	["@variable.builtin.regex"] = { fg = c.fg },

	-- jsx (needs matching captures in after/queries)
	["@function.call.hook"] = { fg = c.fg, fmt = "italic" },

	-- LSP semantic tokens (override treesitter)
	["@lsp.type.parameter"] = { fg = c.fg },
	["@lsp.type.lifetime"] = { fg = c.fg, fmt = "italic" },
	["@lsp.type.readonly"] = { fg = c.fg, fmt = "italic" },
	["@lsp.mod.readonly"] = { fg = c.fg, fmt = "italic" },
	["@lsp.typemod.keyword.documentation"] = { fg = c.comment },

	LspInlayHint = { fg = c.comment, bg = c.line, fmt = "italic" },
	LspReferenceText = { bg = c.visual },
	LspReferenceRead = { bg = c.visual },
	LspReferenceWrite = { bg = c.visual, fmt = "underline" },
	LspCodeLens = { fg = c.comment, fmt = "italic" },
	LspCodeLensSeparator = { fg = c.comment },
	LspSignatureActiveParameter = { fg = c.bright, fmt = "bold,underline" },
})

link("Keyword", {
	"@keyword.function",
	"@keyword.return",
	"@keyword.operator",
	"@keyword.conditional",
	"@keyword.repeat",
	"@keyword.import",
	"@keyword.storage",
	"@keyword.modifier",
	"@keyword.directive",
	"@keyword.exception",
})
link("Type", { "@type.qualifier" })
link("String", { "@string.regexp", "@string.special", "@string.special.symbol" })
link("Delimiter", {
	"@punctuation",
	"@punctuation.delimiter",
	"@punctuation.bracket",
	"@punctuation.special",
	"@tag.delimiter",
})
link("Todo", { "@comment.error", "@comment.warning", "@comment.todo", "@comment.note" })
link("@markup.list", { "@markup.list.checked", "@markup.list.unchecked" })

-- Diagnostics
for level, d in pairs({
	Error = { fg = c.red, bg = blend(c.red, 0.12, c.bg) },
	Warn = { fg = c.teal, bg = blend(c.teal, 0.1, c.bg) },
	Info = { fg = c.mid, bg = blend(c.mid, 0.08, c.bg) },
	Hint = { fg = c.comment, bg = blend(c.comment, 0.15, c.bg) },
	Ok = { fg = c.mid },
}) do
	hl("Diagnostic" .. level, { fg = d.fg })
	hl("DiagnosticVirtualText" .. level, { fg = d.fg, bg = d.bg })
	hl("DiagnosticUnderline" .. level, { sp = d.fg, fmt = "undercurl" })
end
apply({
	DiagnosticUnnecessary = { fg = c.comment },
	DiagnosticDeprecated = { fg = c.comment, fmt = "strikethrough" },
})

-- Markdown

apply({
	["@keyword.directive.markdown"] = { fg = c.teal },
	["@punctuation.special.markdown"] = { fg = c.fg },
	["@punctuation.delimiter.markdown"] = { fg = c.fg },
	["@markup.list.markdown"] = { fg = c.teal, fmt = "bold" },
	["@markup.list.checked.markdown"] = { fg = c.teal, fmt = "bold" },
	["@markup.list.unchecked.markdown"] = { fg = c.teal, fmt = "bold" },
	["@markup.raw.delimiter.markdown"] = { fg = c.teal },
	["@label.markdown"] = { fg = c.teal, fmt = "italic" },

	["@markup.italic.markdown_inline"] = { fg = c.mid, fmt = "italic" },
	["@markup.math.markdown_inline"] = { fg = c.teal },
	["@markup.math.markdown"] = { fg = c.teal },
	["@markup.math.latex"] = { fg = c.teal },
	["@punctuation.special.markdown_inline"] = { fg = c.bright },
	["@markup.link.markdown_inline"] = { fg = c.comment },
	["@markup.link.label.markdown_inline"] = { fg = c.bright, bg = c.line, fmt = "underline" },

	["@markup.heading.marker.markdown"] = { fg = c.bright },
})

-- Heading levels fade in brightness, not in hue
for i, color in ipairs({ c.bright, c.bright, c.fg, c.fg, c.mid, c.mid }) do
	hl(("@markup.heading.%d.markdown"):format(i), { fg = color, fmt = i == 1 and "bold,underline" or "bold" })
	hl(("@markup.heading.%d.marker.markdown"):format(i), { fg = color })
	link(("@markup.heading.%d.markdown"):format(i), { "markdownH" .. i })
end

-- Legacy regex-based markdown groups point to the treesitter ones
for from, to in pairs({
	markdownHeadingDelimiter = "@markup.heading.marker.markdown",
	markdownHeadingRule = "@markup.heading.marker.markdown",
	markdownCode = "@markup.raw",
	markdownCodeBlock = "@markup.raw.block",
	markdownCodeDelimiter = "@markup.raw.delimiter.markdown",
	markdownBlockquote = "@markup.quote",
	markdownListMarker = "@markup.list.markdown",
	markdownOrderedListMarker = "@markup.list.markdown",
	markdownRule = "@punctuation.special.markdown",
	markdownBold = "@markup.strong",
	markdownBoldItalic = "@markup.strong",
	markdownItalic = "@markup.italic.markdown_inline",
	markdownStrike = "@markup.strikethrough",
	markdownLinkText = "@markup.link.label.markdown_inline",
	markdownUrl = "@markup.link.url",
	markdownAutomaticLink = "@markup.link.url",
	markdownLinkDelimiter = "@markup.link.markdown_inline",
	markdownIdDelimiter = "@markup.link.markdown_inline",
	markdownEscape = "@string.escape",
}) do
	link(to, { from })
end

local frontmatter_ns = vim.api.nvim_create_namespace("transilvanian_markdown")
apply({
	["@property.yaml"] = { fg = c.teal },
	["@string.yaml"] = { fg = c.fg },
	["@number.yaml"] = { fg = c.teal },
	["@number.float.yaml"] = { fg = c.teal },
	["@boolean.yaml"] = { fg = c.teal },
	["@constant.builtin.yaml"] = { fg = c.mid },
	["@label.yaml"] = { fg = c.teal },
	["@type.yaml"] = { fg = c.teal },
	["@punctuation.delimiter.yaml"] = { fg = c.comment },
	["@punctuation.bracket.yaml"] = { fg = c.comment },
}, frontmatter_ns)

local aug = vim.api.nvim_create_augroup("Transilvanian", { clear = true })

local function sync_frontmatter_ns()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local is_md = vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "markdown"
		if is_md then
			vim.api.nvim_win_set_hl_ns(win, frontmatter_ns)
			vim.w[win].transilvanian_markdown_ns = true
		elseif vim.w[win].transilvanian_markdown_ns then
			vim.api.nvim_win_set_hl_ns(win, 0)
			vim.w[win].transilvanian_markdown_ns = nil
		end
	end
end

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "BufEnter", "WinEnter" }, {
	group = aug,
	callback = sync_frontmatter_ns,
})
sync_frontmatter_ns()

-- LaTeX (vim :syntax; treesitter stays off for tex)

paint({ fg = c.comment }, { "texComment" })
paint({ fg = c.keyword }, {
	"texStatement",
	"texCmd",
	"texCmdName",
	"texBeginEnd",
	"texMathCmd",
	"texMathCmdText",
	"texSpecialChar",
	"texCmdVerb",
})
paint({ fg = c.keyword, fmt = "italic" }, { "texCmdStyle" })
paint({ fg = c.bright }, {
	"texCmdEnv",
	"texCmdClass",
	"texCmdPackage",
	"texEnvName",
	"texBeginEndName",
	"texMathZone",
	"texMathZoneEnv",
	"texMathZoneEnvStarred",
	"texMathZoneX",
	"texMathZoneXX",
	"texMathZoneEnsured",
	"texMathSymbol",
	"texMathSub",
	"texMathSuper",
	"texLigature",
	"texAccent",
	"texFileArg",
	"texInputFile",
	"VimtexSuccess",
})
paint({ fg = c.bright, fmt = "bold" }, {
	"texCmdPart",
	"texCmdTitle",
	"texCmdBold",
	"texSection",
	"texPartArgTitle",
	"texTitleArg",
})
paint({ fg = c.teal }, {
	"texCmdRef",
	"texRefArg",
	"texMathEnvArgName",
	"texMathDelim",
	"texMathDelimZone",
	"texMathSuperSub",
	"texCiteArg",
	"texLabelArg",
	"texOptSep",
	"texDelim",
	"texMathOper",
	"texNumber",
	"texLength",
	"VimtexWarning",
})
paint({ fg = c.mid }, {
	"texOpt",
	"texFileOpt",
	"texTheoremEnvOpt",
	"texRefOpt",
	"VimtexInfo",
})
paint({ fg = c.fg }, { "texArg", "texMathText" })
paint({ fg = c.red }, { "VimtexError" })
apply({
	texCmdItal = { fg = c.mid, fmt = "italic" },
	texUrlArg = { fg = c.teal, fmt = "underline" },
	texTodo = { fg = c.bg, bg = c.mid, fmt = "bold" },
	texError = { fg = c.red, fmt = "bold" },
	texVerbZone = { fg = c.fg, bg = c.line },
})

-- Plugins

-- oil.nvim (sometimes resets its groups on open, so this is a function)
local function apply_oil()
	paint({ fg = c.bright, fmt = "bold" }, {
		"OilDir",
		"OilCreate",
		"OilCopy",
		"OilRestore",
		"OilTypeDir",
	})
	paint({ fg = c.bright }, { "OilDirIcon", "OilPermissionExecute" })
	paint({ fg = c.fg }, { "OilFile", "OilTypeLink" })
	paint({ fg = c.fg, fmt = "italic" }, { "OilLink" })
	paint({ fg = c.comment }, {
		"OilHidden",
		"OilFileHidden",
		"OilSocket",
		"OilTrash",
		"OilTrashSourcePath",
		"OilTypeFile",
		"OilTypeFifo",
		"OilTypeSocket",
		"OilTypeUnknown",
		"OilPermissionNone",
	})
	paint({ fg = c.comment, fmt = "italic" }, { "OilLinkTarget", "OilLinkHidden" })
	paint({ fg = c.comment, fmt = "bold" }, { "OilDirHidden" })
	paint({ fg = c.red, fmt = "italic" }, {
		"OilOrphanLink",
		"OilOrphanLinkTarget",
		"OilOrphanLinkHidden",
	})
	paint({ fg = c.red }, { "OilDelete", "OilPermissionWrite" })
	paint({ fg = c.red, fmt = "bold" }, { "OilPurge" })
	paint({ fg = c.teal }, { "OilMove", "OilChange", "OilPermissionRead" })
	paint({ fg = c.teal, fmt = "bold" }, { "OilExecutable" })
end
apply_oil()
vim.api.nvim_create_autocmd("FileType", {
	group = aug,
	pattern = "oil",
	callback = function()
		if vim.g.colors_name == "transilvanian" then
			apply_oil()
		end
	end,
})

apply({
	LazyNormal = { bg = bg_float },
	MasonNormal = { bg = bg_float },
	BufferLineBufferSelected = { fg = c.bright, fmt = "bold" },
})

-- blink.cmp / nvim-cmp
apply({
	BlinkCmpMenuSelection = { fg = c.bright, bg = "#181818" },
	BlinkCmpLabelMatch = { fg = c.bright, fmt = "bold" },
	BlinkCmpLabelDeprecated = { fg = c.comment, fmt = "strikethrough" },
	BlinkCmpLabelDetail = { fg = c.comment },
	BlinkCmpLabelDescription = { fg = c.comment },
	BlinkCmpGhostText = { fg = c.comment, fmt = "italic" },
	BlinkCmpDocCursorLine = { bg = c.visual },
	BlinkCmpSignatureHelpActiveParameter = { fg = c.bright, fmt = "bold,underline" },
	CmpItemAbbr = { fg = c.fg },
	CmpItemAbbrDeprecated = { fg = c.comment, fmt = "strikethrough" },
})
for from, to in pairs({
	BlinkCmpMenu = "Pmenu",
	BlinkCmpMenuBorder = "FloatBorder",
	BlinkCmpScrollBarThumb = "PmenuThumb",
	BlinkCmpScrollBarGutter = "PmenuSbar",
	BlinkCmpLabel = "Pmenu",
	BlinkCmpKind = "PmenuKind",
	BlinkCmpSource = "PmenuExtra",
	BlinkCmpDoc = "NormalFloat",
	BlinkCmpDocBorder = "FloatBorder",
	BlinkCmpDocSeparator = "FloatBorder",
	BlinkCmpSignatureHelp = "NormalFloat",
	BlinkCmpSignatureHelpBorder = "FloatBorder",
	CmpItemAbbrMatch = "PmenuMatch",
	CmpItemAbbrMatchFuzzy = "PmenuMatch",
	CmpItemMenu = "PmenuExtra",
	CmpItemKind = "PmenuKind",
}) do
	link(to, { from })
end

-- gitsigns
for kind, d in pairs({
	Add = { sign = "Added", ln = diff_add, cul = git.green },
	Change = { sign = "Changed", ln = diff_change, cul = git.yellow },
	Delete = { sign = "Removed", ln = git.delete_bg, cul = git.red },
}) do
	local p = "GitSigns" .. kind
	link(d.sign, { p, p .. "Nr" })
	link("Diff" .. kind, { p .. "Inline" })
	hl(p .. "Ln", { bg = d.ln })
	hl(p .. "Cul", { fg = d.cul, bg = c.line })
end
link("DiffAdd", { "GitSignsAddPreview" })
link("DiffDelete", { "GitSignsDeletePreview" })
hl("GitSignsCurrentLineBlame", { fg = c.comment, fmt = "italic" })

-- diffview
apply({
	DiffviewFilePanelTitle = { fg = c.bright, fmt = "bold" },
	DiffviewFilePanelCounter = { fg = c.teal, fmt = "bold" },
	DiffviewFilePanelFileName = { fg = c.fg },
	DiffviewFilePanelRootPath = { fg = c.comment },
	DiffviewFilePanelPath = { fg = c.comment },
	DiffviewFilePanelInsertions = { fg = git.green },
	DiffviewFilePanelDeletions = { fg = git.red },
})
for from, to in pairs({
	DiffviewNormal = "Normal",
	DiffviewCursorLine = "CursorLine",
	DiffviewVertSplit = "VertSplit",
	DiffviewSignColumn = "SignColumn",
	DiffviewStatusLine = "StatusLine",
	DiffviewStatusLineNC = "StatusLineNC",
	DiffviewEndOfBuffer = "EndOfBuffer",
	DiffviewStatusAdded = "Added",
	DiffviewStatusUntracked = "Changed",
	DiffviewStatusModified = "Changed",
	DiffviewStatusRenamed = "Changed",
	DiffviewStatusCopied = "Changed",
	DiffviewStatusTypeChange = "Changed",
	DiffviewStatusUnmerged = "Changed",
	DiffviewStatusUnknown = "Removed",
	DiffviewStatusDeleted = "Removed",
	DiffviewStatusBroken = "Removed",
}) do
	link(to, { from })
end

-- legacy vim diff syntax
link("Added", { "diffAdded", "diffNewFile" })
link("Removed", { "diffRemoved", "diffOldFile" })
link("Changed", { "diffChanged" })
link("Comment", { "diffIndexLine", "diffSubname", "diffComment" })

-- Terminal colors
for i, color in ipairs({
	c.bg,
	c.red,
	c.fg,
	c.mid,
	c.mid,
	c.mid,
	c.bright,
	c.bright,
	c.comment,
	c.red,
	c.fg,
	c.mid,
	c.mid,
	c.bright,
	c.teal,
	c.bright,
}) do
	vim.g["terminal_color_" .. (i - 1)] = color
end
