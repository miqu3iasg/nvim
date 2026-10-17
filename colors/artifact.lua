-- colors/artifact.lua
--
-- A relic of the old terminal, where simplicity was a feature and every
-- color had a purpose.
--
-- Copyright (c) Miquéias Medeiros <contatomiqueiasalvesdev@gmail.com>
--
-- SPDX-License-Identifier: MIT

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "artifact"

local set_hl = vim.api.nvim_set_hl
local transparent = vim.g.darkthrone_transparent == true
local underline_on = vim.g.darkthrone_underline ~= false
local italic_on = vim.g.transilvanian_italic == true

local function hex2rgb(h)
  h = h:gsub("#", "")
  return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
end

-- Mixes fg over bg with opacity a (0..1).
local function blend(fg, a, bg)
  local fr, fgr, fb = hex2rgb(fg)
  local br, bgr, bb = hex2rgb(bg)
  local function ch(f, b)
    return math.floor(math.max(0, math.min(255, a * f + (1 - a) * b)) + 0.5)
  end
  return string.format("#%02x%02x%02x", ch(fr, br), ch(fgr, bgr), ch(fb, bb))
end

-- Nearest xterm-256 index, from the 6x6x6 cube or the gray ramp.
local levels = { 0, 95, 135, 175, 215, 255 }
local function to256(hex)
  local r, g, b = hex2rgb(hex)
  local function cv(v)
    if v < 48 then
      return 0
    elseif v < 115 then
      return 1
    end
    return math.floor((v - 35) / 40)
  end
  local ri, gi, bi = cv(r), cv(g), cv(b)
  local cr, cg, cb = levels[ri + 1], levels[gi + 1], levels[bi + 1]
  local cube_idx = 16 + 36 * ri + 6 * gi + bi
  local cube_d = (r - cr) ^ 2 + (g - cg) ^ 2 + (b - cb) ^ 2

  local avg = (r + g + b) / 3
  local gray_i = math.max(0, math.min(23, math.floor((avg - 8) / 10 + 0.5)))
  local gv = 8 + gray_i * 10
  local gray_d = (r - gv) ^ 2 + (g - gv) ^ 2 + (b - gv) ^ 2

  if gray_d < cube_d then
    return 232 + gray_i
  end
  return cube_idx
end

local P = {
  bg = "#000000",
  surface = "#1c1c1c",
  visual = "#303030",

  bright = "#e4e4e4",
  fg = "#b8b8b8",
  mid = "#9a9a9a",
  dim = "#6c6c6c",

  blue = "#7a88c8",
  cyan = "#5f9f9f",
  green = "#6aa86a",
  yellow = "#c9b458",
  magenta = "#b080b0",
  pink = "#c88a8a",
  orange = "#c8935a",
  red = "#b85050",

  teal = "#5f9f9f",
  blood = "#b85050",
}

local c = {
  bg = P.bg,
  fg = P.fg,
  line = P.surface,
  visual = P.visual,
  comment = P.blue,
  string = P.pink,
  type = P.green,
  keyword = P.yellow,
  func = P.fg,
  constant = P.pink,
  number = P.pink,
  operator = P.fg,
  property = P.fg,
  punct = P.fg,
  alt = P.cyan,
  red = P.red,
  warn = P.orange,
}

local NONE = "NONE"
local bg_main = transparent and NONE or c.bg
local bg_float = transparent and NONE or "#121212"

local diff_add = blend(P.bright, 0.12, P.bg)
local diff_change = blend(P.teal, 0.22, P.bg)
local diff_delete = blend(P.blood, 0.35, P.bg)
local code_bg = P.surface
local faint = blend(P.dim, 0.5, P.bg)

local fmt_keys = { "strikethrough", "undercurl", "underline", "nocombine", "reverse", "italic", "bold" }

