-- colors/nox.lua
-- Based on the official Gruber Darker theme by Reimer Behrends.
-- See: https://github.com/rexim/gruber-darker-theme

local M = {}

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.g.colors_name = "gruber-black"
vim.o.background = "dark"

-- CursorLineNr only takes effect when 'cursorline' is on, but we don't want
-- the whole line highlighted. Enable 'cursorline' here and leave CursorLine
-- itself with no background below. Set `vim.g.gruber_black_cursorline_number
-- = false` before `:colorscheme` to opt out and manage 'cursorline' yourself.
if vim.g.gruber_black_cursorline_number ~= false then
  vim.o.cursorline = true
end

-- Color helpers

local function rgb(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

local function clamp(v)
  return math.max(0, math.min(255, math.floor(v + 0.5)))
end

-- Blend `fg` over `bg` with alpha in [0, 1].
local function blend(fg, bg, alpha)
  local fr, fgr, fb = rgb(fg)
  local br, bgr, bb = rgb(bg)
  local function mix(f, b)
    return clamp(f * alpha + b * (1 - alpha))
  end
  return string.format("#%02x%02x%02x", mix(fr, br), mix(fgr, bgr), mix(fb, bb))
end

-- Pull a color toward the gray of equal luminance. `amount` in [0, 1]:
-- 0 leaves the color unchanged, 1 fully desaturates. Brightness is
-- preserved, so only chroma drops; neutral grays are untouched.
local function desaturate(hex, amount)
  local r, g, b = rgb(hex)
  local gray = 0.2126 * r + 0.7152 * g + 0.0722 * b
  local function go(c)
    return clamp(c + (gray - c) * amount)
  end
  return string.format("#%02x%02x%02x", go(r), go(g), go(b))
end

-- Scale brightness by `factor` (1 = unchanged, <1 = darker, >1 = brighter).
-- Hue and saturation are preserved, so applying the same factor to every
-- text color keeps the palette harmonious.
local function dim(hex, factor)
  local r, g, b = rgb(hex)
  return string.format("#%02x%02x%02x", clamp(r * factor), clamp(g * factor), clamp(b * factor))
end

-- Approximate a "#rrggbb" color as the nearest xterm-256 index. Used as the
-- `cterm*` fallback for terminals without true-color support.
local function hex_to_256(hex)
  local r, g, b = rgb(hex)
  if r == g and g == b then
    if r < 8 then
      return 16
    elseif r > 248 then
      return 231
    end
    return clamp((r - 8) / 247 * 24) + 232
  end
  local steps = { 0, 95, 135, 175, 215, 255 }
  local function nearest_step(c)
    local best, best_d = 0, math.huge
    for i, s in ipairs(steps) do
      local d = math.abs(c - s)
      if d < best_d then
        best_d, best = d, i - 1
      end
    end
    return best
  end
  return 16 + 36 * nearest_step(r) + 6 * nearest_step(g) + nearest_step(b)
end

-- Return the cterm index for a "#rrggbb" string; pass through anything else
-- (named colors, "NONE", nil) untouched.
local function to_cterm(hex)
  if type(hex) == "string" and hex:match("^#%x%x%x%x%x%x$") then
    return hex_to_256(hex)
  end
  return nil
end

-- Apply a highlight group, deriving ctermfg/ctermbg from any hex fg/bg so the
-- theme degrades gracefully when 'termguicolors' is off.
local function hi(group, opts)
  if not opts.link then
    if opts.fg and opts.ctermfg == nil then
      opts.ctermfg = to_cterm(opts.fg)
    end
    if opts.bg and opts.ctermbg == nil then
      opts.ctermbg = to_cterm(opts.bg)
    end
  end
  vim.api.nvim_set_hl(0, group, opts)
end

-- Palette
--
-- `original` is the exact Gruber Darker palette. Emacs naming conventions
-- are preserved in comments: "+N" = lighter (_lN here), "-N" = darker (_dN).

local original = {
  fg = "#e4e4ef",
  fg_l1 = "#f4f4ff", -- fg+1
  fg_l2 = "#f5f5f5", -- fg+2
  white = "#ffffff",
  black = "#000000",

  bg_d1 = "#101010",  -- bg-1
  bg = "#181818",
  bg_l1 = "#282828",  -- bg+1
  bg_l2 = "#453d41",  -- bg+2
  bg_l3 = "#484848",  -- bg+3
  bg_l4 = "#52494e",  -- bg+4

  red_d1 = "#c73c3f", -- red-1
  red = "#f43841",
  red_l1 = "#ff4f58", -- red+1
  green = "#73c936",
  yellow = "#ffdd33",
  brown = "#cc8c3c",

  quartz = "#95a99f",
  niagara_d2 = "#303540", -- niagara-2
  niagara_d1 = "#565f73", -- niagara-1
  niagara = "#96a6c8",
  wisteria = "#9e95c7",
}

-- Global desaturation amount: 0 = original Gruber Darker, 1 = grayscale.
-- Override before `:colorscheme` with `vim.g.gruber_black_desat = 0.5`.
local DESAT = vim.g.gruber_black_desat or 0.35

-- Text brightness factor: 1 = original, lower = softer. Override with
-- `vim.g.gruber_black_dim = 0.7`.
local DIM = vim.g.gruber_black_dim or 0.8

-- Surfaces and already-dark grays are not dimmed; only colors used as text.
local no_dim = {
  black = true,
  bg = true,
  bg_d1 = true,
  bg_l1 = true,
  bg_l2 = true,
  bg_l3 = true,
  bg_l4 = true,
  niagara_d1 = true,
  niagara_d2 = true,
}

local colors = {}
for name, hex in pairs(original) do
  local c = desaturate(hex, DESAT)
  colors[name] = no_dim[name] and c or dim(c, DIM)
end

-- Replace the original #181818 background with pure black.
colors.bg = "#000000"
colors.black = "#000000"

-- Yellow is the accent color (keywords, cursor, current line number,
-- selected tab), so it is dimmed and desaturated less than the rest.
-- YELLOW_DESAT 0 / YELLOW_DIM 1 reproduces the original #ffdd33.
local YELLOW_DESAT = 0.3
local YELLOW_DIM = 0.92
colors.yellow = dim(desaturate(original.yellow, YELLOW_DESAT), YELLOW_DIM)

-- Green (strings, checked items) is desaturated slightly more than the
-- global amount and brightened rather than dimmed, keeping strings legible.
local GREEN_DESAT = 0.45
colors.green = dim(desaturate(original.green, GREEN_DESAT), 1.05)

-- Extra tones
colors.comment = "#4b4b4b"    -- darker neutral gray, distinct from code
colors.cursorline = "#111111" -- barely lighter than the background
colors.popup_sel = "#1e1e1e"  -- selected item inside black popups

-- Diagnostics and diffs share the accent's warm low-saturation family so
-- they read as part of the theme instead of clashing traffic-light colors.
-- Semantic meaning is preserved (red = error, green = ok, yellow = warn),
-- just muted toward the accent yellow and dimmed for a calmer feel.
colors.diag_red = dim(blend(colors.yellow, desaturate(original.red, 0.4), 0.15), 0.88)
colors.diag_green = dim(blend(colors.yellow, desaturate(original.green, 0.5), 0.15), 0.85)
colors.diag_warn = dim(desaturate(original.yellow, 0.35), 0.78)

-- Diff backgrounds (Emacs has none; Neovim requires them).
colors.diff_add_bg = blend(colors.diag_green, colors.bg, 0.14)
colors.diff_change_bg = blend(colors.niagara, colors.bg, 0.13)
colors.diff_delete_bg = blend(colors.diag_red, colors.bg, 0.14)
colors.diff_text_bg = blend(colors.niagara, colors.bg, 0.32)

-- Search uses a desaturated blue, distinct from the accent yellow so matches
-- don't read as cursors. The current match is a lighter shade of the same
-- blue, so it still belongs to the search while standing out from the rest.
colors.search_bg = original.niagara
colors.search_cur_bg = dim(original.niagara, 1.25)

-- Statusline text sits between Comment and normal text for a calmer,
-- chrome-like feel. Inactive windows drop further, down to Comment.
colors.statusline_fg = dim(desaturate(original.fg, 0.5), 0.55)

-- Visual selection
colors.visual_bg = blend(colors.yellow, colors.bg_l3, 0.22)
colors.pmenu_sel_bg = blend(colors.yellow, colors.popup_sel, 0.25)

-- Structural chrome (separators, scrollbar thumb) gets a hint of niagara so
-- it feels like part of the palette rather than flat neutral gray.
colors.separator = blend(colors.niagara, colors.bg_l2, 0.18)
colors.pmenu_thumb = blend(colors.niagara, colors.bg_l3, 0.25)

-- Terminal colors (same mapping as term-color-* in the Emacs theme)
local terminal = {
  colors.bg_l3, -- black
  colors.red_d1,
  colors.green,
  colors.yellow,
  colors.niagara,  -- blue
  colors.wisteria, -- magenta
  colors.quartz,   -- cyan
  colors.fg,       -- white
  colors.bg_l4,    -- bright black
  colors.red_l1,
  colors.green,
  colors.yellow,
  colors.niagara,
  colors.wisteria,
  colors.quartz,
  colors.white,
}

for i, color in ipairs(terminal) do
  vim.g["terminal_color_" .. (i - 1)] = color
end

-- Cursor color is set in two layers so it works regardless of terminal or 'guicursor'
if vim.o.guicursor ~= "" then
  local entries = {}
  for entry in vim.gsplit(vim.o.guicursor, ",", { plain = true }) do
    if entry:find(":", 1, true) and not entry:find("Cursor", 1, true) then
      entry = entry .. "-Cursor"
    end
    table.insert(entries, entry)
  end
  vim.o.guicursor = table.concat(entries, ",")
end

local function term_send(seq)
  if vim.api.nvim_ui_send then
    pcall(vim.api.nvim_ui_send, seq)
  else
    pcall(vim.api.nvim_chan_send, vim.v.stderr, seq)
  end
end

local function cursor_set()
  term_send("\027]12;" .. colors.yellow .. "\007")
end

local function cursor_reset()
  term_send("\027]112\007")
end

local cursor_group = vim.api.nvim_create_augroup("GruberBlackCursor", { clear = true })
vim.api.nvim_create_autocmd({ "UIEnter", "VimResume", "FocusGained" }, {
  group = cursor_group,
  callback = cursor_set,
})
vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend", "ColorSchemePre" }, {
  group = cursor_group,
  callback = cursor_reset,
})
cursor_set()

