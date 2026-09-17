-- colors/insanity.lua

local M = {}

vim.cmd("highlight clear")
vim.g.colors_name = "insanity"
vim.o.background = "dark"

local colors = {
  bg = "#000000",

  fg_0 = "#3b3b3b",
  fg_1 = "#808080",
  fg_2 = "#b9b9b9",
  fg_3 = "#d8d8d8",

  linenr = "#3a3a3a",
  linenr_cur = "#585858",
  linenr_above = "#2e2e2e",

  border = "#2a2a2a",

  cursorline = "#0d0d0d",

  comment = "#4a4a4a",

  red = "#d75f5f",
  green = "#7a9c7a",
  yellow = "#7d7d70",
  blue = "#5f87ff",
  magenta = "#d787af",
  cyan = "#5fafaf",

  br_red = "#ff5f5f",
  br_green = "#93b093",
  br_yellow = "#ffd751",
  br_blue = "#5fafff",
  br_magenta = "#d75fd7",
  br_cyan = "#c9d6d6",

  diff_add_bg = "#0c130c",
  diff_change_bg = "#13120c",
  diff_delete_bg = "#130c0c",
  diff_text_bg = "#2a1414",
}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Terminal colors
vim.g.terminal_color_0 = colors.bg
vim.g.terminal_color_1 = colors.red
vim.g.terminal_color_2 = colors.green
vim.g.terminal_color_3 = colors.yellow
vim.g.terminal_color_4 = colors.blue
vim.g.terminal_color_5 = colors.magenta
vim.g.terminal_color_6 = colors.cyan
vim.g.terminal_color_7 = colors.fg_2
vim.g.terminal_color_8 = colors.fg_1
vim.g.terminal_color_9 = colors.br_red
vim.g.terminal_color_10 = colors.br_green
vim.g.terminal_color_11 = colors.br_yellow
vim.g.terminal_color_12 = colors.br_blue
vim.g.terminal_color_13 = colors.br_magenta
vim.g.terminal_color_14 = colors.br_cyan
vim.g.terminal_color_15 = colors.fg_3

-- Default highlights
hi("ColorColumn", {
  bg = colors.fg_0,
})

hi("Conceal", {
  fg = colors.fg_0,
  nocombine = true,
})

hi("Cursor", {
  bg = colors.fg_2,
  fg = colors.bg,
})

hi("CursorLineNr", {
  fg = colors.linenr_cur,
})

hi("Directory", {
  fg = colors.blue,
})

hi("DiffAdd", {
  bg = colors.diff_add_bg,
  fg = colors.green,
})

hi("DiffChange", {
  bg = colors.diff_change_bg,
  fg = colors.br_yellow,
})

hi("DiffDelete", {
  bg = colors.diff_delete_bg,
  fg = colors.red,
})

hi("DiffText", {
  bg = colors.diff_text_bg,
  fg = colors.fg_3,
})

hi("ErrorMsg", {
  fg = colors.br_red,
  nocombine = true,
})

hi("LineNr", {
  fg = colors.linenr,
})

hi("LineNrAbove", {
  fg = colors.linenr_above,
})

hi("MatchParen", {
  fg = colors.br_cyan,
})

hi("NonText", {
  fg = colors.fg_1,
  nocombine = true,
})

hi("Normal", {
  bg = colors.bg,
  fg = colors.fg_2,
  nocombine = true,
})

hi("NormalNC", {
  link = "Normal",
})

hi("NormalFloat", {
  bg = colors.bg,
})

hi("FloatTitle", {
  link = "Title",
})

hi("FloatFooter", {
  link = "Comment",
})

hi("SignColumn", {})

hi("Search", {
  bg = colors.br_magenta,
  fg = colors.fg_3,
})

hi("Substitute", {
  link = "Search",
})

hi("Title", {
  fg = colors.fg_2,
})

hi("QuickFixLine", {
  fg = colors.green,
})

hi("WarningMsg", {
  fg = colors.fg_2,
  nocombine = true,
})

hi("WildMenu", {
  bg = colors.bg,
  fg = colors.fg_2,
})

