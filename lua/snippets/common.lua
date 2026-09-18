-- lua/snippets/common.lua

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local rep = require("luasnip.extras").rep

local function get_date() return os.date("%Y-%m-%d") end
local function get_year() return os.date("%Y") end

local function get_filename()
  local name = vim.fn.expand("%:t")
  return name ~= "" and name or "untitled"
end

local function get_basename()
  local name = vim.fn.expand("%:t:r")
  return name ~= "" and name or "untitled"
end

local comment_styles = {
  lua        = { kind = "line", sym = "--" },
  sh         = { kind = "line", sym = "#" },
  bash       = { kind = "line", sym = "#" },
  zsh        = { kind = "line", sym = "#" },
  yaml       = { kind = "line", sym = "#" },
  toml       = { kind = "line", sym = "#" },
  vim        = { kind = "line", sym = '"' },
  zig        = { kind = "line", sym = "//" },
  scheme     = { kind = "line", sym = ";" },
  lisp       = { kind = "line", sym = ";" },
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

  -- Multi-line opener, no per-line prefix on content.
  python     = {
    kind = "docstring",
    open = { "#!/usr/bin/env python3", "# -*- coding: utf-8 -*-", '"""' },
    close = '"""',
  },
}

local DEFAULT_STYLE = { kind = "line", sym = "#" }

