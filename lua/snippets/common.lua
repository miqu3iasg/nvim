-- lua/snippets/common.lua

local ls  = require("luasnip")
local s   = ls.snippet
local t   = ls.text_node
local i   = ls.insert_node
local f   = ls.function_node
local d   = ls.dynamic_node
local sn  = ls.snippet_node
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

-- Comment style used for file headers, per filetype. "line" prefixes every
-- line with a symbol; "block" wraps content in an open/close pair; "docstring"
-- is a multi-line opener with no per-line prefix (used only by Python).
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
  ruby       = { kind = "line", sym = "#" },
  kotlin     = { kind = "line", sym = "//" },
  perl       = { kind = "line", sym = "#" },
  ps1        = { kind = "line", sym = "#" },

  -- Shebang + encoding line + opening triple-quote; closed by `close` below.
  python     = {
    kind = "docstring",
    open = { "#!/usr/bin/env python3", "# -*- coding: utf-8 -*-", '"""' },
    close = '"""',
  },
}

local DEFAULT_STYLE = { kind = "line", sym = "#" }

-- Single-line comment symbol per filetype. Used by inline snippets
-- (TODO, FIXME, attribution comments) that must stay on one comment line
-- even in languages whose file-header style above uses a block comment
-- (c, cpp, java).
local line_comment_by_ft = {
  lua        = "--",
  sh         = "#",
  bash       = "#",
  zsh        = "#",
  yaml       = "#",
  toml       = "#",
  vim        = '"',
  zig        = "//",
  scheme     = ";",
  lisp       = ";",
  c          = "//",
  cpp        = "//",
  cs         = "//",
  java       = "//",
  javascript = "//",
  typescript = "//",
  rust       = "//",
  go         = "//",
  php        = "//",
  sql        = "--",
  haskell    = "--",
  tex        = "%",
  latex      = "%",
  python     = "#",
  ruby       = "#",
  kotlin     = "//",
  perl       = "#",
  ps1        = "#",
}
local DEFAULT_LINE_COMMENT = "#"

local function line_comment_sym(ft)
  return line_comment_by_ft[ft] or DEFAULT_LINE_COMMENT
end

local FIELD_WIDTH = 15