hi("Whitespace", {
  fg = colors.fg_0,
})

hi("SpecialKey", {
  link = "NonText",
})

hi("MsgArea", {
  link = "Normal",
})

hi("MsgSeparator", {
  link = "StatusLine",
})

hi("healthError", { link = "ErrorMsg" })
hi("healthWarning", { link = "WarningMsg" })
hi("healthSuccess", { fg = colors.green })

hi("lCursor", {
  link = "Cursor",
})

hi("CursorIM", {
  link = "Cursor",
})

hi("TermCursor", {
  link = "Cursor",
})

hi("TermCursorNC", {
  fg = colors.bg,
  bg = colors.fg_1,
})

hi("CursorColumn", {
  link = "ColorColumn",
})

hi("CursorLine", {
  bg = colors.cursorline,
})

hi("CursorLineFold", {
  link = "ColorColumn",
})

hi("CursorLineSign", {
  link = "CursorLineNr",
})

hi("EndOfBuffer", {
  link = "NonText",
})

hi("VertSplit", {
  fg = colors.border,
  bg = colors.bg,
})

hi("WinSeparator", {
  fg = colors.border,
  bg = colors.bg,
})

hi("WinBar", {
  link = "StatusLine",
})

hi("WinBarNC", {
  link = "StatusLineNC",
})

hi("FloatBorder", {
  fg = colors.border,
  bg = colors.bg,
})

hi("Folded", {
  link = "NonText",
})

hi("FoldColumn", {
  link = "Conceal",
})

hi("IncSearch", {
  link = "Search",
})

hi("CurSearch", {
  link = "Search",
})

hi("LineNrBelow", {
  link = "LineNrAbove",
})

hi("MoreMsg", {
  link = "WarningMsg",
})

hi("PopupNotification", {
  link = "WarningMsg",
})

hi("Question", {
  link = "WarningMsg",
})

hi("ModeMsg", {
  link = "Normal",
})

hi("Terminal", {
  link = "Normal",
})

-- Completion menu
hi("Pmenu", {
  bg = colors.bg,
  fg = colors.fg_2,
  nocombine = true,
})

hi("PmenuSbar", {
  bg = colors.bg,
  nocombine = true,
})

hi("PmenuSel", {
  bg = colors.bg,
  fg = colors.fg_3,
})

hi("PmenuThumb", {
  fg = colors.fg_1,
  nocombine = true,
})

hi("PmenuKind", {
  link = "Pmenu",
})

hi("PmenuKindSel", {
  link = "PmenuSel",
})

hi("PmenuExtra", {
  link = "Pmenu",
})

hi("PmenuExtraSel", {
  link = "PmenuSel",
})

hi("PmenuMatch", {
  fg = colors.fg_3,
  bold = true,
})

hi("PmenuMatchSel", {
  link = "PmenuMatch",
})

hi("MessageWindow", {
  link = "PmenuSel",
})

hi("SpellBad", { undercurl = true, sp = colors.red })
hi("SpellCap", { undercurl = true, sp = colors.blue })
hi("SpellLocal", { link = "Normal" })
hi("SpellRare", { link = "Normal" })

-- Status line
hi("StatusLine", {
  bg = colors.bg,
  fg = colors.fg_1,
  nocombine = true,
})

hi("StatusLineNC", {
  bg = colors.bg,
  fg = colors.yellow,
  nocombine = true,
})

hi("StatuslineTerm", {
  link = "StatusLine",
})

hi("StatuslineTermNC", {
  link = "StatusLineNC",
})

-- Tab line
hi("TabLine", {
  bg = colors.bg,
  fg = colors.yellow,
  nocombine = true,
})

hi("TabLineFill", {
  bg = colors.bg,
  nocombine = true,
})

hi("TabLineSel", {
  bg = colors.bg,
  fg = colors.fg_1,
  nocombine = true,
})

-- Visual selection
hi("Visual", {
  bg = colors.fg_1,
  fg = colors.fg_3,
})

hi("VisualNOS", {
  link = "Visual",
})

-- General syntax
hi("String", {
  fg = colors.green,
  nocombine = true,
})

