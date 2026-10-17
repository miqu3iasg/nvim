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
local transparent = vim.g.artifact_transparent == true
local underline_on = vim.g.artifact_underline ~= false
local italic_on = vim.g.artifact_italic == true

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
  surface = "#111111",
  visual = "#1f1f1f",

  bright = "#e4e4e4",
  fg = "#e4e4e4",
  md = "#b8b8b8",
  mid = "#9a9a9a",
  note = "#9e9e9e",  -- comments: readable, but always quieter than code
  rule = "#7a7a7a",  -- window separators
  dim = "#6c6c6c",
  white = "#ffffff", -- matching brackets only
  match = "#444444", -- background of matching brackets

  blue = "#7a88c8",
  cyan = "#5f9f9f",
  green = "#6aa86a", -- messages and ok/added only, never syntax
  yellow = "#c9b458",
  magenta = "#b080b0",
  pink = "#c88a8a",
  orange = "#c8935a",
  red = "#b85050",

  teal = "#5f9f9f",
  blood = "#b85050",
}

-- The single accent color (keywords, current line number, TODO badge).
-- Change only this line to try another one.
P.accent = P.yellow

-- Attention colors. These exist ONLY to be loud when you are hunting for
-- something. They must never be used for syntax, UI chrome or plugins, so
-- that they always stand out from everything else in the theme.
local alert = {
  search = "#a020f0", -- every search match
  current = P.bright, -- the match under the cursor (with black text)
  yank = "#d787af",   -- yank flash
}

