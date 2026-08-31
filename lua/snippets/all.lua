local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local rep = require("luasnip.extras").rep

local function get_date()
  return os.date("%Y-%m-%d")
end

local function get_year()
  return os.date("%Y")
end

local function get_filename()
  local name = vim.fn.expand("%:t")
  return name ~= "" and name or "untitled"
end

local comment_styles = {
  lua        = { kind = "line", sym = "--" },
  python     = { kind = "line", sym = "#" },
  sh         = { kind = "line", sym = "#" },
  bash       = { kind = "line", sym = "#" },
  zsh        = { kind = "line", sym = "#" },
  yaml       = { kind = "line", sym = "#" },
  toml       = { kind = "line", sym = "#" },
  vim        = { kind = "line", sym = '"' },
  c          = { kind = "block", open = "/*", close = "*/" },
  cpp        = { kind = "block", open = "/*", close = "*/" },
  cs         = { kind = "block", open = "/*", close = "*/" },
  java       = { kind = "block", open = "/*", close = "*/" },
  javascript = { kind = "line", sym = "//" },
  typescript = { kind = "line", sym = "//" },
  rust       = { kind = "line", sym = "//" },
  go         = { kind = "line", sym = "//" },
  php        = { kind = "line", sym = "//" },
  sql        = { kind = "line", sym = "--" },
  haskell    = { kind = "line", sym = "--" },
  html       = { kind = "block", open = "<!--", close = "-->" },
  xml        = { kind = "block", open = "<!--", close = "-->" },
  markdown   = { kind = "block", open = "<!--", close = "-->" },
  tex        = { kind = "line", sym = "%" },
  latex      = { kind = "line", sym = "%" },
}

local DEFAULT_STYLE = { kind = "line", sym = "#" }

local FIELD_WIDTH = 15

local function label(text)
  return text .. string.rep(" ", FIELD_WIDTH - #text)
end

local function build_header(_, _)
  local ft = vim.bo.filetype
  local style = comment_styles[ft] or DEFAULT_STYLE

  local function wrap(line)
    if style.kind == "line" then
      if line == "" then
        return style.sym
      end
      return style.sym .. " " .. line
    else
      return line
    end
  end

  local nodes = {}

  if style.kind == "block" then
    table.insert(nodes, t(style.open))
    table.insert(nodes, t({ "", wrap(label("File:")) }))
  else
    table.insert(nodes, t(wrap(label("File:"))))
  end

  vim.list_extend(nodes, {
    f(get_filename, {}),
    t({ "", wrap(label("Author:")) }), i(1, "Miquéias Medeiros"),
    t({ "", wrap(label("Created:")) }), f(get_date, {}),
    t({ "", wrap(label("Modified:")) }), f(get_date, {}),
    t({ "", wrap(label("Description:")) }), i(2, "add description here"),
    t({ "", wrap("") }),
    t({ "", wrap("SPDX-License-Identifier: MIT") }),
    t({ "", wrap(label("Copyright:")) }), t("\194\169 "), f(get_year, {}), t(" "), rep(1), t(". All rights reserved."),
  })

  if style.kind == "block" then
    table.insert(nodes, t({ "", style.close, "", "" }))
  else
    table.insert(nodes, t({ "", "" }))
  end

  table.insert(nodes, i(0))

  return sn(nil, nodes)
end

return {
  s("head", { d(1, build_header, {}) }),
}