hi("Todo", {
  bg = colors.bg,
  fg = colors.br_cyan,
})

hi("Comment", {
  bg = colors.bg,
  fg = colors.comment,
})

hi("Special", {
  bg = colors.bg,
  fg = colors.fg_2,
})

hi("Delimiter", {
  fg = colors.fg_3,
})

hi("@punctuation.bracket", {
  fg = colors.fg_3,
})

hi("@punctuation.delimiter", {
  fg = colors.fg_3,
})

hi("@punctuation.special", {
  fg = colors.fg_3,
})

hi("Link", {
  fg = colors.cyan,
})

hi("Ignore", {
  link = "Comment",
})

hi("Function", {
  link = "Special",
})

hi("FunctionBuiltin", {
  link = "Special",
})

hi("Identifier", {
  link = "Special",
})

hi("IdentifierBuiltin", {
  link = "Special",
})

hi("PreProc", {
  link = "Special",
})

hi("Type", {
  link = "Special",
})

hi("TypeBuiltin", {
  link = "Normal",
})

hi("Exception", {
  link = "WarningMsg",
})

hi("Error", {
  link = "ErrorMsg",
})

hi("Character", {
  link = "Normal",
})

hi("Text", {
  link = "Normal",
})

hi("Constant", {
  link = "Normal",
})

hi("Underlined", {
  link = "Normal",
})

hi("Statement", {
  link = "Link",
})

hi("ToolbarLine", {
  link = "TabLine",
})

hi("ToolbarButton", {
  link = "TabLineSel",
})

-- LSP
hi("DiagnosticError", { fg = colors.br_red })
hi("DiagnosticWarn", { fg = colors.br_yellow })
hi("DiagnosticInfo", { fg = colors.blue })
hi("DiagnosticHint", { fg = colors.cyan })
hi("DiagnosticOk", { fg = colors.green })

hi("DiagnosticUnderlineError", { undercurl = true, sp = colors.br_red })
hi("DiagnosticUnderlineWarn", { undercurl = true, sp = colors.br_yellow })
hi("DiagnosticUnderlineInfo", { undercurl = true, sp = colors.blue })
hi("DiagnosticUnderlineHint", { undercurl = true, sp = colors.cyan })
hi("DiagnosticUnderlineOk", { undercurl = true, sp = colors.green })

-- Texto virtual (mensagem inline) um pouco mais discreto que o sinal
hi("DiagnosticVirtualTextError", { fg = colors.red, bg = colors.bg })
hi("DiagnosticVirtualTextWarn", { fg = colors.yellow, bg = colors.bg })
hi("DiagnosticVirtualTextInfo", { fg = colors.blue, bg = colors.bg })
hi("DiagnosticVirtualTextHint", { fg = colors.cyan, bg = colors.bg })
hi("DiagnosticVirtualTextOk", { fg = colors.green, bg = colors.bg })

hi("DiagnosticFloatingError", { link = "DiagnosticError" })
hi("DiagnosticFloatingWarn", { link = "DiagnosticWarn" })
hi("DiagnosticFloatingInfo", { link = "DiagnosticInfo" })
hi("DiagnosticFloatingHint", { link = "DiagnosticHint" })
hi("DiagnosticFloatingOk", { link = "DiagnosticOk" })

hi("DiagnosticSignError", { link = "DiagnosticError" })
hi("DiagnosticSignWarn", { link = "DiagnosticWarn" })
hi("DiagnosticSignInfo", { link = "DiagnosticInfo" })
hi("DiagnosticSignHint", { link = "DiagnosticHint" })
hi("DiagnosticSignOk", { link = "DiagnosticOk" })

hi("DiagnosticDeprecated", { fg = colors.fg_1, strikethrough = true })
hi("DiagnosticUnnecessary", { fg = colors.fg_1 })

hi("LspReferenceText", { bg = colors.fg_0 })
hi("LspReferenceRead", { bg = colors.fg_0 })
hi("LspReferenceWrite", { bg = colors.fg_0, underline = true })
hi("LspSignatureActiveParameter", { link = "MatchParen" })
hi("LspCodeLens", { link = "Comment" })
hi("LspCodeLensSeparator", { link = "Comment" })
hi("LspInlayHint", { fg = colors.comment, bg = colors.fg_0, italic = true })