-- Highlight groups

local groups = {

  -- Editor UI
  ColorColumn                              = { bg = colors.cursorline },
  Conceal                                  = { fg = colors.bg_l4, nocombine = true },
  Cursor                                   = { bg = colors.yellow, fg = colors.bg },
  CursorLineNr                             = { fg = colors.yellow, bold = true },
  Directory                                = { fg = colors.niagara, bold = true },

  DiffAdd                                  = { bg = colors.diff_add_bg },
  DiffChange                               = { bg = colors.diff_change_bg },
  DiffDelete                               = { bg = colors.diff_delete_bg, fg = colors.diag_red },
  DiffText                                 = { bg = colors.diff_text_bg, fg = colors.fg_l1 },
  DiffTextAdd                              = { bg = colors.diff_text_bg, fg = colors.fg_l1, bold = true },

  ErrorMsg                                 = { fg = colors.diag_red, nocombine = true },
  LineNr                                   = { fg = colors.bg_l4 },
  MatchParen                               = { bg = colors.bg_l4, fg = colors.wisteria, bold = true },
  NonText                                  = { fg = colors.bg_l2, nocombine = true },

  Normal                                   = { bg = colors.bg, fg = colors.fg, nocombine = true },
  NormalNC                                 = { link = "Normal" },
  NormalFloat                              = { bg = colors.bg, fg = colors.fg },
  FloatTitle                               = { fg = colors.yellow, bg = colors.bg, bold = true },
  FloatFooter                              = { link = "Comment" },
  FloatBorder                              = { fg = colors.bg_l3, bg = colors.bg },

  SignColumn                               = {},

  Search                                   = { bg = colors.search_bg, fg = colors.black, bold = true },
  IncSearch                                = { bg = colors.search_cur_bg, fg = colors.black, bold = true },
  CurSearch                                = { link = "IncSearch" },
  Substitute                               = { link = "IncSearch" },

  Title                                    = { fg = colors.yellow, bold = true },
  QuickFixLine                             = { bg = blend(colors.niagara, colors.cursorline, 0.1) },
  WarningMsg                               = { fg = colors.diag_warn, bold = true, nocombine = true },
  WildMenu                                 = { link = "PmenuSel" },
  Whitespace                               = { fg = colors.bg_l2 },
  SpecialKey                               = { link = "NonText" },
  MsgArea                                  = { link = "Normal" },
  MsgSeparator                             = { link = "StatusLine" },

  healthError                              = { link = "ErrorMsg" },
  healthWarning                            = { link = "WarningMsg" },
  healthSuccess                            = { fg = colors.diag_green },

  lCursor                                  = { link = "Cursor" },
  CursorIM                                 = { link = "Cursor" },
  TermCursor                               = { link = "Cursor" },
  TermCursorNC                             = { fg = colors.bg, bg = colors.quartz },

  CursorColumn                             = { link = "ColorColumn" },
  CursorLine                               = {},
  CursorLineFold                           = { link = "CursorLine" },
  CursorLineSign                           = { link = "CursorLine" },
  EndOfBuffer                              = { link = "NonText" },

  VertSplit                                = { fg = colors.separator, bg = colors.bg },
  WinSeparator                             = { fg = colors.separator, bg = colors.bg },
  WinBar                                   = { link = "StatusLine" },
  WinBarNC                                 = { link = "StatusLineNC" },

  Folded                                   = { fg = colors.niagara, bg = colors.niagara_d2 },
  FoldColumn                               = { link = "Conceal" },

  MoreMsg                                  = { fg = colors.diag_green },
  PopupNotification                        = { link = "WarningMsg" },
  Question                                 = { fg = colors.diag_green },
  ModeMsg                                  = { link = "Normal" },
  Terminal                                 = { link = "Normal" },

  -- Completion menu
  Pmenu                                    = { bg = colors.bg, fg = colors.fg, nocombine = true },
  PmenuSbar                                = { bg = colors.bg, nocombine = true },
  PmenuSel                                 = { bg = colors.pmenu_sel_bg, fg = colors.fg_l1 },
  PmenuThumb                               = { bg = colors.pmenu_thumb },
  PmenuKind                                = { link = "Pmenu" },
  PmenuKindSel                             = { link = "PmenuSel" },
  PmenuExtra                               = { fg = colors.brown, bg = colors.bg },
  PmenuExtraSel                            = { fg = colors.brown, bg = colors.pmenu_sel_bg },
  PmenuMatch                               = { fg = colors.green, bold = true },
  PmenuMatchSel                            = { link = "PmenuMatch" },
  MessageWindow                            = { link = "NormalFloat" },

  SpellBad                                 = { undercurl = true, sp = colors.diag_red },
  SpellCap                                 = { undercurl = true, sp = colors.yellow },
  SpellLocal                               = { undercurl = true, sp = colors.niagara },
  SpellRare                                = { undercurl = true, sp = colors.wisteria },

  StatusLine                               = { bg = colors.bg, fg = colors.statusline_fg, nocombine = true },
  StatusLineNC                             = { bg = colors.bg, fg = colors.comment, nocombine = true },
  StatuslineTerm                           = { link = "StatusLine" },
  StatuslineTermNC                         = { link = "StatusLineNC" },

  TabLine                                  = { bg = colors.bg_l1, fg = colors.bg_l4, nocombine = true },
  TabLineFill                              = { bg = colors.bg_l1, nocombine = true },
  TabLineSel                               = { bg = colors.bg, fg = colors.yellow, bold = true, nocombine = true },
  ToolbarLine                              = { link = "TabLine" },
  ToolbarButton                            = { link = "TabLineSel" },

  -- Visual selection
  Visual                                   = { bg = colors.visual_bg },
  VisualNOS                                = { link = "Visual" },

  -- Classic syntax groups
  Comment                                  = { fg = colors.comment },
  String                                   = { fg = colors.green, nocombine = true },
  Character                                = { link = "String" },
  Constant                                 = { fg = colors.quartz },
  Number                                   = { fg = colors.wisteria },
  Float                                    = { link = "Number" },
  Boolean                                  = { fg = colors.quartz },
  Identifier                               = { fg = colors.fg_l1 },
  Function                                 = { fg = colors.niagara },
  Statement                                = { fg = colors.yellow, bold = true },
  Operator                                 = { fg = colors.yellow },
  PreProc                                  = { fg = colors.quartz },
  Type                                     = { fg = colors.quartz },
  Special                                  = { fg = colors.quartz },
  Delimiter                                = { fg = colors.fg },
  Todo                                     = { fg = colors.yellow, bold = true },
  Link                                     = { fg = colors.niagara, underline = true },
  Ignore                                   = { link = "Comment" },
  Exception                                = { link = "Statement" },
  Error                                    = { link = "ErrorMsg" },
  Text                                     = { link = "Normal" },
  Underlined                               = { fg = colors.niagara, underline = true },

  -- Diagnostics
  DiagnosticError                          = { fg = colors.diag_red },
  DiagnosticWarn                           = { fg = colors.diag_warn },
  DiagnosticInfo                           = { fg = colors.niagara },
  DiagnosticHint                           = { fg = colors.quartz },
  DiagnosticOk                             = { fg = colors.diag_green },

  DiagnosticUnderlineError                 = { undercurl = true, sp = colors.diag_red },
  DiagnosticUnderlineWarn                  = { undercurl = true, sp = colors.diag_warn },
  DiagnosticUnderlineInfo                  = { undercurl = true, sp = colors.niagara },
  DiagnosticUnderlineHint                  = { undercurl = true, sp = colors.quartz },
  DiagnosticUnderlineOk                    = { undercurl = true, sp = colors.diag_green },

  DiagnosticVirtualTextError               = { fg = colors.diag_red },
  DiagnosticVirtualTextWarn                = { fg = colors.diag_warn },
  DiagnosticVirtualTextInfo                = { fg = colors.niagara_d1 },
  DiagnosticVirtualTextHint                = { fg = colors.niagara_d1 },
  DiagnosticVirtualTextOk                  = { fg = colors.diag_green },

  DiagnosticFloatingError                  = { link = "DiagnosticError" },
  DiagnosticFloatingWarn                   = { link = "DiagnosticWarn" },
  DiagnosticFloatingInfo                   = { link = "DiagnosticInfo" },
  DiagnosticFloatingHint                   = { link = "DiagnosticHint" },
  DiagnosticFloatingOk                     = { link = "DiagnosticOk" },

  DiagnosticSignError                      = { link = "DiagnosticError" },
  DiagnosticSignWarn                       = { link = "DiagnosticWarn" },
  DiagnosticSignInfo                       = { link = "DiagnosticInfo" },
  DiagnosticSignHint                       = { link = "DiagnosticHint" },
  DiagnosticSignOk                         = { link = "DiagnosticOk" },

  DiagnosticDeprecated                     = { fg = blend(colors.wisteria, colors.bg_l4, 0.35), strikethrough = true, italic = true },
  DiagnosticUnnecessary                    = { fg = colors.bg_l4 },

  -- LSP
  LspReferenceText                         = { bg = colors.niagara_d2 },
  LspReferenceRead                         = { bg = colors.niagara_d2 },
  LspReferenceWrite                        = { bg = colors.niagara_d2, underline = true },
  LspSignatureActiveParameter              = { fg = colors.yellow, bold = true },
  LspCodeLens                              = { link = "Comment" },
  LspCodeLensSeparator                     = { link = "Comment" },
  LspInlayHint                             = { fg = colors.niagara_d1 },

  -- Treesitter variables
  ["@variable"]                            = { fg = colors.fg_l1 },
  ["@variable.builtin"]                    = { fg = colors.yellow, italic = true },
  ["@variable.parameter"]                  = { fg = colors.fg_l1, italic = true },
  ["@variable.parameter.builtin"]          = { fg = colors.yellow, italic = true },
  ["@variable.member"]                     = { fg = colors.fg_l1 },
  ["@property"]                            = { fg = colors.fg_l1 },

  ["@module"]                              = { fg = colors.quartz },
  ["@module.builtin"]                      = { fg = colors.quartz },
  ["@label"]                               = { fg = colors.niagara },

  -- Treesitter literals
  ["@constant"]                            = { link = "Constant" },
  ["@constant.builtin"]                    = { fg = colors.quartz, bold = true },
  ["@constant.macro"]                      = { link = "PreProc" },
  ["@boolean"]                             = { link = "Boolean" },
  ["@number"]                              = { link = "Number" },
  ["@number.float"]                        = { link = "Number" },

  ["@string"]                              = { link = "String" },
  ["@string.documentation"]                = { fg = colors.green, italic = true },
  ["@string.regexp"]                       = { fg = colors.wisteria },
  ["@string.escape"]                       = { fg = colors.wisteria },
  ["@string.special"]                      = { fg = colors.wisteria },
  ["@string.special.symbol"]               = { fg = colors.quartz },
  ["@string.special.url"]                  = { fg = colors.niagara, underline = true },
  ["@character"]                           = { link = "Character" },
  ["@character.special"]                   = { fg = colors.wisteria },

  -- Treesitter types
  ["@type"]                                = { link = "Type" },
  ["@type.builtin"]                        = { link = "Type" },
  ["@type.definition"]                     = { link = "Type" },
  ["@type.qualifier"]                      = { fg = colors.yellow, bold = true, italic = true },

  ["@attribute"]                           = { link = "PreProc" },
  ["@attribute.builtin"]                   = { link = "PreProc" },

  -- Treesitter functions
  ["@function"]                            = { fg = colors.niagara },
  ["@function.builtin"]                    = { fg = colors.yellow },
  ["@function.call"]                       = { fg = colors.niagara },
  ["@function.macro"]                      = { link = "PreProc" },
  ["@function.method"]                     = { fg = colors.niagara },
  ["@function.method.call"]                = { fg = colors.niagara },
  ["@constructor"]                         = { link = "Type" },

  ["@operator"]                            = { link = "Operator" },

  -- Treesitter keywords
  ["@keyword"]                             = { link = "Statement" },
  ["@keyword.coroutine"]                   = { link = "Statement" },
  ["@keyword.function"]                    = { link = "Statement" },
  ["@keyword.operator"]                    = { link = "Statement" },
  ["@keyword.import"]                      = { link = "Statement" },
  ["@keyword.type"]                        = { link = "Statement" },
  ["@keyword.modifier"]                    = { link = "Statement" },
  ["@keyword.repeat"]                      = { link = "Statement" },
  ["@keyword.return"]                      = { link = "Statement" },
  ["@keyword.debug"]                       = { link = "WarningMsg" },
  ["@keyword.exception"]                   = { link = "Statement" },
  ["@keyword.conditional"]                 = { link = "Statement" },
  ["@keyword.conditional.ternary"]         = { fg = colors.fg },
  ["@keyword.directive"]                   = { link = "PreProc" },
  ["@keyword.directive.define"]            = { link = "PreProc" },

  -- Treesitter punctuation
  ["@punctuation.bracket"]                 = { fg = colors.fg },
  ["@punctuation.delimiter"]               = { fg = colors.fg },
  ["@punctuation.special"]                 = { fg = colors.fg },

  -- Treesitter comments
  ["@comment"]                             = { link = "Comment" },
  ["@comment.documentation"]               = { fg = colors.comment },
  ["@comment.error"]                       = { fg = colors.diag_red, bold = true },
  ["@comment.warning"]                     = { fg = colors.diag_warn, bold = true },
  ["@comment.todo"]                        = { link = "Todo" },
  ["@comment.note"]                        = { fg = colors.niagara, bold = true },

  -- Treesitter markup
  ["@markup.strong"]                       = { fg = colors.quartz, bold = true },
  ["@markup.italic"]                       = { fg = colors.quartz, italic = true },
  ["@markup.strikethrough"]                = { strikethrough = true, fg = colors.bg_l4 },
  ["@markup.underline"]                    = { underline = true },
  ["@markup.heading"]                      = { link = "Title" },
  ["@markup.heading.1"]                    = { fg = colors.yellow, bold = true },
  ["@markup.heading.2"]                    = { fg = colors.niagara, bold = true },
  ["@markup.heading.3"]                    = { fg = colors.quartz, bold = true },
  ["@markup.heading.4"]                    = { fg = colors.wisteria, bold = true },
  ["@markup.heading.5"]                    = { fg = colors.fg, bold = true },
  ["@markup.heading.6"]                    = { fg = colors.fg },
  ["@markup.quote"]                        = { fg = colors.quartz, italic = true },
  ["@markup.math"]                         = { fg = colors.green },
  ["@markup.link"]                         = { fg = colors.niagara, underline = true },
  ["@markup.link.label"]                   = { fg = colors.niagara },
  ["@markup.link.url"]                     = { fg = colors.niagara_d1, underline = true },
  ["@markup.raw"]                          = { fg = colors.green },
  ["@markup.raw.block"]                    = { fg = colors.fg },
  ["@markup.raw.delimiter"]                = { fg = colors.bg_l4 },
  ["@markup.list"]                         = { fg = colors.yellow },
  ["@markup.list.checked"]                 = { fg = colors.diag_green },
  ["@markup.list.unchecked"]               = { fg = colors.yellow },

  ["@tag"]                                 = { link = "Statement" },
  ["@tag.attribute"]                       = { fg = colors.quartz },
  ["@tag.delimiter"]                       = { fg = colors.fg },

  ["@diff.plus"]                           = { fg = colors.diag_green },
  ["@diff.minus"]                          = { fg = colors.diag_red },
  ["@diff.delta"]                          = { fg = colors.niagara },

  -- LSP semantic tokens
  ["@lsp.type.class"]                      = { link = "@type" },
  ["@lsp.type.comment"]                    = {}, -- let Treesitter handle comments
  ["@lsp.type.decorator"]                  = { link = "@attribute" },
  ["@lsp.type.enum"]                       = { link = "@type" },
  ["@lsp.type.enumMember"]                 = { link = "@constant" },
  ["@lsp.type.function"]                   = { link = "@function" },
  ["@lsp.type.interface"]                  = { link = "@type" },
  ["@lsp.type.macro"]                      = { link = "@function.macro" },
  ["@lsp.type.method"]                     = { link = "@function.method" },
  ["@lsp.type.namespace"]                  = { link = "@module" },
  ["@lsp.type.parameter"]                  = { link = "@variable.parameter" },
  ["@lsp.type.property"]                   = { link = "@property" },
  ["@lsp.type.struct"]                     = { link = "@type" },
  ["@lsp.type.type"]                       = { link = "@type" },
  ["@lsp.type.typeParameter"]              = { link = "@type" },
  ["@lsp.type.variable"]                   = { link = "@variable" },
  ["@lsp.mod.deprecated"]                  = { strikethrough = true },
  ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
  ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
  ["@lsp.typemod.variable.readonly"]       = { fg = colors.quartz, italic = true },

  -- Help
  helpHeadline                             = { link = "Title" },
  helpSectionDelim                         = { link = "Comment" },
  helpExample                              = { link = "String" },
  helpBar                                  = { link = "Comment" },
  helpHyperTextJump                        = { link = "Link" },
  helpHyperTextEntry                       = { link = "Link" },
  helpVim                                  = { link = "String" },
  helpCommand                              = { link = "String" },
  helpHeader                               = { link = "Title" },
  helpNote                                 = { link = "Todo" },
  helpWarning                              = { link = "WarningMsg" },
  helpDeprecated                           = { link = "ErrorMsg" },
  helpURL                                  = { link = "Link" },

  -- Diff (syntax)
  diffAdded                                = { fg = colors.diag_green },
  diffRemoved                              = { fg = colors.diag_red },
  diffChanged                              = { fg = colors.niagara },
  diffComment                              = { link = "Comment" },
  diffFile                                 = { fg = colors.wisteria },
  diffNewFile                              = { fg = colors.diag_green },
  diffOldFile                              = { fg = colors.diag_red },
  diffLine                                 = { fg = colors.niagara },
  diffIndexLine                            = { fg = colors.quartz },
  diffSubname                              = { link = "Normal" },
  diffCommon                               = { link = "Normal" },
  diffBDiffer                              = { link = "Normal" },
  diffDiffer                               = { link = "Normal" },
  diffIdentical                            = { link = "Normal" },
  diffIsA                                  = { link = "Normal" },
  diffNoEOL                                = { link = "Normal" },
  diffOnly                                 = { link = "Normal" },

  -- Markdown (legacy :syntax groups, used when the vim regex highlighter
  -- runs alongside or instead of Treesitter)
  markdownH1                               = { link = "@markup.heading.1" },
  markdownH2                               = { link = "@markup.heading.2" },
  markdownH3                               = { link = "@markup.heading.3" },
  markdownH4                               = { link = "@markup.heading.4" },
  markdownH5                               = { link = "@markup.heading.5" },
  markdownH6                               = { link = "@markup.heading.6" },
  markdownHeadingDelimiter                 = { fg = colors.bg_l4 },
  markdownHeadingRule                      = { fg = colors.bg_l2 },
  markdownCode                             = { link = "@markup.raw" },
  markdownCodeBlock                        = { link = "@markup.raw.block" },
  markdownCodeDelimiter                    = { link = "@markup.raw.delimiter" },
  markdownBlockquote                       = { link = "@markup.quote" },
  markdownListMarker                       = { link = "@markup.list" },
  markdownOrderedListMarker                = { link = "@markup.list" },
  markdownRule                             = { fg = colors.bg_l2 },
  markdownBold                             = { bold = true },
  markdownItalic                           = { italic = true },
  markdownBoldItalic                       = { bold = true, italic = true },
  markdownStrike                           = { link = "@markup.strikethrough" },
  markdownLinkText                         = { link = "@markup.link" },
  markdownUrl                              = { link = "@markup.link.url" },
  markdownLinkDelimiter                    = { fg = colors.bg_l4 },
  markdownIdDelimiter                      = { fg = colors.bg_l4 },
  markdownAutomaticLink                    = { link = "@markup.link.url" },
  gitcommitSelectedFile                    = { fg = colors.diag_green },
  gitcommitDiscardedFile                   = { fg = colors.diag_red },
  gitcommitUntrackedFile                   = { fg = colors.brown },
  gitcommitSummary                         = { link = "String" },

  -- render-markdown.nvim
  RenderMarkdownH1                         = { link = "@markup.heading.1" },
  RenderMarkdownH2                         = { link = "@markup.heading.2" },
  RenderMarkdownH3                         = { link = "@markup.heading.3" },
  RenderMarkdownH4                         = { link = "@markup.heading.4" },
  RenderMarkdownH5                         = { link = "@markup.heading.5" },
  RenderMarkdownH6                         = { link = "@markup.heading.6" },
  RenderMarkdownH1Bg                       = {},
  RenderMarkdownH2Bg                       = {},
  RenderMarkdownH3Bg                       = {},
  RenderMarkdownH4Bg                       = {},
  RenderMarkdownH5Bg                       = {},
  RenderMarkdownH6Bg                       = {},
  RenderMarkdownCode                       = {},
  RenderMarkdownCodeInline                 = { link = "@markup.raw" },
  RenderMarkdownCodeBorder                 = { fg = colors.bg_l2 },
  RenderMarkdownBullet                     = { fg = colors.yellow },
  RenderMarkdownIndent                     = { fg = colors.bg_l1 },
  RenderMarkdownQuote                      = { link = "@markup.quote" },
  RenderMarkdownDash                       = { fg = colors.bg_l2 },
  RenderMarkdownLink                       = { link = "Link" },
  RenderMarkdownWikiLink                   = { link = "Link" },
  RenderMarkdownSign                       = { fg = colors.bg_l4 },
  RenderMarkdownMath                       = { link = "@markup.math" },
  RenderMarkdownUnchecked                  = { fg = colors.yellow },
  RenderMarkdownChecked                    = { fg = colors.diag_green },
  RenderMarkdownTodo                       = { link = "Todo" },
  RenderMarkdownTableHead                  = { fg = colors.yellow, bold = true },
  RenderMarkdownTableRow                   = { fg = colors.fg },
  RenderMarkdownTableFill                  = { fg = colors.bg_l2 },
  RenderMarkdownSuccess                    = { link = "DiagnosticOk" },
  RenderMarkdownInfo                       = { link = "DiagnosticInfo" },
  RenderMarkdownHint                       = { link = "DiagnosticHint" },
  RenderMarkdownWarn                       = { link = "DiagnosticWarn" },
  RenderMarkdownError                      = { link = "DiagnosticError" },

  -- LaTeX (vimtex)
  --
  -- Targets vimtex's primitive groups (texCmd, texMathZone, texOpt, ...);
  -- more specific groups are `highlight def link`ed to these. Mirrors
  -- AUCTeX's font-latex split, prose stays neutral, LaTeX syntax (commands,
  -- environments, definitions) gets the keyword yellow, and math zones only
  -- color their delimiters (green) so prose vs. math is clear from the frame.
  texCmd                                   = { link = "Statement" },
  texCmdType                               = { link = "Statement" },
  texCmdEnv                                = { link = "Statement" },
  texEnvArgName                            = { fg = colors.niagara },
  texOpt                                   = { fg = colors.quartz },
  texArg                                   = { link = "Normal" },

  texCmdPart                               = { fg = colors.niagara, bold = true }, -- \part, \chapter, \section, ...
  texCmdRef                                = { link = "texCmd" },
  texRefArg                                = { fg = colors.niagara, underline = true },
  texCmdAccent                             = { fg = colors.fg },
  texCmdGreek                              = { fg = colors.wisteria },
  texCmdNew                                = { fg = colors.yellow, bold = true },
  texCmdNewenv                             = { fg = colors.yellow, bold = true },

  texTitleArg                              = { fg = colors.fg_l1, bold = true },
  texPartArgTitle                          = { fg = colors.fg_l1 },

  -- Style commands color the text they wrap, not the command name.
  texStyleBold                             = { fg = colors.quartz, bold = true },
  texStyleItal                             = { fg = colors.quartz, italic = true },
  texStyleUnder                            = { underline = true },
  texStyleBoth                             = { fg = colors.quartz, bold = true, italic = true },
  texStyleBoldUnder                        = { fg = colors.quartz, bold = true, underline = true },
  texStyleItalUnder                        = { fg = colors.quartz, italic = true, underline = true },
  texStyleBoldItalUnder                    = { fg = colors.quartz, bold = true, italic = true, underline = true },

  -- Math zone delimiters by syntax form.
  texMathDelimZoneX                        = { fg = colors.green, bold = true }, -- $...$
  texMathDelimZoneY                        = { fg = colors.green, bold = true }, -- $$...$$
  texMathDelimZoneTI                       = { fg = colors.green, bold = true }, -- \(...\)
  texMathDelimZoneZ                        = { fg = colors.green, bold = true }, -- \[...\]
  texMathDelimZoneV                        = { fg = colors.green, bold = true },
  texMathDelimZoneW                        = { fg = colors.green, bold = true },
  texMathDelimZoneT                        = { fg = colors.green, bold = true },
  texMathDelimZoneEnv                      = { fg = colors.green, bold = true },
  texMathDelimZoneEnsured                  = { fg = colors.green, bold = true },
  texMathDelimZoneLabel                    = { fg = colors.green, bold = true },

  texComment                               = { link = "Comment" },
  texCommentTodo                           = { link = "Todo" },
  texSpecialChar                           = { fg = colors.wisteria },
  texSymbol                                = { fg = colors.fg },
  texLigature                              = { fg = colors.quartz },
  texZone                                  = { fg = colors.fg },
  texError                                 = { link = "ErrorMsg" },

  texFileArg                               = { fg = colors.green },
  texLength                                = { fg = colors.wisteria },
  texParm                                  = { fg = colors.quartz },

  VimtexSuccess                            = { link = "DiagnosticOk" },
  VimtexWarning                            = { link = "WarningMsg" },
  VimtexError                              = { link = "DiagnosticError" },
  VimtexInfo                               = { link = "DiagnosticInfo" },
  VimtexTodo                               = { link = "Todo" },
  VimtexFatal                              = { link = "ErrorMsg" },

  -- Git
  Added                                    = { fg = colors.diag_green },
  Changed                                  = { fg = colors.niagara },
  Removed                                  = { fg = colors.diag_red },
  GitSignsAdd                              = { fg = colors.diag_green },
  GitSignsChange                           = { fg = colors.niagara },
  GitSignsDelete                           = { fg = colors.diag_red },

  -- oil.nvim
  OilDir                                   = { link = "Directory" },
  OilDirIcon                               = { fg = colors.niagara },
  OilLink                                  = { fg = colors.wisteria, italic = true },
  OilLinkTarget                            = { link = "Comment" },
  OilCopy                                  = { fg = colors.diag_green, bold = true },
  OilMove                                  = { fg = colors.niagara, bold = true },
  OilChange                                = { fg = colors.diag_warn, bold = true },
  OilCreate                                = { fg = colors.diag_green, bold = true },
  OilDelete                                = { fg = colors.diag_red, bold = true },
  OilRestore                               = { link = "OilCreate" },
  OilPurge                                 = { link = "OilDelete" },
  OilTrash                                 = { link = "Comment" },
  OilTrashSourcePath                       = { link = "Comment" },
  OilPermissionNone                        = { fg = colors.comment },
  OilPermissionRead                        = { fg = colors.yellow },
  OilPermissionWrite                       = { fg = colors.diag_red },
  OilPermissionExecute                     = { fg = colors.diag_green },
  OilTypeDir                               = { link = "OilDir" },
  OilTypeFile                              = { fg = colors.fg },
  OilTypeLink                              = { link = "OilLink" },
  OilTypeFifo                              = { fg = colors.quartz },
  OilTypeSocket                            = { fg = colors.quartz },
  OilTypeChar                              = { fg = colors.quartz },
  OilTypeBlock                             = { fg = colors.quartz },
  OilSocket                                = { fg = colors.quartz },

  -- blink.cmp
  BlinkCmpMenu                             = { link = "Pmenu" },
  BlinkCmpMenuBorder                       = { link = "FloatBorder" },
  BlinkCmpMenuSelection                    = { link = "PmenuSel" },
  BlinkCmpScrollBarThumb                   = { link = "PmenuThumb" },
  BlinkCmpLabel                            = { link = "Pmenu" },
  BlinkCmpLabelMatch                       = { link = "PmenuMatch" },
  BlinkCmpLabelDeprecated                  = { fg = colors.bg_l4, strikethrough = true },
  BlinkCmpLabelDescription                 = { link = "Comment" },
  BlinkCmpLabelDetail                      = { link = "Comment" },
  BlinkCmpKind                             = { fg = colors.quartz },
  BlinkCmpDoc                              = { link = "NormalFloat" },
  BlinkCmpDocBorder                        = { link = "FloatBorder" },
  BlinkCmpSignatureHelp                    = { link = "NormalFloat" },
  BlinkCmpSignatureHelpBorder              = { link = "FloatBorder" },
  BlinkCmpSignatureHelpActiveParameter     = { link = "LspSignatureActiveParameter" },
}

for group, opts in pairs(groups) do
  hi(group, opts)
end

-- Exposed so other plugins (e.g. lualine) can reuse the palette and helpers.
M.colors = colors
M.original = original
M.blend = blend
M.desaturate = desaturate

return M