local function parse_fmt(fmt)
  local out = {}
  if type(fmt) ~= "string" or fmt == "none" or fmt == NONE then
    return out
  end
  for part in fmt:gmatch("[^,%s]+") do
    local rest = part
    local progressed = true
    while progressed and #rest > 0 do
      progressed = false
      for _, key in ipairs(fmt_keys) do
        if rest:sub(1, #key) == key then
          if (underline_on or (key ~= "underline" and key ~= "undercurl"))
              and (italic_on or key ~= "italic") then
            out[key] = true
          end
          rest = rest:sub(#key + 1)
          progressed = true
          break
        end
      end
    end
  end
  return out
end

local function is_hex(v)
  return type(v) == "string" and v:sub(1, 1) == "#"
end

local function build(spec)
  local def = parse_fmt(spec.fmt)
  local cterm = {}
  for k in pairs(def) do
    cterm[k == "undercurl" and "underline" or k] = true
  end
  def.cterm = cterm
  if spec.fg then
    def.fg = spec.fg
    if is_hex(spec.fg) then
      def.ctermfg = to256(spec.fg)
    end
  end
  if spec.bg then
    def.bg = spec.bg
    if is_hex(spec.bg) then
      def.ctermbg = to256(spec.bg)
    end
  end
  if spec.sp then
    def.sp = spec.sp
  end
  return def
end

local function hi(group, spec)
  if spec.link then
    set_hl(0, group, { link = spec.link })
  else
    set_hl(0, group, build(spec))
  end
end

local function apply(tbl)
  for group, spec in pairs(tbl) do
    hi(group, spec)
  end
end

local function link_all(tbl)
  for from, to in pairs(tbl) do
    set_hl(0, from, { link = to, force = true })
  end
end

local editor = {
  Normal = { fg = c.fg, bg = bg_main },
  NormalNC = { fg = c.fg, bg = bg_main },
  MsgArea = { fg = c.fg, bg = bg_main },
  ColorColumn = { bg = c.line },
  Conceal = { fg = c.func },
  Cursor = { fg = P.bg, bg = P.fg },
  CursorIM = { fg = P.bg, bg = P.bright },
  CursorColumn = { bg = c.line },
  CursorLine = { bg = c.line },
  CursorLineNr = { fg = c.type, bg = c.line, fmt = "bold" },
  CursorLineSign = { bg = c.line },
  CursorLineFold = { fg = c.fg, bg = c.line },
  LineNr = { fg = c.comment, bg = bg_main },
  LineNrAbove = { fg = c.comment, bg = bg_main },
  LineNrBelow = { fg = c.comment, bg = bg_main },
  SignColumn = { fg = c.fg, bg = bg_main },
  FoldColumn = { fg = c.comment, bg = bg_main },
  Folded = { fg = c.comment, bg = c.line },
  EndOfBuffer = { fg = c.comment },
  NonText = { fg = c.comment },
  SpecialKey = { fg = c.comment, fmt = "bold" },
  Whitespace = { fg = faint },
  Directory = { fg = c.type },
  Title = { fg = c.type, fmt = "bold" },
  Underlined = { fg = c.fg, fmt = "underline" },
  Ignore = { fg = c.comment },

  Visual = { bg = c.visual },
  VisualNOS = { bg = c.visual, fmt = "underline" },
  Search = { fg = P.bg, bg = P.yellow },
  CurSearch = { fg = P.bg, bg = P.orange },
  IncSearch = { fg = P.bg, bg = P.orange },
  Substitute = { fg = P.bg, bg = P.mid },
  MatchParen = { fg = c.type, bg = c.visual, fmt = "bold" },
  QuickFixLine = { bg = c.line, fmt = "bold" },

  -- Dedicated group for yank flash. Use it in your TextYankPost autocmd:
  --   vim.hl.on_yank({ higroup = "YankHighlight" })
  YankHighlight = { fg = P.bg, bg = "#d787af" },

  ErrorMsg = { fg = c.red, fmt = "bold" },
  WarningMsg = { fg = c.warn, fmt = "bold" },
  ModeMsg = { fg = c.fg, fmt = "bold" },
  MoreMsg = { fg = c.func, fmt = "bold" },
  Question = { fg = c.fg },
  MsgSeparator = { fg = c.comment, bg = c.line },

  VertSplit = { fg = c.comment },
  WinSeparator = { fg = c.comment },
  WinBar = { fg = c.fg, bg = bg_main },
  WinBarNC = { fg = c.comment, bg = bg_main },
  StatusLine = { fg = c.fg, bg = c.line },
  StatusLineNC = { fg = c.comment, bg = c.line },
  TabLine = { fg = c.comment, bg = c.line },
  TabLineFill = { fg = c.comment, bg = c.line },
  TabLineSel = { fg = c.type, bg = c.visual, fmt = "bold" },
  TitleBar = { fg = c.fg, bg = bg_main },
  TitleBarNC = { fg = c.comment, bg = bg_main },
  ToolbarButton = { fg = c.type, bg = c.line, fmt = "bold" },
  ToolbarLine = { bg = bg_main },

  SpellBad = { sp = c.red, fmt = "undercurl" },
  SpellCap = { sp = c.warn, fmt = "undercurl" },
  SpellLocal = { sp = c.comment, fmt = "undercurl" },
  SpellRare = { sp = c.comment, fmt = "undercurl" },

  DiffAdd = { fg = c.fg, bg = diff_add },
  DiffChange = { fg = c.fg, bg = diff_change },
  DiffDelete = { fg = c.red, bg = diff_delete },
  DiffText = { fg = c.type, bg = blend(P.teal, 0.4, P.bg) },
  Added = { fg = P.green },
  Changed = { fg = P.yellow },
  Removed = { fg = P.red },
  diffFile = { fg = c.type, fmt = "bold" },
  diffLine = { fg = c.alt },

  NormalFloat = { fg = c.fg, bg = bg_float },
  FloatBorder = { fg = c.comment, bg = bg_float },
  FloatTitle = { fg = c.type, bg = bg_float, fmt = "bold" },
  FloatFooter = { fg = c.comment, bg = bg_float },
  Pmenu = { fg = c.fg, bg = bg_float },
  PmenuSel = { fg = c.type, bg = c.visual },
  PmenuKind = { fg = c.comment, bg = bg_float },
  PmenuKindSel = { fg = c.fg, bg = c.visual },
  PmenuExtra = { fg = c.comment, bg = bg_float },
  PmenuExtraSel = { fg = c.fg, bg = c.visual },
  PmenuMatch = { fg = c.type, bg = bg_float, fmt = "bold" },
  PmenuMatchSel = { fg = c.type, bg = c.visual, fmt = "bold" },
  PmenuSbar = { bg = bg_float },
  PmenuThumb = { bg = c.comment },
  WildMenu = { fg = c.type, bg = c.visual },

  Terminal = { fg = c.fg, bg = bg_main },
  TermCursor = { fg = P.bg, bg = P.fg },
  debugPC = { bg = c.line },
  debugBreakpoint = { fg = c.red },
}

local syntax = {
  Comment = { fg = P.blue },
  Constant = { fg = P.pink },
  String = { fg = P.pink },
  Character = { fg = P.pink },
  Number = { fg = P.pink },
  Boolean = { fg = P.pink },
  Float = { fg = P.pink },
  Identifier = { fg = P.fg },
  Function = { fg = P.fg },
  Statement = { fg = P.yellow },
  Conditional = { fg = P.yellow },
  Repeat = { fg = P.yellow },
  Label = { fg = P.yellow },
  Operator = { fg = P.fg },
  Keyword = { fg = P.yellow },
  Exception = { fg = P.yellow },
  PreProc = { fg = P.magenta },
  Include = { fg = P.magenta },
  Define = { fg = P.magenta },
  Macro = { fg = P.magenta },
  PreCondit = { fg = P.magenta },
  Type = { fg = P.green },
  StorageClass = { fg = P.green },
  Structure = { fg = P.green },
  Typedef = { fg = P.green },
  Special = { fg = P.orange },
  SpecialChar = { fg = P.orange },
  Tag = { fg = P.orange },
  Delimiter = { fg = P.fg },
  SpecialComment = { fg = P.blue },
  Debug = { fg = P.orange },
  Error = { fg = P.bright, bg = P.red },
  Todo = { fg = P.bg, bg = P.yellow },
}

local lsp = {
  LspInlayHint = { fg = c.comment, bg = c.line },
  LspReferenceText = { bg = c.visual },
  LspReferenceRead = { bg = c.visual },
  LspReferenceWrite = { bg = c.visual, fmt = "underline" },
  LspCodeLens = { fg = c.comment },
  LspCodeLensSeparator = { fg = c.comment },
  LspSignatureActiveParameter = { fg = c.type, fmt = "bold,underline" },
}

local diag = {
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.warn },
  DiagnosticInfo = { fg = P.cyan },
  DiagnosticHint = { fg = P.blue },
  DiagnosticOk = { fg = P.green },
  DiagnosticUnnecessary = { fg = c.comment },
  DiagnosticDeprecated = { fg = c.comment, fmt = "strikethrough" },

  DiagnosticVirtualTextError = { fg = P.red },
  DiagnosticVirtualTextWarn = { fg = P.orange },
  DiagnosticVirtualTextInfo = { fg = P.cyan },
  DiagnosticVirtualTextHint = { fg = P.blue },
  DiagnosticVirtualTextOk = { fg = P.green },

  DiagnosticUnderlineError = { sp = P.red, fmt = "underline" },
  DiagnosticUnderlineWarn = { sp = P.orange, fmt = "underline" },
  DiagnosticUnderlineInfo = { sp = P.cyan, fmt = "underline" },
  DiagnosticUnderlineHint = { sp = P.blue, fmt = "underline" },
  DiagnosticUnderlineOk = { sp = P.green, fmt = "underline" },

  DiagnosticFloatingError = { fg = c.red },
  DiagnosticFloatingWarn = { fg = c.warn },
  DiagnosticFloatingInfo = { fg = P.cyan },
  DiagnosticFloatingHint = { fg = P.blue },
  DiagnosticSignError = { fg = c.red },
  DiagnosticSignWarn = { fg = c.warn },
  DiagnosticSignInfo = { fg = P.cyan },
  DiagnosticSignHint = { fg = P.blue },
}

-- Heading levels fade in brightness, not in hue.
local heading_levels = { P.bright, P.bright, P.fg, P.fg, P.mid, P.mid }

local markdown = {
  ["@keyword.directive.markdown"] = { fg = c.alt },
  ["@punctuation.special.markdown"] = { fg = c.fg },
  ["@punctuation.delimiter.markdown"] = { fg = c.fg },

  ["@markup.list.markdown"] = { fg = c.alt, fmt = "bold" },
  ["@markup.list.checked.markdown"] = { fg = c.alt, fmt = "bold" },
  ["@markup.list.unchecked.markdown"] = { fg = c.alt, fmt = "bold" },

  ["@markup.quote.markdown"] = { fg = P.mid, fmt = "italic" },

  ["@markup.raw.block.markdown"] = { fg = c.fg },
  ["@markup.raw.delimiter.markdown"] = { fg = c.alt },
  ["@label.markdown"] = { fg = c.alt, fmt = "italic" },

  ["@markup.strong.markdown_inline"] = { fg = P.bright, fmt = "bold" },
  ["@markup.italic.markdown_inline"] = { fg = P.mid, fmt = "italic" },
  ["@markup.strikethrough.markdown_inline"] = { fg = c.comment, fmt = "strikethrough" },

  ["@markup.raw.markdown_inline"] = { fg = P.teal, bg = code_bg },
  -- Math (inline and block) uses the theme's cyan.
  ["@markup.math.markdown_inline"] = { fg = c.alt },
  ["@markup.math.markdown"] = { fg = c.alt },
  ["@markup.math.latex"] = { fg = c.alt },
  ["@punctuation.special.markdown_inline"] = { fg = c.type },

  ["@markup.link.markdown_inline"] = { fg = c.comment },
  ["@markup.link.label.markdown_inline"] = { fg = c.type, bg = c.line, fmt = "underline" },
  ["@markup.link.url.markdown_inline"] = { fg = c.alt, fmt = "underline" },

  ["@string.escape.markdown_inline"] = { fg = c.alt },
  ["@conceal.markdown_inline"] = { fg = c.comment },

  ["@markup.heading.markdown"] = { fg = P.bright, fmt = "bold" },
  ["@markup.heading.marker.markdown"] = { fg = P.bright },
}

for i, color in ipairs(heading_levels) do
  local fmt = i == 1 and "bold,underline" or "bold"
  markdown[("@markup.heading.%d.markdown"):format(i)] = { fg = color, fmt = fmt }
  markdown[("@markup.heading.%d.marker.markdown"):format(i)] = { fg = color }
end

-- Legacy regex-based markdown groups point to the treesitter ones.
local markdown_links = {
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

-- Frontmatter YAML gets its own namespace, enabled only in markdown
-- windows. Regular YAML files are left untouched.
local frontmatter_ns = vim.api.nvim_create_namespace("transilvanian_alt_markdown")
local frontmatter = {
  ["@property.yaml"] = { fg = c.alt },
  ["@string.yaml"] = { fg = c.fg },
  ["@number.yaml"] = { fg = c.number },
  ["@number.float.yaml"] = { fg = c.number },
  ["@boolean.yaml"] = { fg = c.number },
  ["@constant.builtin.yaml"] = { fg = P.mid },
  ["@label.yaml"] = { fg = c.alt },
  ["@type.yaml"] = { fg = c.alt },
  ["@punctuation.delimiter.yaml"] = { fg = c.comment },
  ["@punctuation.bracket.yaml"] = { fg = c.comment },
}
for name, spec in pairs(frontmatter) do
  set_hl(frontmatter_ns, name, build(spec))
end

-- LaTeX uses :syntax, so treesitter stays off for tex.
local tex = {
  texComment = { fg = c.comment },
  texStatement = { fg = c.keyword },
  texCmd = { fg = c.keyword },
  texCmdName = { fg = c.keyword },
  texCmdEnv = { fg = c.type },
  texCmdPart = { fg = c.type, fmt = "bold" },
  texCmdTitle = { fg = c.type, fmt = "bold" },
  texCmdRef = { fg = c.alt },
  texCmdClass = { fg = c.type },
  texCmdPackage = { fg = c.type },
  texCmdStyle = { fg = c.keyword, fmt = "italic" },
  texCmdBold = { fg = c.type, fmt = "bold" },
  texCmdItal = { fg = P.mid, fmt = "italic" },
  texEnvName = { fg = c.type },
  texBeginEnd = { fg = c.keyword },
  texBeginEndName = { fg = c.type },
  texSection = { fg = c.type, fmt = "bold" },
  texPartArgTitle = { fg = c.type, fmt = "bold" },
  texTitleArg = { fg = c.type, fmt = "bold" },
  texRefArg = { fg = c.alt },
  texOpt = { fg = P.mid },
  texOptSep = { fg = c.punct },
  texArg = { fg = c.fg },
  texDelim = { fg = c.punct },
  texMathZone = { fg = c.type },
  texMathZoneEnv = { fg = c.type },
  texMathZoneEnvStarred = { fg = c.type },
  texMathZoneX = { fg = c.type },
  texMathZoneXX = { fg = c.type },
  texMathZoneEnsured = { fg = c.type },
  texMathEnvArgName = { fg = c.alt },
  texMathDelim = { fg = c.alt },
  texMathDelimZone = { fg = c.alt },
  texMathOper = { fg = c.operator },
  texMathSymbol = { fg = c.type },
  texMathCmd = { fg = c.keyword },
  texMathCmdText = { fg = c.keyword },
  texMathText = { fg = c.fg },
  texMathSuperSub = { fg = c.alt },
  texMathSub = { fg = c.type },
  texMathSuper = { fg = c.type },
  texNumber = { fg = c.number },
  texSpecialChar = { fg = c.keyword },
  texLength = { fg = c.number },
  texFileArg = { fg = c.string },
  texFileOpt = { fg = P.mid },
  texTodo = { fg = P.bg, bg = P.yellow, fmt = "bold" },
  texError = { fg = c.red, fmt = "bold" },
  texTheoremEnvOpt = { fg = P.mid },
  texLigature = { fg = c.type },
  texAccent = { fg = c.type },
  texUrlArg = { fg = c.alt, fmt = "underline" },
  texRefOpt = { fg = P.mid },
  texCiteArg = { fg = c.alt },
  texLabelArg = { fg = c.alt },
  texVerbZone = { fg = c.fg, bg = code_bg },
  texCmdVerb = { fg = c.keyword },
  texInputFile = { fg = c.string },
  VimtexInfo = { fg = P.cyan },
  VimtexWarning = { fg = c.warn },
  VimtexError = { fg = c.red },
  VimtexSuccess = { fg = c.type },
}

local plugins = {}

plugins.oil = {
  OilDir = { fg = P.blue, fmt = "bold" },
  OilDirIcon = { fg = P.blue },
  OilFile = { fg = c.fg },
  OilLink = { fg = P.cyan },
  OilLinkTarget = { fg = c.comment },
  OilOrphanLink = { fg = c.red },
  OilOrphanLinkTarget = { fg = c.red },
  OilHidden = { fg = c.dim or P.dim },
  OilDirHidden = { fg = P.dim, fmt = "bold" },
  OilFileHidden = { fg = P.dim },
  OilLinkHidden = { fg = P.dim },
  OilOrphanLinkHidden = { fg = c.red },
  OilExecutable = { fg = P.green, fmt = "bold" },
  OilSocket = { fg = P.magenta },

  OilCreate = { fg = c.type, fmt = "bold" },
  OilCopy = { fg = c.type, fmt = "bold" },
  OilMove = { fg = c.warn },
  OilChange = { fg = c.warn },
  OilDelete = { fg = c.red },
  OilPurge = { fg = c.red, fmt = "bold" },
  OilRestore = { fg = c.type, fmt = "bold" },
  OilTrash = { fg = c.comment },
  OilTrashSourcePath = { fg = c.comment },

  OilTypeDir = { fg = P.blue, fmt = "bold" },
  OilTypeFile = { fg = c.comment },
  OilTypeLink = { fg = P.cyan },
  OilTypeFifo = { fg = c.comment },
  OilTypeSocket = { fg = c.comment },
  OilTypeUnknown = { fg = c.comment },
  OilPermissionNone = { fg = c.comment },
  OilPermissionRead = { fg = c.warn },
  OilPermissionWrite = { fg = c.red },
  OilPermissionExecute = { fg = c.type },
}

plugins.special = {
  LazyNormal = { bg = c.bg_float },
  MasonNormal = { bg = c.bg_float },
}

plugins.bufferline = {
  BufferLineBufferSelected = { fg = P.bright, fmt = "bold" },
}

plugins.blink = {
  BlinkCmpMenu = { link = "Pmenu" },
  BlinkCmpMenuBorder = { link = "FloatBorder" },
  BlinkCmpMenuSelection = { link = "PmenuSel" },
  BlinkCmpScrollBarThumb = { link = "PmenuThumb" },
  BlinkCmpScrollBarGutter = { link = "PmenuSbar" },
  BlinkCmpLabel = { link = "Pmenu" },
  BlinkCmpLabelMatch = { link = "PmenuMatch" },
  BlinkCmpLabelDeprecated = { fg = c.comment, fmt = "strikethrough" },
  BlinkCmpLabelDetail = { fg = c.comment },
  BlinkCmpLabelDescription = { fg = c.comment },
  BlinkCmpKind = { link = "PmenuKind" },
  BlinkCmpSource = { link = "PmenuExtra" },
  BlinkCmpGhostText = { fg = P.dim },
  BlinkCmpDoc = { link = "NormalFloat" },
  BlinkCmpDocBorder = { link = "FloatBorder" },
  BlinkCmpDocSeparator = { link = "FloatBorder" },
  BlinkCmpDocCursorLine = { bg = c.visual },
  BlinkCmpSignatureHelp = { link = "NormalFloat" },
  BlinkCmpSignatureHelpBorder = { link = "FloatBorder" },
  BlinkCmpSignatureHelpActiveParameter = { fg = c.type, fmt = "bold,underline" },
}

plugins.cmp = {
  CmpItemAbbr = { fg = c.fg },
  CmpItemAbbrDeprecated = { fg = c.comment, fmt = "strikethrough" },
  CmpItemAbbrMatch = { link = "PmenuMatch" },
  CmpItemAbbrMatchFuzzy = { link = "PmenuMatch" },
  CmpItemMenu = { link = "PmenuExtra" },
  CmpItemKind = { link = "PmenuKind" },
}

do
  local kind_color = {
    Default = c.keyword,
    Array = c.keyword,
    Boolean = c.constant,
    Class = c.type,
    Color = c.fg,
    Constant = c.constant,
    Constructor = c.type,
    Enum = c.type,
    EnumMember = c.constant,
    Event = P.orange,
    Field = c.property,
    File = c.fg,
    Folder = P.blue,
    Function = c.func,
    Interface = c.type,
    Key = c.keyword,
    Keyword = c.keyword,
    Method = c.func,
    Module = P.magenta,
    Namespace = P.magenta,
    Null = c.type,
    Number = c.number,
    Object = c.type,
    Operator = c.operator,
    Package = P.magenta,
    Property = c.property,
    Reference = c.type,
    Snippet = P.orange,
    String = c.string,
    Struct = c.type,
    Text = c.fg,
    TypeParameter = c.type,
    Unit = c.fg,
    Value = c.fg,
    Variable = c.fg,
  }
  for kind, color in pairs(kind_color) do
    plugins.cmp["CmpItemKind" .. kind] = { fg = color }
    plugins.blink["BlinkCmpKind" .. kind] = { fg = color }
  end
end

plugins.gitsigns = {
  GitSignsAdd = { link = "Added" },
  GitSignsChange = { link = "Changed" },
  GitSignsDelete = { link = "Removed" },
  GitSignsAddNr = { link = "Added" },
  GitSignsChangeNr = { link = "Changed" },
  GitSignsDeleteNr = { link = "Removed" },
  GitSignsAddLn = { bg = diff_add },
  GitSignsChangeLn = { bg = diff_change },
  GitSignsDeleteLn = { bg = diff_delete },
  GitSignsAddCul = { fg = P.green, bg = c.line },
  GitSignsChangeCul = { fg = P.yellow, bg = c.line },
  GitSignsDeleteCul = { fg = P.red, bg = c.line },
  GitSignsAddInline = { link = "DiffAdd" },
  GitSignsChangeInline = { link = "DiffChange" },
  GitSignsDeleteInline = { link = "DiffDelete" },
  GitSignsAddPreview = { link = "DiffAdd" },
  GitSignsDeletePreview = { link = "DiffDelete" },
  GitSignsCurrentLineBlame = { fg = c.comment },
}

plugins.diffview = {
  DiffviewFilePanelTitle = { fg = c.type, fmt = "bold" },
  DiffviewFilePanelCounter = { fg = c.alt, fmt = "bold" },
  DiffviewFilePanelFileName = { fg = c.fg },
  DiffviewNormal = { link = "Normal" },
  DiffviewCursorLine = { link = "CursorLine" },
  DiffviewVertSplit = { link = "VertSplit" },
  DiffviewSignColumn = { link = "SignColumn" },
  DiffviewStatusLine = { link = "StatusLine" },
  DiffviewStatusLineNC = { link = "StatusLineNC" },
  DiffviewEndOfBuffer = { link = "EndOfBuffer" },
  DiffviewFilePanelRootPath = { fg = c.comment },
  DiffviewFilePanelPath = { fg = c.comment },
  DiffviewFilePanelInsertions = { fg = P.green },
  DiffviewFilePanelDeletions = { fg = c.red },
  DiffviewStatusAdded = { link = "Added" },
  DiffviewStatusUntracked = { link = "Changed" },
  DiffviewStatusModified = { link = "Changed" },
  DiffviewStatusRenamed = { link = "Changed" },
  DiffviewStatusCopied = { link = "Changed" },
  DiffviewStatusTypeChange = { link = "Changed" },
  DiffviewStatusUnmerged = { link = "Changed" },
  DiffviewStatusUnknown = { link = "Removed" },
  DiffviewStatusDeleted = { link = "Removed" },
  DiffviewStatusBroken = { link = "Removed" },
}

plugins.neogit = {
  NeogitBranch = { fg = c.alt },
  NeogitUntrackedfiles = { fg = c.warn },
  NeogitUnpulledchanges = { fg = c.warn },
  NeogitUnmergedchanges = { fg = c.keyword, fmt = "bold" },
  NeogitDiffAdd = { link = "DiffAdd" },
  NeogitDiffAddHighlight = { link = "DiffAdd" },
  NeogitDiffAddCursor = { bg = diff_add },
  NeogitDiffDelete = { link = "DiffDelete" },
  NeogitDiffDeleteHighlight = { link = "DiffDelete" },
  NeogitDiffDeleteCursor = { bg = diff_delete },
  NeogitDiffContext = { bg = c.line },
  NeogitDiffContextHighlight = { bg = c.line },
  NeogitDiffContextCursor = { bg = c.line },
  NeogitSectionHeader = { fg = c.type, fmt = "bold" },
  NeogitHunkHeader = { fg = c.comment },
  NeogitHunkHeaderHighlight = { fg = c.comment },
  NeogitHunkHeaderCursor = { fg = c.comment, fmt = "bold" },
  NeogitHunkMergeHeader = { fg = c.warn, bg = c.line, fmt = "bold" },
  NeogitHunkMergeHeaderHighlight = { fg = c.warn, bg = c.line },
  NeogitHunkMergeHeaderCursor = { fg = c.warn, bg = c.line, fmt = "bold" },
}

plugins.neo_tree = {
  NeoTreeNormal = { fg = c.fg, bg = bg_main },
  NeoTreeNormalNC = { fg = c.fg, bg = bg_main },
  NeoTreeVertSplit = { fg = c.comment, bg = bg_main },
  NeoTreeWinSeparator = { fg = c.comment, bg = bg_main },
  NeoTreeEndOfBuffer = { fg = c.comment, bg = bg_main },
  NeoTreeRootName = { fg = c.type, fmt = "bold" },
  NeoTreeDirectoryName = { fg = P.blue },
  NeoTreeDirectoryIcon = { fg = P.blue },
  NeoTreeGitAdded = { link = "Added" },
  NeoTreeGitDeleted = { link = "Removed" },
  NeoTreeGitModified = { link = "Changed" },
  NeoTreeGitConflict = { fg = c.red, fmt = "bold" },
  NeoTreeGitUntracked = { fg = c.red },
  NeoTreeIndentMarker = { fg = c.comment },
  NeoTreeSymbolicLinkTarget = { fg = c.warn },
}

plugins.dashboard = {
  DashboardShortCut = { fg = c.func },
  DashboardHeader = { fg = c.keyword },
  DashboardCenter = { fg = c.fg },
  DashboardFooter = { fg = c.func },
  MiniStarterHeader = { fg = c.keyword },
  MiniStarterFooter = { fg = c.keyword },
}

plugins.indent_blankline = {
  IblIndent = { fg = faint, fmt = "nocombine" },
  IblWhitespace = { fg = faint, fmt = "nocombine" },
  IblScope = { fg = c.comment, fmt = "nocombine" },
  IndentBlanklineChar = { fg = faint, fmt = "nocombine" },
  IndentBlanklineContextChar = { fg = c.comment, fmt = "nocombine" },
  IndentBlanklineContextStart = { sp = c.comment, fmt = "underline" },
  IndentBlanklineContextSpaceChar = { fmt = "nocombine" },
}

local links = {
  MessageWindow = "Pmenu",
  PopupNotification = "Todo",
  StatusLineTerm = "StatusLine",
  StatusLineTermNC = "StatusLineNC",
  lCursor = "Cursor",
  vCursor = "Cursor",
  iCursor = "Cursor",

  diffAdded = "Added",
  diffRemoved = "Removed",
  diffChanged = "Changed",
  diffNewFile = "Added",
  diffOldFile = "Removed",
  diffIndexLine = "Comment",
  diffSubname = "Comment",
  diffComment = "Comment",

  LspDiagnosticsDefaultError = "DiagnosticError",
  LspDiagnosticsDefaultWarning = "DiagnosticWarn",
  LspDiagnosticsDefaultInformation = "DiagnosticInfo",
  LspDiagnosticsDefaultHint = "DiagnosticHint",
  LspDiagnosticsUnderlineError = "DiagnosticUnderlineError",
  LspDiagnosticsUnderlineWarning = "DiagnosticUnderlineWarn",
  LspDiagnosticsUnderlineInformation = "DiagnosticUnderlineInfo",
  LspDiagnosticsUnderlineHint = "DiagnosticUnderlineHint",
  LspDiagnosticsVirtualTextError = "DiagnosticVirtualTextError",
  LspDiagnosticsVirtualTextWarning = "DiagnosticVirtualTextWarn",
  LspDiagnosticsVirtualTextInformation = "DiagnosticVirtualTextInfo",
  LspDiagnosticsVirtualTextHint = "DiagnosticVirtualTextHint",
}

local classic = {
  CursorLine = { bg = NONE },
  CursorLineNr = { fg = P.yellow, fmt = "bold" },
  LineNr = { fg = "#8a7f45", bg = bg_main },
  FoldColumn = { fg = P.cyan, bg = "#303030" },
  Folded = { fg = P.cyan, bg = "#303030" },
  Directory = { fg = P.blue },
  Title = { fg = P.magenta, fmt = "bold" },

  Whitespace = { fg = "#282828" },

  NonText = { fg = P.blue, fmt = "bold" },
  EndOfBuffer = { fg = P.blue, fmt = "bold" },
  SpecialKey = { fg = P.cyan },

  StatusLine = { fg = P.bg, bg = P.fg, fmt = "bold" },
  StatusLineNC = { fg = P.bg, bg = P.dim },
  TabLine = { fg = P.dim, bg = "#121212" },
  TabLineFill = { fg = P.dim, bg = "#121212" },
  TabLineSel = { fg = P.bright, bg = P.surface, fmt = "bold" },

  VertSplit = { fg = "#696868", bg = bg_main },
  WinSeparator = { fg = "#696868", bg = bg_main },

  Search = { fg = P.bright, bg = "#221be3" },
  IncSearch = { fg = P.bg, bg = P.bright, fmt = "bold" },
  CurSearch = { fg = P.bg, bg = P.bright, fmt = "bold" },
  MatchParen = { fg = P.bg, bg = P.cyan },
  Visual = { bg = P.visual },

  Pmenu = { fg = P.fg, bg = bg_float },
  PmenuSel = { fg = P.bg, bg = P.mid },
  PmenuSbar = { bg = P.surface },
  PmenuThumb = { bg = P.dim },

  ErrorMsg = { fg = P.bright, bg = P.red },
  WarningMsg = { fg = P.red },
  MoreMsg = { fg = P.green, fmt = "bold" },
  Question = { fg = P.green, fmt = "bold" },
  ModeMsg = { fg = P.fg, fmt = "bold" },

  DiffAdd = { fg = P.fg, bg = "#1f2f4f" },
  DiffChange = { fg = P.fg, bg = "#3f2f4f" },
  DiffDelete = { fg = P.cyan, bg = "#1f3f3f" },
  DiffText = { fg = P.bright, bg = "#6f2f2f", fmt = "bold" },

  SpellBad = { sp = P.red, fmt = "underline" },
  SpellCap = { sp = P.blue, fmt = "underline" },
  SpellLocal = { sp = P.cyan, fmt = "underline" },
  SpellRare = { sp = P.magenta, fmt = "underline" },
}

apply(editor)
apply(syntax)
apply(lsp)
apply(diag)
apply(markdown)
apply(tex)
for _, group in pairs(plugins) do
  apply(group)
end
apply(classic)
link_all(links)
link_all(markdown_links)

local function sync_frontmatter_ns()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "markdown" then
      vim.api.nvim_win_set_hl_ns(win, frontmatter_ns)
      vim.w[win].transilvanian_alt_markdown_ns = true
    elseif vim.w[win].transilvanian_alt_markdown_ns then
      vim.api.nvim_win_set_hl_ns(win, 0)
      vim.w[win].transilvanian_alt_markdown_ns = nil
    end
  end
end

local aug = vim.api.nvim_create_augroup("TransilvanianAlt", { clear = true })
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "BufEnter", "WinEnter" }, {
  group = aug,
  callback = sync_frontmatter_ns,
})
sync_frontmatter_ns()

-- Oil sometimes resets its groups on open. Apply them again.
vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  pattern = "oil",
  callback = function()
    if vim.g.colors_name == "artifact" then
      apply(plugins.oil)
    end
  end,
})

local term = {
  P.bg, P.red, P.green, P.yellow, P.blue, P.magenta, P.cyan, P.fg,
  P.dim, P.red, P.green, P.yellow, P.blue, P.magenta, P.cyan, P.bright,
}
for i, color in ipairs(term) do
  vim.g["terminal_color_" .. (i - 1)] = color
end
