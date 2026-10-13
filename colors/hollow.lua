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

vim.cmd('runtime colors/vim.lua')
vim.g.colors_name = 'hollow'

local set_hl      = vim.api.nvim_set_hl

local _           = false

local fg0         = '#dadada'
local fg1         = '#c6c6c6'
local dim         = '#707070'
local cmt         = '#626262'

local err         = '#b86a6a'
local warn        = '#a8884a'
local ok          = '#3f7a3f'

local function attrs(str)
  local t = {}
  if str then
    for a in str:gmatch('[^,]+') do
      if a ~= 'NONE' then t[a] = true end
    end
  end
  return t
end

local function apply(defs)
  for _, d in ipairs(defs) do
    local name, fg, bg, sp, gui, cfg, cbg, cterm = unpack(d, 1, 8)
    local o = attrs(gui)
    if fg then o.fg = fg end
    if bg then o.bg = bg end
    if sp then o.sp = sp end
    if cfg then o.ctermfg = cfg end
    if cbg then o.ctermbg = cbg end
    o.cterm = attrs(cterm)
    set_hl(0, name, o)
  end
end

-- Links (hi! link)
local links = {
  Boolean = 'Constant',
  Character = 'Constant',
  Conditional = 'Statement',
  Debug = 'Special',
  Define = 'PreProc',
  Delimiter = 'Special',
  Exception = 'Statement',
  Float = 'Constant',
  Include = 'PreProc',
  Keyword = 'Statement',
  Label = 'Statement',
  Macro = 'PreProc',
  MessageWindow = 'Pmenu',
  Number = 'Constant',
  PopupNotification = 'Todo',
  PreCondit = 'PreProc',
  Repeat = 'Statement',
  SpecialChar = 'Special',
  SpecialComment = 'Special',
  StatusLineTerm = 'StatusLine',
  StatusLineTermNC = 'StatusLineNC',
  StorageClass = 'Type',
  -- String = 'Constant',
  Structure = 'Type',
  Tag = 'Special',
  Terminal = 'Normal',
  Typedef = 'Type',
  debugBreakpoint = 'ModeMsg',
  debugPC = 'CursorLine',
  lCursor = 'Cursor',
  TermCursor = 'Cursor',

  diffAdded = 'Added',
  diffRemoved = 'Removed',
  diffChanged = 'Changed',
  diffNewFile = 'Added',
  diffOldFile = 'Removed',
  diffIndexLine = 'Comment',
  diffSubname = 'Comment',
  diffComment = 'Comment',
  ['@diff.plus'] = 'Added',
  ['@diff.minus'] = 'Removed',
  ['@diff.delta'] = 'Changed',

  GitSignsAdd = 'Added',
  GitSignsChange = 'Changed',
  GitSignsDelete = 'Removed',
  GitSignsAddNr = 'Added',
  GitSignsChangeNr = 'Changed',
  GitSignsDeleteNr = 'Removed',
  GitSignsAddInline = 'DiffAdd',
  GitSignsChangeInline = 'DiffChange',
  GitSignsDeleteInline = 'DiffDelete',
  GitSignsAddPreview = 'DiffAdd',
  GitSignsDeletePreview = 'DiffDelete',

  BlinkCmpMenu = 'Pmenu',
  BlinkCmpMenuBorder = 'FloatBorder',
  BlinkCmpMenuSelection = 'PmenuSel',
  BlinkCmpScrollBarThumb = 'PmenuThumb',
  BlinkCmpScrollBarGutter = 'PmenuSbar',
  BlinkCmpLabel = 'Pmenu',
  BlinkCmpLabelMatch = 'PmenuMatch',
  BlinkCmpKind = 'PmenuKind',
  BlinkCmpSource = 'PmenuExtra',
  BlinkCmpDoc = 'NormalFloat',
  BlinkCmpDocBorder = 'FloatBorder',
  BlinkCmpDocSeparator = 'FloatBorder',
  BlinkCmpSignatureHelp = 'NormalFloat',
  BlinkCmpSignatureHelpBorder = 'FloatBorder',

  CmpItemAbbrMatch = 'PmenuMatch',
  CmpItemAbbrMatchFuzzy = 'PmenuMatch',
  CmpItemKind = 'PmenuKind',
  CmpItemMenu = 'PmenuExtra',
}

