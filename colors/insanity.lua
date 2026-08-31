local M = {}

vim.cmd("highlight clear")
vim.g.colors_name = "insanity"
vim.o.background = "dark"

local colors = {
  bg = "#000000",

  fg_0 = "#3b3b3b",
  fg_1 = "#808080",
  fg_2 = "#b9b9b9",
  fg_3 = "#ffffff",

  red = "#d75f5f",
  green = "#5faf5f",
  yellow = "#878700",
  blue = "#5f87ff",
  magenta = "#d787af",
  cyan = "#5fafaf",

  br_red = "#ff5f5f",
  br_green = "#87d787",
  br_yellow = "#ffd751",
  br_blue = "#5fafff",
  br_magenta = "#d75fd7",
  br_cyan = "#87ffff",
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
  fg = colors.fg_2,
})

hi("Directory", {
  fg = colors.blue,
})

hi("DiffAdd", {
  fg = colors.green,
})

hi("DiffChange", {
  fg = colors.br_yellow,
})

hi("DiffDelete", {
  fg = colors.red,
})

hi("DiffText", {
  bg = colors.red,
  fg = colors.fg_3,
})

hi("ErrorMsg", {
  fg = colors.br_red,
  nocombine = true,
})

hi("LineNr", {
  fg = colors.fg_2,
})

hi("LineNrAbove", {
  fg = colors.fg_1,
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

hi("SignColumn", {})

hi("Search", {
  bg = colors.br_magenta,
  fg = colors.fg_3,
})

hi("Title", {
  fg = colors.fg_2,
})

hi("QuickFixLine", {
  fg = colors.green,
})

hi("WarningMsg", {
  fg = colors.br_yellow,
  nocombine = true,
})

hi("WildMenu", {
  bg = colors.bg,
  fg = colors.fg_2,
})

-- Cursor and window links
hi("lCursor", {
  link = "Cursor",
})

hi("CursorIM", {
  link = "Cursor",
})

hi("CursorColumn", {
  link = "ColorColumn",
})

hi("CursorLine", {
  link = "ColorColumn",
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
  link = "NonText",
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

hi("SpecialKey", {
  link = "NonText",
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
  fg = colors.blue,
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

hi("MessageWindow", {
  link = "PmenuSel",
})

-- Spell checking
hi("SpellBad", {
  fg = colors.br_red,
})

hi("SpellCap", {
  fg = colors.magenta,
})

hi("SpellLocal", {
  link = "Normal",
})

hi("SpellRare", {
  link = "Normal",
})

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
  fg = colors.fg_1,
})

hi("Special", {
  bg = colors.bg,
  fg = colors.fg_2,
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

-- Diff
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

-- vim-sneak
hi("SneakLabel", {
  link = "Search",
})

return M
