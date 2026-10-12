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

local set_hl = vim.api.nvim_set_hl

local _ = false

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
  Function = 'Identifier',
  Include = 'PreProc',
  Keyword = 'Statement',
  Label = 'Statement',
  Macro = 'PreProc',
  MessageWindow = 'Pmenu',
  Number = 'Constant',
  Operator = 'Statement',
  PopupNotification = 'Todo',
  PreCondit = 'PreProc',
  Repeat = 'Statement',
  SpecialChar = 'Special',
  SpecialComment = 'Special',
  StatusLineTerm = 'StatusLine',
  StatusLineTermNC = 'StatusLineNC',
  StorageClass = 'Type',
  String = 'Constant',
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
  { 'Normal',        '#dadada', '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'ColorColumn',   _,         '#1c1c1c', _,         'NONE',         _,   234, 'NONE' },
  { 'Comment',       '#525252', _,         _,         'NONE',         59,  _,   'NONE' },
  { 'Conceal',       _,         _,         _,         'NONE',         _,   _,   'NONE' },
  { 'Constant',      '#dadada', _,         _,         'NONE',         253, _,   'NONE' },
  { 'CurSearch',     '#ff5fff', '#000000', _,         'reverse',      207, 16,  'reverse' },
  { 'CursorColumn',  _,         '#303030', _,         'NONE',         _,   236, 'NONE' },
  { 'CursorIM',      '#000000', '#221cd6', _,         'NONE',         16,  20,  'NONE' },
  { 'CursorLine',    _,         '#121212', _,         'NONE',         _,   236, 'NONE' },
  { 'CursorLineNr',  '#dadada', '#121212', _,         'NONE',         253, 236, 'NONE' },
  -- Diff backgrounds: very dark tints, close to the black background
  { 'DiffAdd',       _,         '#0b1a0b', _,         'NONE',         _,   22,  'NONE' },
  { 'DiffChange',    _,         '#0b121c', _,         'NONE',         _,   17,  'NONE' },
  { 'DiffDelete',    '#b86a6a', '#1a0b0b', _,         'NONE',         131, 52,  'NONE' },
  { 'DiffText',      _,         '#1e1230', _,         'NONE',         _,   53,  'NONE' },

  -- Diff signs / text (gitsigns, `diff` filetype, treesitter): muted tones
  { 'Added',         '#3f7a3f', _,         _,         'NONE',         65,  _,   'NONE' },
  { 'Changed',       '#3f6280', _,         _,         'NONE',         60,  _,   'NONE' },
  { 'Removed',       '#b86a6a', _,         _,         'NONE',         131, _,   'NONE' },
  { 'diffFile',      '#dadada', _,         _,         'bold',         253, _,   'bold' },
  { 'diffLine',      '#6b4a80', _,         _,         'NONE',         96,  _,   'NONE' },

  { 'Directory',     '#dadada', _,         _,         'NONE',         253, _,   'NONE' },
  { 'EndOfBuffer',   '#707070', _,         _,         'NONE',         242, _,   'NONE' },
  { 'Error',         '#ff005f', '#000000', _,         'bold,reverse', 197, 16,  'bold,reverse' },
  { 'ErrorMsg',      '#ff005f', '#000000', _,         'bold',         197, 16,  'bold' },
  { 'FoldColumn',    '#707070', '#000000', _,         'NONE',         242, 16,  'NONE' },
  { 'Folded',        '#707070', '#000000', _,         'NONE',         242, 16,  'NONE' },
  { 'Identifier',    '#dadada', _,         _,         'NONE',         253, _,   'NONE' },
  { 'Ignore',        '#dadada', _,         _,         'NONE',         253, _,   'NONE' },
  { 'IncSearch',     '#d75fd7', '#000000', _,         'reverse',      170, 16,  'reverse' },
  { 'LineNr',        '#585858', _,         _,         'NONE',         240, _,   'NONE' },
  { 'MatchParen',    '#5e51e8', _,         _,         'bold',         20,  _,   'bold' },
  { 'ModeMsg',       '#dadada', '#000000', _,         'bold',         253, 16,  'bold' },
  { 'MoreMsg',       '#dadada', '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'MsgArea',       '#dadada', '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'MsgSeparator',  '#444444', '#000000', _,         'NONE',         238, 16,  'NONE' },
  { 'NonText',       '#707070', _,         _,         'NONE',         242, _,   'NONE' },
  { 'PreProc',       '#dadada', _,         _,         'NONE',         253, _,   'NONE' },
  { 'Question',      '#dadada', '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'QuickFixLine',  '#ff5fff', '#000000', _,         'reverse',      207, 16,  'reverse' },
  { 'Search',        '#dadada', '#221cd6', _,         'NONE',         253, 20,  'NONE' },
  { 'SignColumn',    '#dadada', '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'Special',       '#dadada', _,         _,         'NONE',         253, _,   'NONE' },
  { 'SpecialKey',    '#707070', _,         _,         'bold',         242, _,   'bold' },
  { 'SpellBad',      '#d7005f', _,         '#d7005f', 'undercurl',    161, _,   'underline' },
  { 'SpellCap',      '#0087d7', _,         '#0087d7', 'undercurl',    32,  _,   'underline' },
  { 'SpellLocal',    '#d787d7', _,         '#d787d7', 'undercurl',    176, _,   'underline' },
  { 'SpellRare',     '#00afaf', _,         '#00afaf', 'undercurl',    37,  _,   'underline' },
  { 'Statement',     '#dadada', _,         _,         'NONE',         253, _,   'NONE' },
  { 'StatusLine',    '#a8a8a8', '#121212', _,         'NONE',         248, 234, 'NONE' },
  { 'StatusLineNC',  '#5f5f5f', '#050505', _,         'NONE',         59,  233, 'NONE' },
  { 'TabLine',       '#707070', '#000000', _,         'NONE',         242, 16,  'NONE' },
  { 'TabLineFill',   '#dadada', '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'TabLineSel',    '#dadada', '#000000', _,         'bold',         253, 16,  'bold' },
  { 'Title',         _,         _,         _,         'NONE',         _,   _,   'NONE' },
  { 'TitleBar',      '#dadada', '#000000', _,         'NONE',         253, 16,  'NONE' },
  { 'TitleBarNC',    '#707070', '#000000', _,         'NONE',         242, 16,  'NONE' },
  { 'Todo',          '#00ffaf', _,         _,         'bold,reverse', 49,  _,   'bold,reverse' },
  { 'ToolbarButton', '#dadada', '#000000', _,         'bold',         253, 16,  'bold' },
  { 'ToolbarLine',   _,         '#000000', _,         'NONE',         _,   16,  'NONE' },
  { 'Type',          '#dadada', _,         _,         'NONE',         253, _,   'NONE' },
  { 'Underlined',    '#dadada', _,         _,         'underline',    253, _,   'underline' },
  { 'VertSplit',     '#707070', '#000000', _,         'NONE',         242, 16,  'NONE' },
  { 'Visual',        _,         '#444444', _,         'NONE',         _,   238, 'NONE' },
  { 'VisualNOS',     _,         '#303030', _,         'NONE',         _,   236, 'NONE' },
  { 'WarningMsg',    '#dadada', '#000000', _,         'NONE',         253, 16,  'NONE' },
}

local popups = {
  { 'NormalFloat',   '#dadada', '#000000', _, 'NONE', 253, 16,  'NONE' },
  { 'FloatBorder',   '#444444', '#000000', _, 'NONE', 238, 16,  'NONE' },
  { 'FloatTitle',    '#dadada', '#000000', _, 'NONE', 253, 16,  'NONE' },
  { 'FloatFooter',   '#707070', '#000000', _, 'NONE', 242, 16,  'NONE' },
  { 'Pmenu',         '#dadada', '#000000', _, 'NONE', 253, 16,  'NONE' },
  { 'PmenuExtra',    '#707070', '#000000', _, 'NONE', 242, 16,  'NONE' },
  { 'PmenuExtraSel', '#dadada', '#303030', _, 'NONE', 253, 236, 'NONE' },
  { 'PmenuKind',     '#707070', '#000000', _, 'NONE', 242, 16,  'NONE' },
  { 'PmenuKindSel',  '#dadada', '#303030', _, 'NONE', 253, 236, 'NONE' },
  { 'PmenuMatch',    '#ffffff', '#000000', _, 'bold', 231, 16,  'bold' },
  { 'PmenuMatchSel', '#ffffff', '#303030', _, 'bold', 231, 236, 'bold' },
  { 'PmenuSbar',     _,         '#000000', _, 'NONE', _,   16,  'NONE' },
  { 'PmenuSel',      '#dadada', '#303030', _, 'NONE', 253, 236, 'NONE' },
  { 'PmenuThumb',    _,         '#444444', _, 'NONE', _,   238, 'NONE' },
  { 'WildMenu',      '#dadada', '#303030', _, 'NONE', 253, 236, 'NONE' },
}

for from, to in pairs(links) do
  set_hl(0, from, { link = to, force = true })
end

vim.o.background = 'dark'

terminal_colors({
  '#000000', '#913939', '#00af5f', '#221cd6', '#0087d7', '#d787d7', '#00afaf', '#dadada',
  '#707070', '#9c3b3b', '#00d75f', '#221cd6', '#5fafff', '#ff87ff', '#00d7d7', '#ffffff',
})
apply(dark)
apply(popups)

set_hl(0, 'Cursor', { fg = '#000000', bg = '#dadada', ctermfg = 16, ctermbg = 253 })