-- Treesitter
hi("@variable", { fg = colors.fg_2 })
hi("@variable.builtin", { fg = colors.fg_3, italic = true })
hi("@variable.parameter", { fg = colors.fg_3, italic = true })
hi("@variable.parameter.builtin", { fg = colors.fg_3, italic = true })
hi("@variable.member", { fg = colors.fg_3 })

hi("@module", { link = "Special" })
hi("@module.builtin", { fg = colors.fg_3 })
hi("@label", { link = "Link" })

hi("@constant", { link = "Constant" })
hi("@constant.builtin", { fg = colors.fg_3, bold = true })
hi("@constant.macro", { link = "PreProc" })
hi("@boolean", { fg = colors.fg_3, bold = true })
hi("@number", { link = "Constant" })
hi("@number.float", { link = "Constant" })

hi("@string", { link = "String" })
hi("@string.documentation", { fg = colors.green, italic = true })
hi("@string.regexp", { fg = colors.magenta })
hi("@string.escape", { fg = colors.br_cyan })
hi("@string.special", { fg = colors.br_cyan })
hi("@string.special.symbol", { fg = colors.fg_3 })
hi("@string.special.url", { fg = colors.cyan, underline = true })
hi("@character", { link = "Character" })
hi("@character.special", { fg = colors.br_cyan })

hi("@type", { link = "Type" })
hi("@type.builtin", { link = "TypeBuiltin" })
hi("@type.definition", { link = "Type" })
hi("@type.qualifier", { link = "Statement" })

hi("@attribute", { link = "PreProc" })
hi("@attribute.builtin", { link = "PreProc" })
hi("@property", { fg = colors.fg_3 })

hi("@function", { link = "Function" })
hi("@function.builtin", { link = "FunctionBuiltin" })
hi("@function.call", { link = "Function" })
hi("@function.macro", { link = "PreProc" })
hi("@function.method", { link = "Function" })
hi("@function.method.call", { link = "Function" })
hi("@constructor", { link = "Special" })

hi("@operator", { fg = colors.fg_3 })

hi("@keyword", { link = "Statement" })
hi("@keyword.coroutine", { link = "Statement" })
hi("@keyword.function", { link = "Statement" })
hi("@keyword.operator", { fg = colors.fg_3 })
hi("@keyword.import", { link = "Statement" })
hi("@keyword.type", { link = "Statement" })
hi("@keyword.modifier", { link = "Statement" })
hi("@keyword.repeat", { link = "Statement" })
hi("@keyword.return", { link = "Statement" })
hi("@keyword.debug", { link = "WarningMsg" })
hi("@keyword.exception", { link = "Exception" })
hi("@keyword.conditional", { link = "Statement" })
hi("@keyword.conditional.ternary", { fg = colors.fg_3 })
hi("@keyword.directive", { link = "PreProc" })
hi("@keyword.directive.define", { link = "PreProc" })

hi("@comment", { link = "Comment" })
hi("@comment.documentation", { fg = colors.comment, italic = true })
hi("@comment.error", { link = "ErrorMsg" })
hi("@comment.warning", { link = "WarningMsg" })
hi("@comment.todo", { link = "Todo" })
hi("@comment.note", { link = "Special" })

hi("@markup.strong", { bold = true })
hi("@markup.italic", { italic = true })
hi("@markup.strikethrough", { strikethrough = true })
hi("@markup.underline", { underline = true })
hi("@markup.heading", { link = "Title" })
hi("@markup.heading.1", { link = "Title" })
hi("@markup.heading.2", { link = "Title" })
hi("@markup.heading.3", { link = "Title" })
hi("@markup.heading.4", { link = "Title" })
hi("@markup.heading.5", { link = "Title" })
hi("@markup.heading.6", { link = "Title" })
hi("@markup.quote", { fg = colors.fg_1, italic = true })
hi("@markup.math", { fg = colors.fg_3 })
hi("@markup.link", { link = "Link" })
hi("@markup.link.label", { link = "Link" })
hi("@markup.link.url", { fg = colors.cyan, underline = true })
hi("@markup.raw", { fg = colors.green })
hi("@markup.raw.block", { fg = colors.green })
hi("@markup.list", { fg = colors.fg_1 })
hi("@markup.list.checked", { fg = colors.green })
hi("@markup.list.unchecked", { fg = colors.fg_1 })

