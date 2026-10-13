-- colors/insanity.lua
--
-- Colorscheme for insane people.
--
-- Copyright (c) Robertus Chris <diawan@pm.me>
-- Copyright (c) Miquéias Medeiros <contatomiqueiasalvesdev@gmail.com>
--
-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/colors/insanity.vim
--
-- SPDX-License-Identifier: MIT

local M = {}

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.g.colors_name = "insanity"
vim.o.background = "dark"

-- Helpers

local function rgb(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

-- Mixes `fg` over `bg` with the given alpha (0..1)
local function blend(fg, bg, alpha)
  local fr, fgr, fb = rgb(fg)
  local br, bgr, bb = rgb(bg)
  local function mix(f, b)
    return math.floor(f * alpha + b * (1 - alpha) + 0.5)
  end
  return string.format("#%02x%02x%02x", mix(fr, br), mix(fgr, bgr), mix(fb, bb))
end

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Desaturate theme colors
local function desaturate(hex, factor)
  local r, g, b = rgb(hex)
  r, g, b = r / 255, g / 255, b / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local l = (max + min) / 2
  if max == min then
    return hex
  end

  local d = max - min
  local s = l > 0.5 and d / (2 - max - min) or d / (max + min)
  local h
  if max == r then
    h = (g - b) / d + (g < b and 6 or 0)
  elseif max == g then
    h = (b - r) / d + 2
  else
    h = (r - g) / d + 4
  end
  h = h / 6
  s = s * factor

  local function hue(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1 / 6 then return p + (q - p) * 6 * t end
    if t < 1 / 2 then return q end
    if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
    return p
  end

  local q = l < 0.5 and l * (1 + s) or l + s - l * s
  local p = 2 * l - q
  return string.format(
    "#%02x%02x%02x",
    math.floor(hue(p, q, h + 1 / 3) * 255 + 0.5),
    math.floor(hue(p, q, h) * 255 + 0.5),
    math.floor(hue(p, q, h - 1 / 3) * 255 + 0.5)
  )
end

-- Palette (grays, green strings and cyan keywords)

local colors = {
  -- single background; the only other "surface" tone is `cursorline`
  bg = "#000000",
  cursorline = "#111111", -- state tone: cursorline, selected menu item, matchparen, references
  popup_bg = "#0d0d0d",   -- completion menu and docs popup
  popup_sel = "#1c1c1c",  -- selected item inside the popup

  fg_0 = "#3b3b3b",
  fg_1 = "#808080",
  fg_2 = "#d8d8d8",
  fg_3 = "#d8d8d8",

  linenr = "#3a3a3a",
  linenr_cur = "#585858",
  linenr_above = "#2e2e2e",

  border = "#2a2a2a",
  border_subtle = "#0f0f0f",
  split = "#5a5a5a",
  statusline_nc = "#4f4f48",

  comment = "#4a4a4a",
  comment_doc = "#5a5a5a",

  red = "#d75f5f",
  green = "#7a9c7a",
  yellow = "#7d7d70",
  blue = "#5f87ff",
  magenta = "#d787af",
  cyan = "#80bdbd",

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

-- Tints derived from the palette
colors.visual_bg = blend(colors.fg_1, colors.bg, 0.35) -- neutral gray, no hue

-- Colors used for Markdown
local MD_SAT = 0.8
local md = {
  text = "#b9b9b9",                     -- fg_0
  title = "#dedede",                    -- fg_1
  cyan = desaturate("#5fafaf", MD_SAT), -- cyan
  blue = desaturate("#5f87ff", MD_SAT),
  violet = desaturate("#af87d7", MD_SAT),
  green = desaturate("#7a9c7a", MD_SAT),
  br_violet = desaturate("#af87ff", MD_SAT),
  br_blue = desaturate("#5fafff", MD_SAT),
}

-- Terminal colors

local terminal = {
  colors.bg,
  colors.red,
  colors.green,
  colors.yellow,
  colors.blue,
  colors.magenta,
  colors.cyan,
  colors.fg_2,
  colors.fg_1,
  colors.br_red,
  colors.br_green,
  colors.br_yellow,
  colors.br_blue,
  colors.br_magenta,
  colors.br_cyan,
  colors.fg_3,
}

for i, color in ipairs(terminal) do
  vim.g["terminal_color_" .. (i - 1)] = color
end

-- Highlight groups

local groups = {
  -- Editor UI
  ColorColumn = { bg = colors.cursorline },
  Conceal = { fg = colors.fg_0, nocombine = true },
  Cursor = { bg = colors.fg_2, fg = colors.bg },
  CursorLineNr = { fg = colors.linenr_cur, bold = true },
  Directory = { fg = colors.blue },

  DiffAdd = { bg = colors.diff_add_bg, fg = colors.green },
  DiffChange = { bg = colors.diff_change_bg, fg = colors.br_yellow },
  DiffDelete = { bg = colors.diff_delete_bg, fg = colors.red },
  DiffText = { bg = colors.diff_text_bg, fg = colors.fg_3 },

  ErrorMsg = { fg = colors.br_red, nocombine = true },
  LineNr = { fg = colors.linenr },
  LineNrAbove = { fg = colors.linenr_above },
  LineNrBelow = { link = "LineNrAbove" },
  MatchParen = { fg = colors.br_cyan, bg = colors.cursorline, bold = true },
  NonText = { fg = colors.fg_1, nocombine = true },

  Normal = { bg = colors.bg, fg = colors.fg_2, nocombine = true },
  NormalNC = { link = "Normal" },
  NormalFloat = { bg = colors.bg },
  FloatTitle = { link = "Title" },
  FloatFooter = { link = "Comment" },
  FloatBorder = { fg = colors.border, bg = colors.bg },

  SignColumn = {},

  Search = { bg = colors.br_magenta, fg = colors.fg_3 },
  IncSearch = { link = "Search" },
  CurSearch = { link = "Search" },
  Substitute = { link = "Search" },

  Title = { fg = colors.fg_2 },
  QuickFixLine = { fg = colors.green },
  WarningMsg = { fg = colors.fg_2, nocombine = true },
  WildMenu = { bg = colors.bg, fg = colors.fg_2 },
  Whitespace = { fg = colors.linenr_above },
  SpecialKey = { link = "NonText" },
  MsgArea = { link = "Normal" },
  MsgSeparator = { link = "StatusLine" },

  healthError = { link = "ErrorMsg" },
  healthWarning = { link = "WarningMsg" },
  healthSuccess = { fg = colors.green },

  lCursor = { link = "Cursor" },
  CursorIM = { link = "Cursor" },
  TermCursor = { link = "Cursor" },
  TermCursorNC = { fg = colors.bg, bg = colors.fg_1 },

  CursorColumn = { link = "ColorColumn" },
  CursorLine = { bg = colors.cursorline },
  CursorLineFold = { link = "ColorColumn" },
  CursorLineSign = { link = "CursorLineNr" },
  EndOfBuffer = { link = "NonText" },

  VertSplit = { fg = colors.split, bg = colors.bg },
  WinSeparator = { fg = colors.split, bg = colors.bg },
  WinBar = { link = "StatusLine" },
  WinBarNC = { link = "StatusLineNC" },

  Folded = { fg = colors.fg_1 },
  FoldColumn = { link = "Conceal" },

  MoreMsg = { link = "WarningMsg" },
  PopupNotification = { link = "WarningMsg" },
  Question = { link = "WarningMsg" },
  ModeMsg = { link = "Normal" },
  Terminal = { link = "Normal" },

  -- Completion menu
  Pmenu = { bg = colors.bg, fg = colors.fg_2, nocombine = true },
  PmenuSbar = { bg = colors.bg, nocombine = true },
  PmenuSel = { bg = colors.cursorline, fg = colors.fg_3 },
  PmenuThumb = { bg = colors.fg_0 },
  PmenuKind = { link = "Pmenu" },
  PmenuKindSel = { link = "PmenuSel" },
  PmenuExtra = { link = "Pmenu" },
  PmenuExtraSel = { link = "PmenuSel" },
  PmenuMatch = { fg = colors.fg_3, bold = true },
  PmenuMatchSel = { link = "PmenuMatch" },
  MessageWindow = { link = "PmenuSel" },

  SpellBad = { undercurl = true, sp = colors.red },
  SpellCap = { undercurl = true, sp = colors.blue },
  SpellLocal = { link = "Normal" },
  SpellRare = { link = "Normal" },

  -- Status line
  StatusLine = { bg = colors.bg, fg = colors.fg_1, nocombine = true },
  StatusLineNC = { bg = colors.bg, fg = colors.statusline_nc, nocombine = true },
  StatuslineTerm = { link = "StatusLine" },
  StatuslineTermNC = { link = "StatusLineNC" },

  -- Tab line
  TabLine = { bg = colors.bg, fg = colors.yellow, nocombine = true },
  TabLineFill = { bg = colors.bg, nocombine = true },
  TabLineSel = { bg = colors.bg, fg = colors.fg_1, nocombine = true },
  ToolbarLine = { link = "TabLine" },
  ToolbarButton = { link = "TabLineSel" },

  -- Visual selection: neutral tint, no fg, so syntax colors survive
  Visual = { bg = colors.visual_bg },
  VisualNOS = { link = "Visual" },

  -- Legacy syntax groups (mirror the Treesitter captures above, so
  -- filetypes without a Treesitter parser look the same)
  Keyword = { link = "Statement" },
  Conditional = { link = "Statement" },
  Repeat = { link = "Statement" },
  Label = { link = "Statement" },
  Tag = { link = "Statement" },
  Operator = { fg = colors.fg_3 },
  Number = { link = "Constant" },
  Float = { link = "Constant" },
  Include = { link = "PreProc" },
  Define = { link = "PreProc" },
  Macro = { link = "PreProc" },
  PreCondit = { link = "PreProc" },
  StorageClass = { link = "Type" },
  Structure = { link = "Type" },
  Typedef = { link = "Type" },
  SpecialChar = { fg = colors.br_cyan },
  SpecialComment = { link = "Special" },
  Debug = { link = "WarningMsg" },

  -- Classic syntax groups
  -- (no bg on Comment/Special/Todo so the cursorline shows through)
  String = { fg = colors.green, nocombine = true },
  Todo = { fg = colors.br_cyan },
  Comment = { fg = colors.comment },
  Special = { fg = colors.fg_2 },
  Delimiter = { fg = colors.fg_3 },
  Link = { fg = colors.cyan },
  Ignore = { link = "Comment" },

  Function = { link = "Special" },
  FunctionBuiltin = { fg = colors.fg_2 },
  Identifier = { link = "Special" },
  IdentifierBuiltin = { link = "Special" },
  PreProc = { link = "Special" },
  Type = { link = "Special" },
  TypeBuiltin = { link = "Normal" },
  Exception = { link = "WarningMsg" },
  Error = { link = "ErrorMsg" },
  Character = { link = "Normal" },
  Text = { link = "Normal" },
  Constant = { link = "Normal" },
  Underlined = { link = "Normal" },
  Statement = { link = "Link" },

  -- Diagnostics
  DiagnosticError = { fg = colors.br_red },
  DiagnosticWarn = { fg = colors.yellow },
  DiagnosticInfo = { fg = colors.cyan },
  DiagnosticHint = { fg = colors.br_blue },
  DiagnosticOk = { fg = colors.green },

  DiagnosticUnderlineError = { undercurl = true, sp = colors.br_red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = colors.br_yellow },
  DiagnosticUnderlineInfo = { undercurl = true, sp = colors.blue },
  DiagnosticUnderlineHint = { undercurl = true, sp = colors.cyan },
  DiagnosticUnderlineOk = { undercurl = true, sp = colors.green },

  -- Inline messages a bit calmer than the sign; no bg so cursorline shows
  DiagnosticVirtualTextError = { fg = colors.red },
  DiagnosticVirtualTextWarn = { fg = colors.yellow },
  DiagnosticVirtualTextInfo = { fg = colors.blue },
  DiagnosticVirtualTextHint = { fg = colors.cyan },
  DiagnosticVirtualTextOk = { fg = colors.green },

  DiagnosticFloatingError = { link = "DiagnosticError" },
  DiagnosticFloatingWarn = { link = "DiagnosticWarn" },
  DiagnosticFloatingInfo = { link = "DiagnosticInfo" },
  DiagnosticFloatingHint = { link = "DiagnosticHint" },
  DiagnosticFloatingOk = { link = "DiagnosticOk" },

  DiagnosticSignError = { link = "DiagnosticError" },
  DiagnosticSignWarn = { link = "DiagnosticWarn" },
  DiagnosticSignInfo = { link = "DiagnosticInfo" },
  DiagnosticSignHint = { link = "DiagnosticHint" },
  DiagnosticSignOk = { link = "DiagnosticOk" },

  DiagnosticDeprecated = { fg = colors.fg_1, strikethrough = true },
  DiagnosticUnnecessary = { fg = colors.fg_1 },

  -- LSP
  LspReferenceText = { bg = colors.cursorline },
  LspReferenceRead = { bg = colors.cursorline },
  LspReferenceWrite = { bg = colors.cursorline, underline = true },
  LspSignatureActiveParameter = { link = "MatchParen" },
  LspCodeLens = { link = "Comment" },
  LspCodeLensSeparator = { link = "Comment" },
  LspInlayHint = { fg = colors.comment },

  -- Treesitter: variables
  ["@variable"] = { fg = colors.fg_2 },
  ["@variable.member"] = { fg = colors.fg_3 },
  ["@variable.builtin"] = { fg = colors.fg_3 },
  ["@variable.parameter"] = { fg = colors.fg_3 },
  ["@variable.parameter.builtin"] = { fg = colors.fg_3 },
  ["@property"] = { fg = colors.fg_3 },

  ["@module"] = { link = "Special" },
  ["@module.builtin"] = { fg = colors.fg_3 },
  ["@label"] = { link = "Link" },

  ["@string.documentation"] = { fg = colors.green },
  ["@tag.attribute"] = { fg = colors.fg_3 },

  -- Treesitter: literals
  ["@constant"] = { link = "Constant" },
  ["@constant.builtin"] = { fg = colors.fg_3, bold = true },
  ["@constant.macro"] = { link = "PreProc" },
  ["@boolean"] = { fg = colors.fg_3, bold = true },
  ["@number"] = { link = "Constant" },
  ["@number.float"] = { link = "Constant" },

  ["@string"] = { link = "String" },
  ["@string.documentation"] = { fg = colors.green, italic = true },
  ["@string.regexp"] = { fg = colors.magenta },
  ["@string.escape"] = { fg = colors.br_cyan },
  ["@string.special"] = { fg = colors.br_cyan },
  ["@string.special.symbol"] = { fg = colors.fg_3 },
  ["@string.special.url"] = { fg = colors.cyan, underline = true },
  ["@character"] = { link = "Character" },
  ["@character.special"] = { fg = colors.br_cyan },

  -- Treesitter: types
  ["@type"] = { link = "Type" },
  ["@type.builtin"] = { link = "TypeBuiltin" },
  ["@type.definition"] = { link = "Type" },
  ["@type.qualifier"] = { link = "Statement" },

  ["@attribute"] = { link = "PreProc" },
  ["@attribute.builtin"] = { link = "PreProc" },

  -- Treesitter: functions
  ["@function"] = { fg = colors.fg_2 },
  ["@function.builtin"] = { link = "FunctionBuiltin" },
  ["@function.call"] = { link = "Function" },
  ["@function.macro"] = { link = "PreProc" },
  ["@function.method"] = { fg = colors.fg_2 },
  ["@function.method.call"] = { link = "Function" },
  ["@constructor"] = { link = "Special" },

  ["@operator"] = { fg = colors.fg_3 },

  -- Treesitter: keywords
  ["@keyword"] = { link = "Statement" },
  ["@keyword.coroutine"] = { link = "Statement" },
  ["@keyword.function"] = { link = "Statement" },
  ["@keyword.operator"] = { fg = colors.fg_3 },
  ["@keyword.import"] = { link = "Statement" },
  ["@keyword.type"] = { link = "Statement" },
  ["@keyword.modifier"] = { link = "Statement" },
  ["@keyword.repeat"] = { link = "Statement" },
  ["@keyword.return"] = { link = "Statement" },
  ["@keyword.debug"] = { link = "WarningMsg" },
  ["@keyword.exception"] = { link = "Exception" },
  ["@keyword.conditional"] = { link = "Statement" },
  ["@keyword.conditional.ternary"] = { fg = colors.fg_3 },
  ["@keyword.directive"] = { link = "PreProc" },
  ["@keyword.directive.define"] = { link = "PreProc" },

  -- Treesitter: punctuation
  ["@punctuation.bracket"] = { fg = colors.fg_3 },
  ["@punctuation.delimiter"] = { fg = colors.fg_3 },
  ["@punctuation.special"] = { fg = colors.fg_3 },

  -- Treesitter: comments (doc comments slightly brighter)
  ["@comment"] = { link = "Comment" },
  ["@comment.documentation"] = { fg = colors.comment_doc },
  ["@comment.error"] = { link = "ErrorMsg" },
  ["@comment.warning"] = { link = "WarningMsg" },
  ["@comment.todo"] = { link = "Todo" },
  ["@comment.note"] = { link = "Special" },

  -- Treesitter: markup
  ["@markup.strong"] = { bold = true },
  ["@markup.italic"] = { fg = colors.comment_doc, italic = true },
  ["@markup.strikethrough"] = { strikethrough = true, fg = colors.fg_1 },
  ["@markup.underline"] = { underline = true },
  ["@markup.heading"] = { link = "Title" },
  ["@markup.heading.1"] = { fg = colors.fg_3, bold = true },
  ["@markup.heading.2"] = { fg = colors.fg_3, bold = true },
  ["@markup.heading.3"] = { fg = colors.fg_2, bold = true },
  ["@markup.heading.4"] = { fg = colors.fg_2 },
  ["@markup.heading.5"] = { fg = colors.fg_1 },
  ["@markup.heading.6"] = { fg = colors.fg_1, italic = true },
  ["@markup.quote"] = { fg = colors.fg_1, italic = true },
  ["@markup.math"] = { fg = colors.br_cyan },
  ["@markup.link"] = { fg = colors.cyan },
  ["@markup.link.label"] = { fg = colors.cyan },
  ["@markup.link.url"] = { fg = colors.fg_1 },
  ["@markup.raw"] = { fg = colors.fg_3 },
  ["@markup.raw.block"] = { fg = colors.fg_2 },
  ["@markup.raw.delimiter"] = { fg = colors.fg_0 },
  ["@markup.list"] = { fg = colors.fg_1 },
  ["@markup.list.checked"] = { fg = colors.fg_0 },
  ["@markup.list.unchecked"] = { fg = colors.fg_2 },

  ["@tag"] = { link = "Statement" },
  ["@tag.attribute"] = { fg = colors.fg_3, italic = true },
  ["@tag.delimiter"] = { link = "Delimiter" },

  ["@diff.plus"] = { link = "DiffAdd" },
  ["@diff.minus"] = { link = "DiffDelete" },
  ["@diff.delta"] = { link = "DiffChange" },

  -- LSP semantic tokens
  ["@lsp.type.class"] = { link = "@type" },
  ["@lsp.type.comment"] = {}, -- let Treesitter handle comments
  ["@lsp.type.decorator"] = { link = "@attribute" },
  ["@lsp.type.enum"] = { link = "@type" },
  ["@lsp.type.enumMember"] = { link = "@constant" },
  ["@lsp.type.function"] = { link = "@function" },
  ["@lsp.type.interface"] = { link = "@type" },
  ["@lsp.type.macro"] = { link = "@function.macro" },
  ["@lsp.type.method"] = { link = "@function.method" },
  ["@lsp.type.namespace"] = { link = "@module" },
  ["@lsp.type.parameter"] = { link = "@variable.parameter" },
  ["@lsp.type.property"] = { link = "@property" },
  ["@lsp.type.struct"] = { link = "@type" },
  ["@lsp.type.type"] = { link = "@type" },
  ["@lsp.type.typeParameter"] = { link = "@type" },
  ["@lsp.type.variable"] = { link = "@variable" },
  ["@lsp.mod.deprecated"] = { strikethrough = true },
  ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
  ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
  ["@lsp.typemod.variable.readonly"] = { fg = colors.fg_3 },

  -- Help
  helpHeadline = { link = "Title" },
  helpSectionDelim = { link = "Comment" },
  helpExample = { link = "String" },
  helpBar = { link = "Comment" },
  helpHyperTextJump = { link = "Link" },
  helpHyperTextEntry = { link = "Link" },
  helpVim = { link = "String" },
  helpCommand = { link = "String" },
  helpHeader = { link = "String" },
  helpNote = { link = "Todo" },
  helpWarning = { link = "WarningMsg" },
  helpDeprecated = { link = "ErrorMsg" },
  helpURL = { link = "Link" },

  -- Diff (syntax)
  diffAdded = { link = "DiffAdd" },
  diffBDiffer = { link = "Normal" },
  diffChanged = { link = "DiffChange" },
  diffComment = { link = "Comment" },
  diffCommon = { link = "Normal" },
  diffDiffer = { link = "Normal" },
  diffFile = { link = "DiffChange" },
  diffIdentical = { link = "Normal" },
  diffIndexLine = { link = "Normal" },
  diffIsA = { link = "Normal" },
  diffLine = { link = "Title" },
  diffNewFile = { link = "Normal" },
  diffNoEOL = { link = "Normal" },
  diffOldFile = { link = "Normal" },
  diffOnly = { link = "Normal" },
  diffRemoved = { link = "DiffDelete" },
  diffSubname = { link = "Normal" },

  gitcommitSelectedFile = { link = "Link" },
  gitcommitDiscardedFile = { link = "Link" },
  gitcommitUntrackedFile = { link = "Link" },
  gitcommitSummary = { link = "String" },

  -- Filetype: LaTeX (vimtex)
  --
  -- vimtex 2.0+ replaced the legacy built-in tex.vim syntax groups with its
  -- own set (see :help vimtex-syntax-reference). Most specific command and
  -- argument groups are just `highlight def link`ed to a small set of
  -- "primitive" groups (texCmd, texMathZone, texOpt, etc.) unless a
  -- colorscheme overrides them directly. Targeting those primitives here
  -- means newer/less common command families still get sensible colors
  -- automatically instead of silently falling back to plain text.
  --
  -- Split: prose you actually typed (running text, document/section
  -- titles, the *content* wrapped by \textbf/\emph/\textit) stays neutral
  -- gray so it reads like the rest of the document. LaTeX *syntax*
  -- (commands, environments, macro definitions) gets the same muted cyan
  -- used for Statement/keywords elsewhere in the theme, so code and text
  -- are unmistakable at a glance without introducing new hues. Math zones
  -- get no background: only the delimiters ($, \[, \]) are colored, so
  -- prose vs. math is clear just from the "frame" around it.

  texCmd = { link = "Statement" },                    -- \foo, \item, ...
  texCmdType = { link = "Statement" },                -- \textbf, \emph, \tiny, ...
  texCmdEnv = { link = "Statement" },                 -- \begin, \end
  texEnvArgName = { fg = colors.magenta },            -- {itemize}, {figure}, ...
  texOpt = { fg = colors.fg_3 },                      -- [options], key=value args like inside \lstset{}
  texArg = { link = "Normal" },                       -- generic {argument} body: still just text

  texCmdPart = { fg = colors.fg_3, bold = true },     -- \part, \chapter, \section, ...
  texCmdRef = { link = "texCmd" },                    -- \ref, \label, \cite, \pageref, \eqref, ...
  texRefArg = { fg = colors.cyan, underline = true }, -- the {label-name} being referenced
  texCmdAccent = { fg = colors.fg_2 },                -- \', \", \^, ...
  texCmdGreek = { fg = colors.magenta },              -- \alpha, \beta, ...
  texCmdNew = { fg = colors.fg_3, bold = true },      -- \newcommand, \def, \let
  texCmdNewenv = { fg = colors.fg_3, bold = true },   -- \newenvironment

  texTitleArg = { fg = colors.fg_3, bold = true },    -- \title{...}: the document title
  texPartArgTitle = { fg = colors.fg_3 },             -- \section{...}, \chapter{...}: still prose

  -- Style commands color the text they wrap, not the command name.
  texStyleBold = { bold = true },
  texStyleItal = { italic = true },
  texStyleUnder = { underline = true },
  texStyleBoth = { bold = true, italic = true },
  texStyleBoldUnder = { bold = true, underline = true },
  texStyleItalUnder = { italic = true, underline = true },
  texStyleBoldItalUnder = { bold = true, italic = true, underline = true },

  -- Math zones: content stays neutral (reads like prose), only the
  -- delimiters get color, so $...$ and \[...\] visually "frame"
  -- themselves against surrounding text without any background fill.
  texMathDelimZoneX = { fg = colors.cyan, bold = true },  -- $...$
  texMathDelimZoneY = { fg = colors.cyan, bold = true },  -- $$...$$
  texMathDelimZoneTI = { fg = colors.cyan, bold = true }, -- \(...\)
  texMathDelimZoneZ = { fg = colors.cyan, bold = true },  -- \[...\]
  texMathDelimZoneV = { fg = colors.cyan, bold = true },
  texMathDelimZoneW = { fg = colors.cyan, bold = true },
  texMathDelimZoneT = { fg = colors.cyan, bold = true },
  texMathDelimZoneEnv = { fg = colors.cyan, bold = true },
  texMathDelimZoneEnsured = { fg = colors.cyan, bold = true },
  texMathDelimZoneLabel = { fg = colors.cyan, bold = true },

  texComment = { link = "Comment" },
  texCommentTodo = { link = "Todo" },
  texSpecialChar = { fg = colors.fg_3 }, -- %, &, _, \\, escaped specials
  texSymbol = { fg = colors.fg_3 },      -- table separators, ligature markers, literal symbols
  texLigature = { fg = colors.fg_1 },    -- --, ---, ``, '': typographic, not code
  texZone = { fg = colors.fg_2 },        -- verbatim/listings body: still literal text
  texError = { link = "ErrorMsg" },

  texFileArg = { fg = colors.fg_3 },   -- filenames in \input, \includegraphics, \bibliography, ...
  texLength = { fg = colors.magenta }, -- 12pt, 3.5cm, ...
  texParm = { fg = colors.fg_1 },      -- #1, #2 macro parameters

  -- vimtex compiler/status messages (health checks, :VimtexCompile output)
  VimtexSuccess = { link = "DiagnosticOk" },
  VimtexWarning = { link = "WarningMsg" },
  VimtexError = { link = "DiagnosticError" },
  VimtexInfo = { link = "DiagnosticInfo" },
  VimtexTodo = { link = "Todo" },
  VimtexFatal = { link = "ErrorMsg" },

  -- Plugins: git
  Added = { fg = colors.green },
  Changed = { fg = colors.yellow },
  Removed = { fg = colors.red },
  GitSignsAdd = { fg = colors.green },
  GitSignsChange = { fg = colors.yellow },
  GitSignsDelete = { fg = colors.red },

  -- Plugins: indent-blankline
  IblIndent = { fg = colors.linenr_above },
  IblScope = { fg = colors.fg_0 },

  -- Plugins: nvim-cmp
  CmpBorder = { fg = colors.border_subtle, bg = colors.bg },
  CmpDocBorder = { fg = colors.border_subtle, bg = colors.bg },

  CmpItemAbbr = { link = "Pmenu" },
  CmpItemAbbrDeprecated = { fg = colors.fg_1, strikethrough = true },
  CmpItemAbbrMatch = { link = "PmenuMatch" },
  CmpItemAbbrMatchFuzzy = { link = "PmenuMatch" },
  CmpItemKind = { link = "Special" },
  CmpItemMenu = { link = "Comment" },

  -- Plugins: blink.cmp
  BlinkCmpMenu = { fg = colors.fg_2, bg = colors.popup_bg },
  BlinkCmpMenuBorder = { fg = colors.border_subtle, bg = colors.popup_bg },
  BlinkCmpMenuSelection = { fg = colors.fg_3, bg = colors.popup_sel },
  BlinkCmpScrollBarThumb = { bg = colors.fg_0 },
  BlinkCmpScrollBarGutter = { bg = colors.popup_bg },

  BlinkCmpLabel = { fg = colors.fg_2 },
  BlinkCmpLabelDeprecated = { fg = colors.fg_1, strikethrough = true },
  BlinkCmpLabelMatch = { fg = colors.fg_3, bold = true },
  BlinkCmpLabelDetail = { fg = colors.comment },
  BlinkCmpLabelDescription = { fg = colors.comment },

  BlinkCmpKind = { fg = colors.fg_1 },
  BlinkCmpSource = { fg = colors.comment },
  BlinkCmpGhostText = { fg = colors.comment },

  BlinkCmpDoc = { fg = colors.fg_2, bg = colors.popup_bg },
  BlinkCmpDocBorder = { fg = colors.border_subtle, bg = colors.popup_bg },
  BlinkCmpDocSeparator = { fg = colors.border, bg = colors.popup_bg },
  BlinkCmpDocCursorLine = { bg = colors.popup_sel },

  BlinkCmpSignatureHelp = { fg = colors.fg_2, bg = colors.popup_bg },
  BlinkCmpSignatureHelpBorder = { fg = colors.border_subtle, bg = colors.popup_bg },
  BlinkCmpSignatureHelpActiveParameter = { link = "LspSignatureActiveParameter" },
}

for group, opts in pairs(groups) do
  hi(group, opts)
end

-- Markdown
local markdown_markup = {
  strong = { fg = md.green, bold = true },
  italic = { fg = md.cyan, italic = true },
  strikethrough = { strikethrough = true },
  underline = { underline = true },
  heading = { fg = md.title },
  ["heading.1"] = { fg = md.title },
  ["heading.2"] = { fg = md.title },
  ["heading.3"] = { fg = md.title },
  ["heading.4"] = { fg = md.title },
  ["heading.5"] = { fg = md.title },
  ["heading.6"] = { fg = md.title },
  quote = { fg = md.text },
  math = { fg = md.blue },
  link = { fg = md.blue },
  ["link.label"] = { fg = md.violet },
  ["link.url"] = { fg = md.blue },
  raw = { fg = md.blue },
  ["raw.block"] = { fg = md.blue },
  ["raw.delimiter"] = { fg = md.text },
  list = { fg = md.blue },
  ["list.checked"] = { fg = md.br_violet },
  ["list.unchecked"] = { fg = md.br_violet },
}

for name, opts in pairs(markdown_markup) do
  hi("@markup." .. name .. ".markdown", opts)
  hi("@markup." .. name .. ".markdown_inline", opts)
  hi("@markup.math.latex", { fg = md.blue })
end

-- Exposed so other themes (e.g. lualine) can reuse the palette
M.colors = colors
M.blend = blend

return M