local function terminal_colors(list)
  for i, c in ipairs(list) do
    vim.g['terminal_color_' .. (i - 1)] = c
  end
end

local dark = {
  { 'Normal',        fg0,       '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'ColorColumn',   _,         '#1c1c1c', _,         'NONE',         _,   234, 'NONE' },
  { 'Conceal',       _,         _,         _,         'NONE',         _,   _,   'NONE' },
  { 'Constant',      fg0,       _,         _,         'NONE',         253, _,   'NONE' },
  { 'CurSearch',     '#ff5fff', '#000000', _,         'reverse',      207, 16,  'reverse' },
  { 'CursorColumn',  _,         '#303030', _,         'NONE',         _,   236, 'NONE' },
  { 'CursorIM',      '#000000', '#221cd6', _,         'NONE',         16,  20,  'NONE' },
  { 'CursorLine',    _,         '#121212', _,         'NONE',         _,   236, 'NONE' },
  { 'CursorLineNr',  fg0,       '#121212', _,         'bold',         253, 236, 'bold' },
  -- Diff backgrounds: very dark tints, close to the black background
  { 'DiffAdd',       _,         '#070f07', _,         'NONE',         _,   233, 'NONE' },
  { 'DiffChange',    _,         '#070b11', _,         'NONE',         _,   233, 'NONE' },
  { 'DiffDelete',    '#7a4a4a', '#100707', _,         'NONE',         95,  233, 'NONE' },
  { 'DiffText',      _,         '#120c1a', _,         'NONE',         _,   234, 'NONE' },

  -- Diff signs / text (gitsigns, `diff` filetype, treesitter): muted tones
  { 'Added',         '#335533', _,         _,         'NONE',         22,  _,   'NONE' },
  { 'Changed',       '#334a60', _,         _,         'NONE',         60,  _,   'NONE' },
  { 'Removed',       '#7a4a4a', _,         _,         'NONE',         95,  _,   'NONE' },
  { 'diffFile',      fg0,       _,         _,         'bold',         253, _,   'bold' },
  { 'diffLine',      '#4a3560', _,         _,         'NONE',         60,  _,   'NONE' },

  { 'Directory',     fg0,       _,         _,         'NONE',         253, _,   'NONE' },
  { 'EndOfBuffer',   dim,       _,         _,         'NONE',         242, _,   'NONE' },
  { 'Error',         '#ff005f', '#000000', _,         'bold,reverse', 197, 16,  'bold,reverse' },
  { 'ErrorMsg',      '#ff005f', '#000000', _,         'bold',         197, 16,  'bold' },
  { 'FoldColumn',    dim,       '#000000', _,         'NONE',         242, 16,  'NONE' },
  { 'Folded',        dim,       '#000000', _,         'NONE',         242, 16,  'NONE' },
  { 'Identifier',    fg0,       _,         _,         'NONE',         253, _,   'NONE' },
  { 'Ignore',        fg0,       _,         _,         'NONE',         253, _,   'NONE' },
  { 'IncSearch',     '#d75fd7', '#000000', _,         'reverse',      170, 16,  'reverse' },
  { 'LineNr',        '#585858', _,         _,         'NONE',         240, _,   'NONE' },
  { 'MatchParen',    '#ffffff', '#221cd6', _,         'bold',         231, 62,  'bold' },
  { 'ModeMsg',       fg0,       '#000000', _,         'bold',         253, 16,  'bold' },
  { 'MoreMsg',       fg0,       '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'MsgArea',       fg0,       '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'MsgSeparator',  '#444444', '#000000', _,         'NONE',         238, 16,  'NONE' },
  { 'NonText',       dim,       _,         _,         'NONE',         242, _,   'NONE' },
  { 'PreProc',       fg1,       _,         _,         'NONE',         251, _,   'NONE' },
  { 'Question',      fg0,       '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'QuickFixLine',  '#ff5fff', '#000000', _,         'reverse',      207, 16,  'reverse' },
  { 'Search',        fg0,       '#221cd6', _,         'NONE',         253, 20,  'NONE' },
  { 'SignColumn',    fg0,       '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'Special',       fg0,       _,         _,         'NONE',         253, _,   'NONE' },
  { 'SpecialKey',    dim,       _,         _,         'bold',         242, _,   'bold' },
  { 'SpellBad',      '#d7005f', _,         '#d7005f', 'undercurl',    161, _,   'underline' },
  { 'SpellCap',      '#0087d7', _,         '#0087d7', 'undercurl',    32,  _,   'underline' },
  { 'SpellLocal',    '#d787d7', _,         '#d787d7', 'undercurl',    176, _,   'underline' },
  { 'SpellRare',     '#00afaf', _,         '#00afaf', 'undercurl',    37,  _,   'underline' },
  { 'StatusLine',    '#a8a8a8', '#121212', _,         'NONE',         248, 234, 'NONE' },
  { 'StatusLineNC',  '#5f5f5f', '#050505', _,         'NONE',         59,  233, 'NONE' },
  { 'TabLine',       dim,       '#000000', _,         'NONE',         242, 16,  'NONE' },
  { 'TabLineFill',   fg0,       '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'TabLineSel',    fg0,       '#000000', _,         'bold',         253, 16,  'bold' },
  { 'TitleBar',      fg0,       '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'TitleBarNC',    dim,       '#000000', _,         'NONE',         242, 16,  'NONE' },
  { 'Todo',          '#00ffaf', _,         _,         'bold,reverse', 49,  _,   'bold,reverse' },
  { 'ToolbarButton', fg0,       '#000000', _,         'bold',         253, 16,  'bold' },
  { 'ToolbarLine',   _,         '#000000', _,         'NONE',         _,   16,  'NONE' },
  { 'Underlined',    fg0,       _,         _,         'underline',    253, _,   'underline' },
  { 'VertSplit',     dim,       '#000000', _,         'NONE',         242, 16,  'NONE' },
  { 'Visual',        _,         '#444444', _,         'NONE',         _,   238, 'NONE' },
  { 'VisualNOS',     _,         '#303030', _,         'NONE',         _,   236, 'NONE' },
  { 'WarningMsg',    fg0,       '#000000', _,         'NONE',         253, 16,  'NONE' },
}

local popups = {
  { 'NormalFloat',   fg0,       '#000000', _, 'NONE', 253, 16,  'NONE' },
  { 'FloatBorder',   '#444444', '#000000', _, 'NONE', 238, 16,  'NONE' },
  { 'FloatTitle',    fg0,       '#000000', _, 'NONE', 253, 16,  'NONE' },
  { 'FloatFooter',   dim,       '#000000', _, 'NONE', 242, 16,  'NONE' },
  { 'Pmenu',         fg0,       '#000000', _, 'NONE', 253, 16,  'NONE' },
  { 'PmenuExtra',    dim,       '#000000', _, 'NONE', 242, 16,  'NONE' },
  { 'PmenuExtraSel', fg0,       '#303030', _, 'NONE', 253, 236, 'NONE' },
  { 'PmenuKind',     dim,       '#000000', _, 'NONE', 242, 16,  'NONE' },
  { 'PmenuKindSel',  fg0,       '#303030', _, 'NONE', 253, 236, 'NONE' },
  { 'PmenuMatch',    '#ffffff', '#000000', _, 'bold', 231, 16,  'bold' },
  { 'PmenuMatchSel', '#ffffff', '#303030', _, 'bold', 231, 236, 'bold' },
  { 'PmenuSbar',     _,         '#000000', _, 'NONE', _,   16,  'NONE' },
  { 'PmenuSel',      fg0,       '#303030', _, 'NONE', 253, 236, 'NONE' },
  { 'PmenuThumb',    _,         '#444444', _, 'NONE', _,   238, 'NONE' },
  { 'WildMenu',      fg0,       '#303030', _, 'NONE', 253, 236, 'NONE' },
}

-- Modern groups
local modern = {
  -- Syntax hierarchy
  { 'Comment',                      cmt,       _,         _,    'NONE',      241, _,   'NONE' },
  { 'Statement',                    fg1,       _,         _,    'NONE',      251, _,   'NONE' },
  { 'Type',                         fg1,       _,         _,    'NONE',      251, _,   'NONE' },
  { 'Function',                     fg0,       _,         _,    'bold',      253, _,   'bold' },
  { 'Delimiter',                    fg0,       _,         _,    'NONE',      253, _,   'NONE' },
  { '@punctuation',                 fg0,       _,         _,    'NONE',      253, _,   'NONE' },
  { 'Operator',                     fg0,       _,         _,    'NONE',      253, _,   'NONE' },
  { '@operator',                    fg0,       _,         _,    'NONE',      253, _,   'NONE' },
  { '@variable.parameter',          fg0,       _,         _,    'NONE',      253, _,   'NONE' },
  { '@variable.builtin',            fg1,       _,         _,    'italic',    251, _,   'italic' },
  { '@constant.builtin',            fg1,       _,         _,    'NONE',      251, _,   'NONE' },
  { '@tag.attribute',               fg1,       _,         _,    'NONE',      251, _,   'NONE' },

  -- Diagnostics
  { 'DiagnosticError',              err,       _,         _,    'NONE',      131, _,   'NONE' },
  { 'DiagnosticWarn',               warn,      _,         _,    'NONE',      137, _,   'NONE' },
  { 'DiagnosticInfo',               fg1,       _,         _,    'NONE',      251, _,   'NONE' },
  { 'DiagnosticHint',               cmt,       _,         _,    'NONE',      241, _,   'NONE' },
  { 'DiagnosticOk',                 ok,        _,         _,    'NONE',      65,  _,   'NONE' },
  { 'DiagnosticUnderlineError',     _,         _,         err,  'undercurl', _,   _,   'underline' },
  { 'DiagnosticUnderlineWarn',      _,         _,         warn, 'undercurl', _,   _,   'underline' },
  { 'DiagnosticUnderlineInfo',      _,         _,         fg1,  'undercurl', _,   _,   'underline' },
  { 'DiagnosticUnderlineHint',      _,         _,         cmt,  'undercurl', _,   _,   'underline' },
  { 'DiagnosticUnnecessary',        cmt,       _,         _,    'NONE',      241, _,   'NONE' },

  -- LSP
  { 'LspInlayHint',                 cmt,       '#0a0a0a', _,    'italic',    241, 233, 'italic' },
  { 'LspReferenceText',             _,         '#1c1c1c', _,    'NONE',      _,   234, 'NONE' },
  { 'LspReferenceRead',             _,         '#1c1c1c', _,    'NONE',      _,   234, 'NONE' },
  { 'LspReferenceWrite',            _,         '#1c1c1c', _,    'underline', _,   234, 'underline' },

  -- Markup / markdown
  { 'Title',                        fg0,       _,         _,    'bold',      253, _,   'bold' },
  { '@markup.heading',              fg0,       _,         _,    'bold',      253, _,   'bold' },
  { '@markup.strong',               _,         _,         _,    'bold',      _,   _,   'bold' },
  { '@markup.italic',               _,         _,         _,    'italic',    _,   _,   'italic' },
  { '@markup.link',                 fg1,       _,         _,    'underline', 251, _,   'underline' },
  { '@markup.raw',                  fg1,       _,         _,    'NONE',      251, _,   'NONE' },

  -- Regex
  { '@string.regexp',               '#8a94a0', _,         _,    'NONE',      245, _,   'NONE' },
  { '@character.special',           fg0,       _,         _,    'bold',      253, _,   'bold' },
  { '@constant.character.escape',   fg0,       _,         _,    'NONE',      253, _,   'NONE' },
  { '@operator.regex',              warn,      _,         _,    'bold',      137, _,   'bold' },
  { '@keyword.operator.regex',      warn,      _,         _,    'bold',      137, _,   'bold' },
  { '@punctuation.bracket.regex',   dim,       _,         _,    'NONE',      242, _,   'NONE' },
  { '@punctuation.delimiter.regex', '#946060', _,         _,    'NONE',      95,  _,   'NONE' },
  { '@property.regex',              '#5f7f5f', _,         _,    'italic',    65,  _,   'italic' },
  { '@variable.builtin.regex',      fg1,       _,         _,    'NONE',      251, _,   'NONE' },
}

-- Markdown only

-- Exact xterm-256 values, so cterm matches GUI
local md = {
  heading    = '#ffffff',
  heading_bg = '#121212',
  italic     = '#a8a8a8',
  strike     = '#6c6c6c',
  marker     = '#585858',
  code       = '#87afd7',
  block_bg   = '#121212',
  link_url   = '#5f87af',
  block      = '#b2b2b2',
  green      = '#cecece',
  accent     = '#af87af',
}

local markdown = {
  -- Headings
  { '@markup.heading.markdown',              md.heading,  _, _, 'bold',          231, _, 'bold' },
  { '@markup.heading.1.markdown',            md.heading,  _, _, 'bold',          231, _, 'bold' },
  { '@markup.heading.2.markdown',            md.heading,  _, _, 'bold',          231, _, 'bold' },
  { '@markup.heading.3.markdown',            md.heading,  _, _, 'bold',          231, _, 'bold' },
  { '@markup.heading.4.markdown',            md.heading,  _, _, 'bold',          231, _, 'bold' },
  { '@markup.heading.5.markdown',            md.heading,  _, _, 'bold',          231, _, 'bold' },
  { '@markup.heading.6.markdown',            md.heading,  _, _, 'bold',          231, _, 'bold' },
  { '@markup.heading.1.marker.markdown',     md.heading,  _, _, 'NONE',          231, _, 'NONE' },
  { '@markup.heading.2.marker.markdown',     md.heading,  _, _, 'NONE',          231, _, 'NONE' },
  { '@markup.heading.3.marker.markdown',     md.heading,  _, _, 'NONE',          231, _, 'NONE' },
  { '@markup.heading.4.marker.markdown',     md.heading,  _, _, 'NONE',          231, _, 'NONE' },
  { '@markup.heading.5.marker.markdown',     md.heading,  _, _, 'NONE',          231, _, 'NONE' },
  { '@markup.heading.6.marker.markdown',     md.heading,  _, _, 'NONE',          231, _, 'NONE' },
  { '@markup.heading.marker.markdown',       md.heading,  _, _, 'NONE',          231, _, 'NONE' },

  -- Structural punctuation
  { '@punctuation.special.markdown',         fg0,         _, _, 'NONE',          253, _, 'NONE' },
  { '@punctuation.delimiter.markdown',       fg0,         _, _, 'NONE',          253, _, 'NONE' },

  -- Frontmatter fences (---)
  { '@keyword.directive.markdown',           md.accent,   _, _, 'NONE',          139, _, 'NONE' },

  -- Lists and task items
  { '@markup.list.markdown',                 md.accent,   _, _, 'bold',          139, _, 'bold' },
  { '@markup.list.checked.markdown',         md.accent,   _, _, 'bold',          139, _, 'bold' },
  { '@markup.list.unchecked.markdown',       md.accent,   _, _, 'bold',          139, _, 'bold' },

  -- Blockquote
  { '@markup.quote.markdown',                md.italic,   _, _, 'italic',        248, _, 'italic' },

  -- Code blocks
  { '@markup.raw.block.markdown',            md.block,    _, _, 'NONE',          249, _, 'NONE' },
  { '@markup.raw.delimiter.markdown',        md.accent,   _, _, 'NONE',          139, _, 'NONE' },
  { '@label.markdown',                       md.accent,   _, _, 'italic',        139, _, 'italic' },

  -- Inline emphasis
  { '@markup.strong.markdown_inline',        md.heading,  _, _, 'bold',          231, _, 'bold' },
  { '@markup.italic.markdown_inline',        md.italic,   _, _, 'italic',        248, _, 'italic' },
  { '@markup.strikethrough.markdown_inline', md.strike,   _, _, 'strikethrough', 242, _, 'NONE' },

  -- Inline code and math
  { '@markup.raw.markdown_inline',           md.code,     _, _, 'NONE',          110, _, 'NONE' },
  { '@markup.math.markdown_inline',          md.code,     _, _, 'NONE',          110, _, 'NONE' },
  { '@markup.math.markdown',                 md.code,     _, _, 'NONE',          110, _, 'NONE' },
  { '@markup.math.latex',                    md.code,     _, _, 'NONE',          110, _, 'NONE' }, -- injected latex inside math (also affects .tex)
  { '@punctuation.special.markdown_inline',  md.code,     _, _, 'NONE',          110, _, 'NONE' }, -- $ delimiters

  -- Inline links
  { '@markup.link.markdown_inline',          md.marker,   _, _, 'NONE',          240, _, 'NONE' },
  { '@markup.link.label.markdown_inline',    md.code,     _, _, 'underline',     110, _, 'underline' },
  { '@markup.link.url.markdown_inline',      md.link_url, _, _, 'underline',     67,  _, 'underline' },

  -- Inline escapes and conceal
  { '@string.escape.markdown_inline',        md.accent,   _, _, 'NONE',          139, _, 'NONE' },
  { '@conceal.markdown_inline',              md.marker,   _, _, 'NONE',          240, _, 'NONE' },
}

-- Markdown-specific links
local markdown_links = {
  -- Legacy :syntax groups (regex highlighter)
  markdownH1 = '@markup.heading.1.markdown',
  markdownH2 = '@markup.heading.2.markdown',
  markdownH3 = '@markup.heading.3.markdown',
  markdownH4 = '@markup.heading.4.markdown',
  markdownH5 = '@markup.heading.5.markdown',
  markdownH6 = '@markup.heading.6.markdown',
  markdownHeadingDelimiter = '@markup.heading.marker.markdown',
  markdownHeadingRule = '@markup.heading.marker.markdown',
  markdownCode = '@markup.raw.markdown_inline',
  markdownCodeBlock = '@markup.raw.block.markdown',
  markdownCodeDelimiter = '@markup.raw.delimiter.markdown',
  markdownBlockquote = '@markup.quote.markdown',
  markdownListMarker = '@markup.list.markdown',
  markdownOrderedListMarker = '@markup.list.markdown',
  markdownRule = '@punctuation.special.markdown',
  markdownBold = '@markup.strong.markdown_inline',
  markdownItalic = '@markup.italic.markdown_inline',
  markdownBoldItalic = '@markup.strong.markdown_inline',
  markdownStrike = '@markup.strikethrough.markdown_inline',
  markdownLinkText = '@markup.link.label.markdown_inline',
  markdownUrl = '@markup.link.url.markdown_inline',
  markdownLinkDelimiter = '@markup.link.markdown_inline',
  markdownIdDelimiter = '@markup.link.markdown_inline',
  markdownAutomaticLink = '@markup.link.url.markdown_inline',
  markdownEscape = '@string.escape.markdown_inline',
}

-- Frontmatter (YAML injected into markdown)
local frontmatter_ns = vim.api.nvim_create_namespace('hollow_markdown')

local frontmatter = {
  ['@property.yaml']              = { fg = md.accent, ctermfg = 110 }, -- keys
  ['@string.yaml']                = { fg = md.green, ctermfg = 175 },  -- string values
  ['@number.yaml']                = { fg = md.accent, ctermfg = 139 },
  ['@number.float.yaml']          = { fg = md.accent, ctermfg = 139 },
  ['@boolean.yaml']               = { fg = md.accent, ctermfg = 139 },
  ['@constant.builtin.yaml']      = { fg = md.accent, ctermfg = 139 }, -- null
  ['@label.yaml']                 = { fg = md.accent, ctermfg = 139 }, -- anchors / aliases
  ['@type.yaml']                  = { fg = md.accent, ctermfg = 139 }, -- tags
  ['@punctuation.delimiter.yaml'] = { fg = md.marker, ctermfg = 240 }, -- : - ,
  ['@punctuation.bracket.yaml']   = { fg = md.marker, ctermfg = 240 }, -- [ ] { }
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

vim.o.background = 'dark'

terminal_colors({
  '#000000', '#913939', '#00af5f', '#221cd6', '#0087d7', '#d787d7', '#00afaf', '#dadada',
  '#707070', '#9c3b3b', '#00d75f', '#221cd6', '#5fafff', '#ff87ff', '#00d7d7', '#ffffff',
})
apply(dark)
apply(popups)
apply(modern)
apply(markdown)

-- Attach the frontmatter namespace only to windows showing markdown buffers
local function sync_frontmatter_ns()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'markdown' then
      vim.api.nvim_win_set_hl_ns(win, frontmatter_ns)
      vim.w[win].hollow_markdown_ns = true
    elseif vim.w[win].hollow_markdown_ns then
      vim.api.nvim_win_set_hl_ns(win, 0)
      vim.w[win].hollow_markdown_ns = nil
    end
  end
end

vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter', 'BufEnter', 'WinEnter' }, {
  group = vim.api.nvim_create_augroup('HollowMarkdown', { clear = true }),
  callback = sync_frontmatter_ns,
})
sync_frontmatter_ns()

set_hl(0, 'Cursor', { fg = '#000000', bg = fg0, ctermfg = 16, ctermbg = 253 })