hi("@tag", { link = "Statement" })
hi("@tag.attribute", { fg = colors.fg_3, italic = true })
hi("@tag.delimiter", { link = "Delimiter" })

hi("@diff.plus", { link = "DiffAdd" })
hi("@diff.minus", { link = "DiffDelete" })
hi("@diff.delta", { link = "DiffChange" })

-- LSP semantic tokens
hi("@lsp.type.class", { link = "@type" })
hi("@lsp.type.decorator", { link = "@attribute" })
hi("@lsp.type.enum", { link = "@type" })
hi("@lsp.type.enumMember", { link = "@constant" })
hi("@lsp.type.function", { link = "@function" })
hi("@lsp.type.interface", { link = "@type" })
hi("@lsp.type.macro", { link = "@function.macro" })
hi("@lsp.type.method", { link = "@function.method" })
hi("@lsp.type.namespace", { link = "@module" })
hi("@lsp.type.parameter", { link = "@variable.parameter" })
hi("@lsp.type.property", { link = "@property" })
hi("@lsp.type.struct", { link = "@type" })
hi("@lsp.type.type", { link = "@type" })
hi("@lsp.type.typeParameter", { link = "@type" })
hi("@lsp.type.variable", { link = "@variable" })
hi("@lsp.typemod.function.defaultLibrary", { link = "@function.builtin" })
hi("@lsp.typemod.variable.defaultLibrary", { link = "@variable.builtin" })
hi("@lsp.typemod.variable.readonly", { fg = colors.fg_3 })

-- Help
hi("helpHeadline", {
  link = "Title",
})

hi("helpSectionDelim", {
  link = "Comment",
})

hi("helpExample", {
  link = "String",
})

hi("helpBar", {
  link = "Comment",
})

hi("helpHyperTextJump", {
  link = "Link",
})

hi("helpHyperTextEntry", {
  link = "Link",
})

hi("helpVim", {
  link = "String",
})

hi("helpCommand", {
  link = "String",
})

hi("helpHeader", {
  link = "String",
})

hi("helpNote", {
  link = "Todo",
})

hi("helpWarning", {
  link = "WarningMsg",
})

hi("helpDeprecated", {
  link = "ErrorMsg",
})

hi("helpURL", {
  link = "Link",
})

hi("diffAdded", {
  link = "DiffAdd",
})

hi("diffBDiffer", {
  link = "Normal",
})

hi("diffChanged", {
  link = "DiffChange",
})

hi("diffComment", {
  link = "Comment",
})

hi("diffCommon", {
  link = "Normal",
})

hi("diffDiffer", {
  link = "Normal",
})

hi("diffFile", {
  link = "DiffChange",
})

hi("diffIdentical", {
  link = "Normal",
})

hi("diffIndexLine", {
  link = "Normal",
})

hi("diffIsA", {
  link = "Normal",
})

hi("diffLine", {
  link = "Title",
})

hi("diffNewFile", {
  link = "Normal",
})

hi("diffNoEOL", {
  link = "Normal",
})

hi("diffOldFile", {
  link = "Normal",
})

hi("diffOnly", {
  link = "Normal",
})

hi("diffRemoved", {
  link = "DiffDelete",
})

hi("diffSubname", {
  link = "Normal",
})

-- Markdown
hi("markdownUrl", {
  link = "Link",
})

-- Git commit
hi("gitcommitSelectedFile", {
  link = "Link",
})

hi("gitcommitDiscardedFile", {
  link = "Link",
})

hi("gitcommitUntrackedFile", {
  link = "Link",
})

hi("gitcommitSummary", {
  link = "String",
})

return M