local c = {
  bg = P.bg,
  fg = P.fg,
  md = P.md,
  line = P.surface,
  visual = P.visual,
  comment = P.note, -- real comments and comment-like text
  ui = P.dim,       -- quiet chrome: borders, separators, tildes, line numbers
  dim = P.dim,
  string = P.pink,
  type = P.bright, -- types: weight and brightness, not hue
  keyword = P.accent,
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
local bg_float = transparent and NONE or "#0e0e0e"

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

-- Single editor table. (It used to be split in "editor" + "classic", where
-- the second silently overrode the first.)
local editor = {
  Normal = { fg = c.fg, bg = bg_main },
  NormalNC = { fg = c.fg, bg = bg_main },
  MsgArea = { fg = c.fg, bg = bg_main },
  ColorColumn = { bg = c.line },
  Conceal = { fg = c.func },
  Cursor = { fg = P.bg, bg = P.fg },
  CursorIM = { fg = P.bg, bg = P.bright },
  CursorColumn = { bg = c.line },
  CursorLine = { bg = NONE },
  CursorLineNr = { fg = P.accent, fmt = "bold" },
  CursorLineSign = { bg = bg_main },
  CursorLineFold = { fg = c.fg, bg = bg_main },
  LineNr = { fg = c.ui, bg = bg_main },
  LineNrAbove = { fg = c.ui, bg = bg_main },
  LineNrBelow = { fg = c.ui, bg = bg_main },
  SignColumn = { fg = c.fg, bg = bg_main },
  FoldColumn = { fg = P.cyan, bg = P.visual },
  Folded = { fg = P.cyan, bg = P.visual },
  EndOfBuffer = { fg = c.ui },
  NonText = { fg = c.ui },
  SpecialKey = { fg = P.cyan },
  Whitespace = { fg = "#282828" },
  Directory = { fg = c.type, fmt = "bold" },
  Title = { fg = P.bright, fmt = "bold" },
  Underlined = { fg = c.fg, fmt = "underline" },
  Ignore = { fg = c.ui },

  Visual = { bg = c.visual },
  VisualNOS = { bg = c.visual, fmt = "underline" },
  Search = { fg = P.bright, bg = alert.search },
  CurSearch = { fg = P.bg, bg = alert.current, fmt = "bold" },
  IncSearch = { fg = P.bg, bg = alert.current, fmt = "bold" },
  Substitute = { fg = P.bg, bg = P.mid },
  MatchParen = { fg = P.white, bg = P.match, fmt = "bold" },
  QuickFixLine = { bg = c.line, fmt = "bold" },

  -- Dedicated group for yank flash. Use it in your TextYankPost autocmd:
  --   vim.hl.on_yank({ higroup = "YankHighlight" })
  YankHighlight = { fg = P.bg, bg = alert.yank },

  ErrorMsg = { fg = P.bright, bg = P.red },
  WarningMsg = { fg = P.red },
  ModeMsg = { fg = P.fg, fmt = "bold" },
  MoreMsg = { fg = P.green, fmt = "bold" },
  Question = { fg = P.green, fmt = "bold" },
  MsgSeparator = { fg = c.ui, bg = c.line },

  VertSplit = { fg = P.rule, bg = bg_main },
  WinSeparator = { fg = P.rule, bg = bg_main },
  WinBar = { fg = c.fg, bg = bg_main },
  WinBarNC = { fg = c.ui, bg = bg_main },

  -- Statusline: subtle background; active vs inactive by bg and text color.
  -- Tabline stays text-only (bg_main, not NONE, so it matches Normal).
  StatusLine = { fg = P.bright, bg = bg_main },
  StatusLineNC = { fg = P.dim, bg = bg_main },
  TabLine = { fg = P.dim, bg = bg_main },
  TabLineFill = { fg = P.dim, bg = bg_main },
  TabLineSel = { fg = P.mid, bg = bg_main },

  TitleBar = { fg = c.fg, bg = bg_main },
  TitleBarNC = { fg = c.ui, bg = bg_main },
  ToolbarButton = { fg = c.type, bg = c.line, fmt = "bold" },
  ToolbarLine = { bg = bg_main },

  SpellBad = { sp = P.red, fmt = "underline" },
  SpellCap = { sp = P.mid, fmt = "underline" },
  SpellLocal = { sp = P.cyan, fmt = "underline" },
  SpellRare = { sp = P.mid, fmt = "underline" },

  DiffAdd = { fg = P.fg, bg = "#1f2f4f" },
  DiffChange = { fg = P.fg, bg = "#3f2f4f" },
  DiffDelete = { fg = P.cyan, bg = "#1f3f3f" },
  DiffText = { fg = P.bright, bg = "#6f2f2f", fmt = "bold" },
  Added = { fg = P.green },
  Changed = { fg = P.yellow },
  Removed = { fg = P.red },
  diffFile = { fg = c.type, fmt = "bold" },
  diffLine = { fg = c.alt },

  NormalFloat = { fg = c.fg, bg = bg_float },
  FloatBorder = { fg = c.ui, bg = bg_float },
  FloatTitle = { fg = c.type, bg = bg_float, fmt = "bold" },
  FloatFooter = { fg = c.ui, bg = bg_float },
  Pmenu = { fg = P.fg, bg = bg_float },
  PmenuSel = { fg = P.bright, bg = P.visual },
  PmenuKind = { fg = c.ui, bg = bg_float },
  PmenuKindSel = { fg = P.bright, bg = P.visual },
  PmenuExtra = { fg = c.ui, bg = bg_float },
  PmenuExtraSel = { fg = P.bright, bg = P.visual },
  PmenuMatch = { fg = P.accent, bg = bg_float, fmt = "bold" },
  PmenuMatchSel = { fg = P.accent, bg = P.visual, fmt = "bold" },
  PmenuSbar = { bg = P.surface },
  PmenuThumb = { bg = P.dim },
  WildMenu = { fg = P.bright, bg = P.visual, fmt = "bold" },

  Terminal = { fg = c.fg, bg = bg_main },
  TermCursor = { fg = P.bg, bg = P.fg },
  debugPC = { bg = c.line },
  debugBreakpoint = { fg = c.red },
}

local syntax = {
  Comment = { fg = P.note },
  Constant = { fg = P.pink },
  String = { fg = P.pink },
  Character = { fg = P.pink },
  Number = { fg = P.pink },
  Boolean = { fg = P.pink },
  Float = { fg = P.pink },
  Identifier = { fg = P.fg },
  Function = { fg = P.fg },
  Statement = { fg = c.keyword, fmt = "bold" },
  Conditional = { fg = c.keyword, fmt = "bold" },
  Repeat = { fg = c.keyword, fmt = "bold" },
  Label = { fg = c.keyword, fmt = "bold" },
  Operator = { fg = P.fg },
  Keyword = { fg = c.keyword, fmt = "bold" },
  Exception = { fg = c.keyword, fmt = "bold" },
  PreProc = { fg = P.orange },
  Include = { fg = P.orange },
  Define = { fg = P.orange },
  Macro = { fg = P.orange },
  PreCondit = { fg = P.orange },
  Type = { fg = c.type, fmt = "bold" },
  StorageClass = { fg = c.type, fmt = "bold" },
  Structure = { fg = c.type, fmt = "bold" },
  Typedef = { fg = c.type, fmt = "bold" },
  Special = { fg = P.orange },
  SpecialChar = { fg = P.orange },
  Tag = { fg = P.orange },
  Delimiter = { fg = P.fg },
  SpecialComment = { fg = P.note },
  Debug = { fg = P.orange },
  Error = { fg = P.bright, bg = P.red },
  Todo = { fg = P.bg, bg = P.accent, fmt = "bold" },

  -- Tags inside comments (TODO, NOTE, WARN...): brighter and bold, but no
  -- new color. Handy for study notes.
  ["@comment.todo"] = { fg = P.bright, fmt = "bold" },
  ["@comment.note"] = { fg = P.bright, fmt = "bold" },
  ["@comment.warning"] = { fg = P.bright, fmt = "bold" },
  ["@comment.error"] = { fg = P.red, fmt = "bold" },
}

local lsp = {
  -- Hints are not your text: keep them dimmer than comments.
  LspInlayHint = { fg = P.dim, bg = c.line },
  LspReferenceText = { bg = c.visual },
  LspReferenceRead = { bg = c.visual },
  LspReferenceWrite = { bg = c.visual, fmt = "underline" },
  LspCodeLens = { fg = P.dim },
  LspCodeLensSeparator = { fg = P.dim },
  LspSignatureActiveParameter = { fg = c.type, fmt = "bold,underline" },
}

local diag = {
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.warn },
  DiagnosticInfo = { fg = P.cyan },
  DiagnosticHint = { fg = P.mid },
  DiagnosticOk = { fg = P.green },
  DiagnosticUnnecessary = { fg = c.ui },
  DiagnosticDeprecated = { fg = c.ui, fmt = "strikethrough" },

  DiagnosticVirtualTextError = { fg = P.red },
  DiagnosticVirtualTextWarn = { fg = P.orange },
  DiagnosticVirtualTextInfo = { fg = P.cyan },
  DiagnosticVirtualTextHint = { fg = P.mid },
  DiagnosticVirtualTextOk = { fg = P.green },

  DiagnosticUnderlineError = { sp = P.red, fmt = "underline" },
  DiagnosticUnderlineWarn = { sp = P.orange, fmt = "underline" },
  DiagnosticUnderlineInfo = { sp = P.cyan, fmt = "underline" },
  DiagnosticUnderlineHint = { sp = P.mid, fmt = "underline" },
  DiagnosticUnderlineOk = { sp = P.green, fmt = "underline" },

  DiagnosticFloatingError = { fg = c.red },
  DiagnosticFloatingWarn = { fg = c.warn },
  DiagnosticFloatingInfo = { fg = P.cyan },
  DiagnosticFloatingHint = { fg = P.mid },
  DiagnosticSignError = { fg = c.red },
  DiagnosticSignWarn = { fg = c.warn },
  DiagnosticSignInfo = { fg = P.cyan },
  DiagnosticSignHint = { fg = P.mid },
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
  ["@markup.strikethrough.markdown_inline"] = { fg = c.ui, fmt = "strikethrough" },

  ["@markup.raw.markdown_inline"] = { fg = P.bright, bg = code_bg },
  -- Math (inline and block) uses the theme's cyan.
  ["@markup.math.markdown_inline"] = { fg = c.alt },
  ["@markup.math.markdown"] = { fg = c.alt },
  ["@markup.math.latex"] = { fg = c.alt },
  ["@punctuation.special.markdown_inline"] = { fg = c.type },

  ["@markup.link.markdown_inline"] = { fg = c.ui },
  ["@markup.link.label.markdown_inline"] = { fg = c.type, bg = c.line, fmt = "underline" },
  ["@markup.link.url.markdown_inline"] = { fg = c.alt, fmt = "underline" },

  ["@string.escape.markdown_inline"] = { fg = c.alt },
  ["@conceal.markdown_inline"] = { fg = c.ui },

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
local frontmatter_ns = vim.api.nvim_create_namespace("artifact_markdown")
local frontmatter = {
  -- Plain markdown text (no treesitter capture) uses the md color.
  -- Headings, code, inline math and bold set their own fg, so they win.
  Normal = { fg = c.md, bg = bg_main },
  NormalNC = { fg = c.md, bg = bg_main },

  ["@property.yaml"] = { fg = c.alt },
  ["@string.yaml"] = { fg = c.fg },
  ["@number.yaml"] = { fg = c.number },
  ["@number.float.yaml"] = { fg = c.number },
  ["@boolean.yaml"] = { fg = c.number },
  ["@constant.builtin.yaml"] = { fg = P.mid },
  ["@label.yaml"] = { fg = c.alt },
  ["@type.yaml"] = { fg = c.alt },
  ["@punctuation.delimiter.yaml"] = { fg = c.ui },
  ["@punctuation.bracket.yaml"] = { fg = c.ui },
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
  texTodo = { fg = P.bg, bg = P.accent, fmt = "bold" },
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
  OilDir = { fg = P.bright, fmt = "bold" },
  OilDirIcon = { fg = P.bright },
  OilFile = { fg = c.fg },
  OilLink = { fg = P.mid },
  OilLinkTarget = { fg = c.ui },
  OilOrphanLink = { fg = c.red },
  OilOrphanLinkTarget = { fg = c.red },
  OilHidden = { fg = c.dim },
  OilDirHidden = { fg = P.dim, fmt = "bold" },
  OilFileHidden = { fg = P.dim },
  OilLinkHidden = { fg = P.dim },
  OilOrphanLinkHidden = { fg = c.red },
  OilExecutable = { fg = P.fg, fmt = "bold" },
  OilSocket = { fg = P.mid },

  OilCreate = { fg = c.type, fmt = "bold" },
  OilCopy = { fg = c.type, fmt = "bold" },
  OilMove = { fg = c.warn },
  OilChange = { fg = c.warn },
  OilDelete = { fg = c.red },
  OilPurge = { fg = c.red, fmt = "bold" },
  OilRestore = { fg = c.type, fmt = "bold" },
  OilTrash = { fg = c.ui },
  OilTrashSourcePath = { fg = c.ui },

  OilTypeDir = { fg = P.bright, fmt = "bold" },
  OilTypeFile = { fg = c.ui },
  OilTypeLink = { fg = P.mid },
  OilTypeFifo = { fg = c.ui },
  OilTypeSocket = { fg = c.ui },
  OilTypeUnknown = { fg = c.ui },
  OilPermissionNone = { fg = c.ui },
  OilPermissionRead = { fg = c.warn },
  OilPermissionWrite = { fg = c.red },
  OilPermissionExecute = { fg = c.type },
}

plugins.special = {
  LazyNormal = { bg = bg_float },
  MasonNormal = { bg = bg_float },
}

plugins.blink = {
  BlinkCmpMenu = { link = "Pmenu" },
  BlinkCmpMenuBorder = { link = "FloatBorder" },
  BlinkCmpMenuSelection = { link = "PmenuSel" },
  BlinkCmpScrollBarThumb = { link = "PmenuThumb" },
  BlinkCmpScrollBarGutter = { link = "PmenuSbar" },
  BlinkCmpLabel = { link = "Pmenu" },
  BlinkCmpLabelMatch = { link = "PmenuMatch" },
  BlinkCmpLabelDeprecated = { fg = c.ui, fmt = "strikethrough" },
  BlinkCmpLabelDetail = { fg = c.ui },
  BlinkCmpLabelDescription = { fg = c.ui },
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
    Folder = P.mid,
    Function = c.func,
    Interface = c.type,
    Key = c.keyword,
    Keyword = c.keyword,
    Method = c.func,
    Module = P.mid,
    Namespace = P.mid,
    Null = c.type,
    Number = c.number,
    Object = c.type,
    Operator = c.operator,
    Package = P.mid,
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
  GitSignsCurrentLineBlame = { fg = c.ui },
}

plugins.dashboard = {
  DashboardShortCut = { fg = c.func },
  DashboardHeader = { fg = c.keyword },
  DashboardCenter = { fg = c.fg },
  DashboardFooter = { fg = c.func },
  MiniStarterHeader = { fg = c.keyword },
  MiniStarterFooter = { fg = c.keyword },
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

apply(editor)
apply(syntax)
apply(lsp)
apply(diag)
apply(markdown)
apply(tex)
for _, group in pairs(plugins) do
  apply(group)
end
link_all(links)
link_all(markdown_links)

local function sync_frontmatter_ns()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "markdown" then
      vim.api.nvim_win_set_hl_ns(win, frontmatter_ns)
      vim.w[win].artifact_markdown_ns = true
    elseif vim.w[win].artifact_markdown_ns then
      vim.api.nvim_win_set_hl_ns(win, 0)
      vim.w[win].artifact_markdown_ns = nil
    end
  end
end

local aug = vim.api.nvim_create_augroup("ArtifactTheme", { clear = true })
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