local FIELD_WIDTH = 15
local function label(text)
  return text .. string.rep(" ", math.max(1, FIELD_WIDTH - #text))
end

local function wrap(style, line)
  if style.kind == "line" then
    if line == "" then return style.sym end
    return style.sym .. " " .. line
  elseif style.kind == "block" then
    if line == "" then return " *" end
    return " * " .. line
  else -- No prefix at all
    return line
  end
end

-- Prefix used when a placeholder needs to start mid-line (no "label:" before it).
local function line_prefix(style)
  if style.kind == "line" then
    return style.sym .. " "
  elseif style.kind == "block" then
    return " * "
  else -- docstring / no prefix
    return ""
  end
end

local usage_by_ft = {
  c = function(style)
    return {
      t({ "", wrap(style, "    Compile:") }),
      t({ "", wrap(style, "    $ gcc -Wall -Wextra -Wpedantic -std=c23 ") }),
      f(get_filename, {}),
      t(" -o "),
      f(get_basename, {}),
      t({ "", wrap(style, ""), wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ ./") }),
      f(get_basename, {}),
    }
  end,
  cpp = function(style)
    return {
      t({ "", wrap(style, "    Compile:") }),
      t({ "", wrap(style, "    $ g++ -Wall -Wextra -Wpedantic -std=c++23 ") }),
      f(get_filename, {}),
      t(" -o "),
      f(get_basename, {}),
      t({ "", wrap(style, ""), wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ ./") }),
      f(get_basename, {}),
    }
  end,
  java = function(style)
    return {
      t({ "", wrap(style, "    Compile and run from the directory containing this file.") }),
      t({ "", wrap(style, ""), wrap(style, "    $ javac ") }),
      f(get_filename, {}),
      t({ "", wrap(style, "    $ java ") }),
      f(get_basename, {}),
    }
  end,
  python = function(style)
    return {
      t({ "", wrap(style, "    Run from the directory containing this file.") }),
      t({ "", wrap(style, ""), wrap(style, "    $ python ") }),
      f(get_filename, {}),
    }
  end,
  zig = function(style)
    return {
      t({ "", wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ zig run ") }),
      f(get_filename, {}),
    }
  end,
  scheme = function(style)
    return {
      t({ "", wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ mit-scheme --quiet --load ") }),
      f(get_filename, {}),
      t({ "", wrap(style, ""), wrap(style, "    To evaluate line by line, use ,ee and ,er in the REPL.") }),
    }
  end,
  javascript = function(style)
    return {
      t({ "", wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ node ") }),
      f(get_filename, {}),
    }
  end,
  typescript = function(style)
    return {
      t({ "", wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ npx ts-node ") }),
      f(get_filename, {}),
      t({ "", wrap(style, ""), wrap(style, "    Or compile then run:") }),
      t({ "", wrap(style, "    $ tsc ") }),
      f(get_filename, {}),
      t({ "", wrap(style, "    $ node ") }),
      f(get_basename, {}),
      t(".js"),
    }
  end,
  rust = function(style)
    return {
      t({ "", wrap(style, "    Compile:") }),
      t({ "", wrap(style, "    $ rustc ") }),
      f(get_filename, {}),
      t(" -o "),
      f(get_basename, {}),
      t({ "", wrap(style, ""), wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ ./") }),
      f(get_basename, {}),
    }
  end,
  go = function(style)
    return {
      t({ "", wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ go run ") }),
      f(get_filename, {}),
    }
  end,
  php = function(style)
    return {
      t({ "", wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ php ") }),
      f(get_filename, {}),
    }
  end,
  cs = function(style)
    return {
      t({ "", wrap(style, "    Run (single file, .NET 10+):") }),
      t({ "", wrap(style, "    $ dotnet run ") }),
      f(get_filename, {}),
    }
  end,
  haskell = function(style)
    return {
      t({ "", wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ runghc ") }),
      f(get_filename, {}),
      t({ "", wrap(style, ""), wrap(style, "    Or compile then run:") }),
      t({ "", wrap(style, "    $ ghc -o ") }),
      f(get_basename, {}),
      t(" "),
      f(get_filename, {}),
      t({ "", wrap(style, "    $ ./") }),
      f(get_basename, {}),
    }
  end,
  sh = function(style)
    return {
      t({ "", wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ chmod +x ") }),
      f(get_filename, {}),
      t({ "", wrap(style, "    $ ./") }),
      f(get_filename, {}),
    }
  end,
}
usage_by_ft.bash = usage_by_ft.sh
usage_by_ft.zsh = usage_by_ft.sh

-- Emits the opening marker(s) and, if needed, a line break before the
-- first field, depending on how many lines the opener itself takes.
local function open_and_first_line(add, style, first_line)
  if style.kind == "block" or style.kind == "docstring" then
    add(t(style.open))
    add(t({ "", wrap(style, first_line) }))
  else
    add(t(wrap(style, first_line)))
  end
end

local function close_header(add, style)
  if style.kind == "block" then
    add(t({ "", " " .. style.close, "", "" }))
  elseif style.kind == "docstring" then
    add(t({ "", style.close, "", "" }))
  else
    add(t({ "", "" }))
  end
end

local function build_head(_, _)
  local ft = vim.bo.filetype
  local style = comment_styles[ft] or DEFAULT_STYLE
  local nodes = {}
  local function add(...) for _, n in ipairs({ ... }) do table.insert(nodes, n) end end

  open_and_first_line(add, style, label("File:"))
  add(f(get_filename, {}))
  add(t({ "", wrap(style, label("Author:")) }))
  add(i(1, "Miquéias Alves Medeiros <https://github.com/miqu3iasg>"))
  add(t({ "", wrap(style, label("Created:")) }))
  add(f(get_date, {}))
  add(t({ "", wrap(style, label("Modified:")) }))
  add(f(get_date, {}))
  add(t({ "", wrap(style, label("By:")) }))
  add(i(2, "actual author(s) of the work"))
  add(t({ "", wrap(style, label("Reference:")) }))
  add(i(3, "title of the book/article"))
  add(t({ "", wrap(style, label("Location:")) }))
  add(i(4, "pages / section"))
  add(t({ "", wrap(style, ""), line_prefix(style) }))
  add(i(5, "add description here"))
  add(t({ "", wrap(style, ""), wrap(style, "SPDX-License-Identifier: AGPL-3.0-only") }))
  add(t({ "", wrap(style, label("Copyright:")) }))
  add(t("(c) "))
  add(f(get_year, {}))
  add(t(" "))
  add(rep(1))
  add(t("."))
  close_header(add, style)
  add(i(0))

  return sn(nil, nodes)
end

local function build_exs(_, _)
  local ft = vim.bo.filetype
  local style = comment_styles[ft] or DEFAULT_STYLE
  local usage_fn = usage_by_ft[ft]
  local nodes = {}
  local function add(...) for _, n in ipairs({ ... }) do table.insert(nodes, n) end end

  open_and_first_line(add, style, label("File:"))
  add(f(get_filename, {}))
  add(t({ "", wrap(style, label("Author:")) }))
  add(i(1, "Miquéias Medeiros <https://github.com/miqu3iasg>"))
  add(t({ "", wrap(style, label("Created:")) }))
  add(f(get_date, {}))
  add(t({ "", wrap(style, label("Modified:")) }))
  add(f(get_date, {}))
  add(t({ "", wrap(style, ""), line_prefix(style) }))
  add(i(2, "Longer description, if needed."))
  add(t({ "", wrap(style, ""), wrap(style, label("Problem Statement:")) }))
  add(t({ "", wrap(style, "    ") }))
  add(i(3, "Paste the exercise/assignment text here."))
  add(t({ "", wrap(style, ""), wrap(style, label("Usage:")) }))

  if usage_fn then
    for _, n in ipairs(usage_fn(style)) do add(n) end
  else
    add(t({ "", wrap(style, "    ") }))
    add(i(4, "how to compile/run this file"))
  end

  add(t({ "", wrap(style, ""), wrap(style, label("References:")) }))
  add(t({ "", wrap(style, "    - ") }))
  add(i(5, "https://..."))
  add(t({ "", wrap(style, ""), wrap(style, "SPDX-License-Identifier: AGPL-3.0-only") }))
  add(t({ "", wrap(style, label("Copyright:")) }))
  add(t("(c) "))
  add(f(get_year, {}))
  add(t(" "))
  add(rep(1))
  add(t("."))
  close_header(add, style)
  add(i(0))

  return sn(nil, nodes)
end

return {
  s("head", { d(1, build_head, {}) }),
  s("exs", { d(1, build_exs, {}) }),
}