-- Pads a field name to a fixed width so header values line up in a column.
local function label(text)
  return text .. string.rep(" ", math.max(1, FIELD_WIDTH - #text))
end

-- Applies a comment style to one line of header content.
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

-- Comment prefix for a line that starts with a placeholder instead of a
-- "Label:" field.
local function line_prefix(style)
  if style.kind == "line" then
    return style.sym .. " "
  elseif style.kind == "block" then
    return " * "
  else -- docstring / no prefix
    return ""
  end
end

-- Compile/run instructions per filetype, used by the `exs` header.
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
  ruby = function(style)
    return {
      t({ "", wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ ruby ") }),
      f(get_filename, {}),
    }
  end,
  kotlin = function(style)
    return {
      t({ "", wrap(style, "    Compile:") }),
      t({ "", wrap(style, "    $ kotlinc ") }),
      f(get_filename, {}),
      t(" -include-runtime -d "),
      f(get_basename, {}),
      t(".jar"),
      t({ "", wrap(style, ""), wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ java -jar ") }),
      f(get_basename, {}),
      t(".jar"),
    }
  end,
  perl = function(style)
    return {
      t({ "", wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ perl ") }),
      f(get_filename, {}),
    }
  end,
  ps1 = function(style)
    return {
      t({ "", wrap(style, "    Run:") }),
      t({ "", wrap(style, "    $ pwsh -File ") }),
      f(get_filename, {}),
    }
  end,
}
usage_by_ft.bash = usage_by_ft.sh
usage_by_ft.zsh = usage_by_ft.sh

-- Test-runner commands per filetype, used by the `testhead` header. Unlike
-- `usage_by_ft` above, these run the test suite (pytest, cargo test, mvn
-- test, and so on), not just the file itself.
local test_usage_by_ft = {
  c = function(style)
    return {
      t({ "", wrap(style, "    Plain, compiled test binary:") }),
      t({ "", wrap(style, "    $ gcc -Wall -Wextra -Wpedantic -std=c23 ") }),
      f(get_filename, {}),
      t(" -o "),
      f(get_basename, {}),
      t({ "", wrap(style, "    $ ./") }),
      f(get_basename, {}),
      t({ "", wrap(style, ""), wrap(style, "    If using a framework (Unity, Criterion, cmocka), use its runner instead.") }),
    }
  end,
  cpp = function(style)
    return {
      t({ "", wrap(style, "    With CTest (GoogleTest/Catch2 registered via CMake):") }),
      t({ "", wrap(style, "    $ ctest --test-dir build") }),
      t({ "", wrap(style, ""), wrap(style, "    Or compiled directly against GoogleTest:") }),
      t({ "", wrap(style, "    $ g++ -std=c++23 ") }),
      f(get_filename, {}),
      t(" -lgtest -lgtest_main -pthread -o "),
      f(get_basename, {}),
      t({ "", wrap(style, "    $ ./") }),
      f(get_basename, {}),
    }
  end,
  java = function(style)
    return {
      t({ "", wrap(style, "    Maven:") }),
      t({ "", wrap(style, "    $ mvn test") }),
      t({ "", wrap(style, ""), wrap(style, "    Gradle:") }),
      t({ "", wrap(style, "    $ gradle test") }),
    }
  end,
  python = function(style)
    return {
      t({ "", wrap(style, "    $ pytest ") }),
      f(get_filename, {}),
      t({ "", wrap(style, "    $ pytest -v ") }),
      f(get_filename, {}),
    }
  end,
  javascript = function(style)
    return {
      t({ "", wrap(style, "    $ npx jest ") }),
      f(get_filename, {}),
      t({ "", wrap(style, ""), wrap(style, "    Or, if configured as the project's test script:") }),
      t({ "", wrap(style, "    $ npm test") }),
    }
  end,
  typescript = function(style)
    return {
      t({ "", wrap(style, "    $ npx jest ") }),
      f(get_filename, {}),
      t({ "", wrap(style, ""), wrap(style, "    Or, if configured as the project's test script:") }),
      t({ "", wrap(style, "    $ npm test") }),
    }
  end,
  rust = function(style)
    return {
      t({ "", wrap(style, "    $ cargo test") }),
    }
  end,
  go = function(style)
    return {
      t({ "", wrap(style, "    $ go test ./...") }),
    }
  end,
  php = function(style)
    return {
      t({ "", wrap(style, "    $ vendor/bin/phpunit ") }),
      f(get_filename, {}),
    }
  end,
  cs = function(style)
    return {
      t({ "", wrap(style, "    $ dotnet test") }),
    }
  end,
  haskell = function(style)
    return {
      t({ "", wrap(style, "    Stack:") }),
      t({ "", wrap(style, "    $ stack test") }),
      t({ "", wrap(style, ""), wrap(style, "    Cabal:") }),
      t({ "", wrap(style, "    $ cabal test") }),
    }
  end,
  zig = function(style)
    return {
      t({ "", wrap(style, "    $ zig test ") }),
      f(get_filename, {}),
    }
  end,
  sh = function(style)
    return {
      t({ "", wrap(style, "    With bats-core:") }),
      t({ "", wrap(style, "    $ bats ") }),
      f(get_filename, {}),
    }
  end,
  ruby = function(style)
    return {
      t({ "", wrap(style, "    RSpec:") }),
      t({ "", wrap(style, "    $ bundle exec rspec ") }),
      f(get_filename, {}),
      t({ "", wrap(style, ""), wrap(style, "    Minitest:") }),
      t({ "", wrap(style, "    $ ruby -Itest ") }),
      f(get_filename, {}),
    }
  end,
  kotlin = function(style)
    return {
      t({ "", wrap(style, "    Gradle:") }),
      t({ "", wrap(style, "    $ gradle test") }),
      t({ "", wrap(style, ""), wrap(style, "    Maven:") }),
      t({ "", wrap(style, "    $ mvn test") }),
    }
  end,
  perl = function(style)
    return {
      t({ "", wrap(style, "    With Test::More, via prove:") }),
      t({ "", wrap(style, "    $ prove ") }),
      f(get_filename, {}),
    }
  end,
  ps1 = function(style)
    return {
      t({ "", wrap(style, "    Pester:") }),
      t({ "", wrap(style, "    $ Invoke-Pester ") }),
      f(get_filename, {}),
    }
  end,
}
test_usage_by_ft.bash = test_usage_by_ft.sh
test_usage_by_ft.zsh = test_usage_by_ft.sh

-- Emits the header opener and the first field. Block and docstring styles
-- need a line break between the opener and the first field; a line style
-- doesn't.
local function open_and_first_line(add, style, first_line)
  if style.kind == "block" or style.kind == "docstring" then
    add(t(style.open))
    add(t({ "", wrap(style, first_line) }))
  else
    add(t(wrap(style, first_line)))
  end
end

-- Emits the header closer and a blank line to separate the header from
-- the code that follows.
local function close_header(add, style)
  if style.kind == "block" then
    add(t({ "", " " .. style.close, "", "" }))
  elseif style.kind == "docstring" then
    add(t({ "", style.close, "", "" }))
  else
    add(t({ "", "" }))
  end
end

-- `head`: minimal, license-free header. File, Author, Created, Modified,
-- Description. Use this when a full license block is overkill.
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
  add(t({ "", wrap(style, ""), line_prefix(style) }))
  add(i(2, "add description here"))
  close_header(add, style)
  add(i(0))

  return sn(nil, nodes)
end

-- `studyhead`: header for code written while studying a book or article.
-- File, Author, Created, Modified, Source, By, Location, Description,
-- SPDX-License-Identifier, Copyright. Hardcoded to AGPL-3.0-only, the
-- license used for this kind of file; unlike `<license>head` below, this
-- isn't meant to be generated per license.
local function build_study(_, _)
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
  add(t({ "", wrap(style, label("Source:")) }))
  add(i(2, "title of the book/article"))
  add(t({ "", wrap(style, label("By:")) }))
  add(i(3, "actual author(s) of the source material"))
  add(t({ "", wrap(style, label("Location:")) }))
  add(i(4, "chapter / pages / section"))
  add(t({ "", wrap(style, ""), line_prefix(style) }))
  add(i(5, "what you implemented / learned here"))
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

-- Attribution comments (see, refs, snip): none of these are file headers.
-- They're dropped inline, above or inside a block of code borrowed or
-- adapted from elsewhere, in increasing order of detail.

local licenses = {
  agpl    = "AGPL-3.0-only",
  gpl3    = "GPL-3.0-only",
  mit     = "MIT",
  apache2 = "Apache-2.0",
  bsd3    = "BSD-3-Clause",
  isc     = "ISC",
  mpl2    = "MPL-2.0",
}

-- Builds a header snippet for the given SPDX license identifier: File,
-- Author, Created, Modified, Description, SPDX-License-Identifier, and
-- Copyright. Study-specific fields (Source, By, Location) live in
-- `studyhead` instead.
local function build_licensed_head(spdx)
  return function(_, _)
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
    add(t({ "", wrap(style, ""), line_prefix(style) }))
    add(i(2, "add description here"))
    add(t({ "", wrap(style, ""), wrap(style, "SPDX-License-Identifier: " .. spdx) }))
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
end

-- `allhead`: proprietary header, no open license. File, Author, Created,
-- Modified, Description, Copyright. Uses the standard "All rights
-- reserved." notice instead of an SPDX identifier.
local function build_allhead(_, _)
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
  add(t({ "", wrap(style, ""), line_prefix(style) }))
  add(i(2, "add description here"))
  add(t({ "", wrap(style, ""), wrap(style, label("Copyright:")) }))
  add(t("(c) "))
  add(f(get_year, {}))
  add(t(" "))
  add(rep(1))
  add(t(". All rights reserved."))
  close_header(add, style)
  add(i(0))

  return sn(nil, nodes)
end

-- `exs`: exercise/assignment header. Adds a Problem Statement and a
-- Usage section (compile/run commands from `usage_by_ft`) on top of the
-- standard File/Author/Created/Modified/Description fields.
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

-- `testhead`: test-file header. States what's under test and how to run
-- the test suite (real test-runner commands from `test_usage_by_ft`).
local function build_testhead(_, _)
  local ft = vim.bo.filetype
  local style = comment_styles[ft] or DEFAULT_STYLE
  local usage_fn = test_usage_by_ft[ft]
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
  add(t({ "", wrap(style, label("Testing:")) }))
  add(i(2, "module / function / behavior under test"))
  add(t({ "", wrap(style, ""), line_prefix(style) }))
  add(i(3, "setup notes, mocks, fixtures, etc."))
  add(t({ "", wrap(style, ""), wrap(style, label("Run:")) }))

  if usage_fn then
    for _, n in ipairs(usage_fn(style)) do add(n) end
  else
    add(t({ "", wrap(style, "    ") }))
    add(i(4, "how to run this test file"))
  end

  close_header(add, style)
  add(i(0))

  return sn(nil, nodes)
end

-- Comment style for a short inline comment (TODO, FIXME, attribution).
-- Languages with a genuine block-comment form (C, C++, C#, Java, HTML,
-- XML, Markdown) get that form; everything else falls back to its
-- single-line comment symbol.
local function inline_style(ft)
  local raw = comment_styles[ft]
  if raw and raw.kind == "block" then
    return raw
  end
  return { kind = "line", sym = line_comment_sym(ft) }
end

-- Opens an inline comment that starts with a placeholder rather than a
-- fixed label.
local function open_inline(add, style)
  if style.kind == "block" then
    add(t(style.open))
    add(t({ "", line_prefix(style) }))
  else
    add(t(line_prefix(style)))
  end
end

-- Closes a block-style inline comment. Line-style comments need no closer.
local function close_inline(add, style)
  if style.kind == "block" then
    add(t({ "", " " .. style.close }))
  end
end

-- `fixme`: FIXME with a second line for context on what's broken and why.
-- A single block comment for languages that have one; a line comment
-- otherwise.
local function build_fixme(_, _)
  local style = inline_style(vim.bo.filetype)
  local nodes = {}
  local function add(...) for _, n in ipairs({ ... }) do table.insert(nodes, n) end end

  open_inline(add, style)
  add(t("FIXME: "))
  add(i(1, "short description"))
  add(t({ "", wrap(style, "  ") }))
  add(i(2, "context, if needed"))
  close_inline(add, style)

  return sn(nil, nodes)
end

-- `todo`: TODO with a second line for context. Same block/line handling
-- as `fixme`.
local function build_todo(_, _)
  local style = inline_style(vim.bo.filetype)
  local nodes = {}
  local function add(...) for _, n in ipairs({ ... }) do table.insert(nodes, n) end end

  open_inline(add, style)
  add(t("TODO: "))
  add(i(1, "short description"))
  add(t({ "", wrap(style, "  ") }))
  add(i(2, "context, if needed"))
  close_inline(add, style)

  return sn(nil, nodes)
end

-- `scratch`: smallest header, for throwaway or exploratory files. Just
-- File, Created, and Description.
local function build_scratch(_, _)
  local ft = vim.bo.filetype
  local style = comment_styles[ft] or DEFAULT_STYLE
  local nodes = {}
  local function add(...) for _, n in ipairs({ ... }) do table.insert(nodes, n) end end

  open_and_first_line(add, style, label("File:"))
  add(f(get_filename, {}))
  add(t({ "", wrap(style, label("Created:")) }))
  add(f(get_date, {}))
  add(t({ "", wrap(style, ""), line_prefix(style) }))
  add(i(1, "quick scratch / throwaway notes"))
  close_header(add, style)
  add(i(0))

  return sn(nil, nodes)
end

-- `see`: single line, single reference. `-- See: <url>`
local function build_see(_, _)
  local sym = line_comment_sym(vim.bo.filetype)
  return sn(nil, {
    t(sym .. " See: "),
    i(1, "https://..."),
  })
end

-- `refs`: bullet list of references, no description. Copy the bullet
-- line to add more sources. Block comment where the language has one,
-- line comment otherwise.
local function build_refs(_, _)
  local style = inline_style(vim.bo.filetype)
  local nodes = {}
  local function add(...) for _, n in ipairs({ ... }) do table.insert(nodes, n) end end

  open_inline(add, style)
  add(t("References:"))
  add(t({ "", wrap(style, "  - ") }))
  add(i(1, "https://..."))
  close_inline(add, style)
  add(i(0))

  return sn(nil, nodes)
end

-- description plus reference(s). Use when the reason the snippet
-- was kept matters as much as where it came from. Deliberately excludes
-- filename and tags, which belong to the file, not to a borrowed snippet
-- sitting mid-function. Block comment where the language has one, line
-- comment otherwise.
local function build_snip(_, _)
  local style = inline_style(vim.bo.filetype)
  local nodes = {}
  local function add(...) for _, n in ipairs({ ... }) do table.insert(nodes, n) end end

  open_inline(add, style)
  add(i(1, "what this snippet does / why it was kept"))
  add(t({ "", wrap(style, "References:") }))
  add(t({ "", wrap(style, "  - ") }))
  add(i(2, "https://..."))
  close_inline(add, style)
  add(i(0))

  return sn(nil, nodes)
end

-- ASCII art signature. Purely decorative — drop the art
-- commented according to the language's inline style (block style when
-- applicable, line style otherwise).
local arts = {
  ascii_name = {
    [[▄▄▄▄ ▄▄  ▄▄  ▄▄▄  ▄▄ ▄▄ ▄▄▄▄▄ ▄▄  ▄▄▄▄  ▄▄▄▄  ▄▄▄▄]],
    [[░█ ░█ ░█ ▄▄ ░█ ░█ ░█ ░█ ░█ ░█ ▄▄ ░█ ░█ ░█ ▀▀ ░█ ░█]],
    [[▒█ ▒█ ▒█ ▒█ ▒█ ░█ ▒█ ░█   ▄▒█ ▒█ ▒█ ░█  ▀▀░▄ ▒█ ░█]],
    [[▓▓ ▓▓ ▓▓ ▓▓ ▓▓ ▓░ ▓▓ ▓░ ▒░ ▓▓ ▓▓ ▓▓ ▓░ ░█ ▓░ ▀▀▀░█]],
    [[▀▀ ▀▀ ▀▀ ▀▀  ▀▀▒█ ▀▀▀▀▀ ▀▀▀▀▀ ▀▀  ▀▀▀▀ ▀▀▀▀  ░█ ▓░]],
    [[               ▀▀                             ▀▀▀▀]],
  },

  line_name = {
    [[    __  ____            _____ _]],
    [[   /  |/  (_)___ ___  _|__  /(_)___ __________ _]],
    [[  / /|_/ / / __ `/ / / //_ </ / __ `/ ___/ __ `/]],
    [[ / /  / / / /_/ / /_/ /__/ / / /_/ (__  ) /_/ /]],
    [[/_/  /_/_/\__, /\__,_/____/_/\__,_/____/\__, /]],
    [[            /_/                        /____/]],
  },

  morse = {
    [[-- .. --.- ..- . .. .- ... --. ]],
  },

  binary = {
    [[01101101 01101001 01110001 01110101 01100101 01101001 01100001 01110011 01100111]],
  },
}

local miq_art = arts.morse

local function build_miq(_, _)
  local style = inline_style(vim.bo.filetype)
  local nodes = {}
  local function add(...) for _, n in ipairs({ ... }) do table.insert(nodes, n) end end

  if style.kind == "block" then add(t(style.open)) end

  for idx, line in ipairs(miq_art) do
    if idx == 1 and style.kind ~= "block" then
      add(t(wrap(style, line)))
    else
      add(t({ "", wrap(style, line) }))
    end
  end

  close_inline(add, style)
  add(i(0))

  return sn(nil, nodes)
end

-- Snippet registration. Licensed headers are appended below by iterating
-- over `licenses`.
local snippets = {
  s("head", { d(1, build_head, {}) }),
  s("shead", { d(1, build_study, {}) }),
  s("ahead", { d(1, build_allhead, {}) }),
  s("thead", { d(1, build_testhead, {}) }),
  s("chead", { d(1, build_scratch, {}) }),
  s("ehead", { d(1, build_exs, {}) }),
  s("fixme", { d(1, build_fixme, {}) }),
  s("todo", { d(1, build_todo, {}) }),
  s("see", { d(1, build_see, {}) }),
  s("refs", { d(1, build_refs, {}) }),
  s("drefs", { d(1, build_snip, {}) }),
  s("miq", { d(1, build_miq, {}) }),
}

for key, spdx in pairs(licenses) do
  table.insert(snippets, s(key .. "head", { d(1, build_licensed_head(spdx), {}) }))
end

return snippets
