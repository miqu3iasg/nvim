-- snippets/common.lua

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

local C_BLOCK              = { kind = "block", open = "/*", close = "*/" }
local HTML_BLOCK           = { kind = "block", open = "<!--", close = "-->" }

-- File header comment style per filetype. A line style starts every line
-- with a symbol, a block style wraps the content in an opener and a closer,
-- and the docstring style (Python only) is a shebang, an encoding line and
-- an opening triple quote. Block styles can also set `mid`, the prefix of
-- each content line (default " * "), and `close_indent`, the whitespace
-- before the closer (default " "). Filetypes without a real block comment
-- stay on line comments, and lisp and scheme keep ";;;" because it is the
-- community convention for file metadata
local comment_styles       = {
  lua        = { kind = "block", open = "-" .. "-[" .. "[", close = "]" .. "]", mid = "  ", close_indent = "" },
  sh         = { kind = "line", sym = "#" },
  bash       = { kind = "line", sym = "#" },
  zsh        = { kind = "line", sym = "#" },
  yaml       = { kind = "line", sym = "#" },
  toml       = { kind = "line", sym = "#" },
  vim        = { kind = "line", sym = '"' },
  zig        = { kind = "line", sym = "//" },
  scheme     = { kind = "line", sym = ";;;" },
  lisp       = { kind = "line", sym = ";;;" },
  c          = C_BLOCK,
  cpp        = C_BLOCK,
  cs         = C_BLOCK,
  java       = C_BLOCK,
  javascript = C_BLOCK,
  typescript = C_BLOCK,
  rust       = C_BLOCK,
  go         = C_BLOCK,
  php        = C_BLOCK,
  sql        = C_BLOCK,
  kotlin     = C_BLOCK,
  haskell    = { kind = "block", open = "{-", close = "-}", mid = "  ", close_indent = "" },
  html       = HTML_BLOCK,
  xml        = HTML_BLOCK,
  markdown   = HTML_BLOCK,
  tex        = { kind = "line", sym = "%" },
  latex      = { kind = "line", sym = "%" },
  ruby       = { kind = "block", open = "=begin", close = "=end", mid = "", close_indent = "" },
  perl       = { kind = "line", sym = "#" },
  ps1        = { kind = "block", open = "<#", close = "#>", mid = "  ", close_indent = "" },
  python     = {
    kind = "docstring",
    open = { "#!/usr/bin/env python3", "# -*- coding: utf-8 -*-", '"""' },
    close = '"""',
  },
}

local DEFAULT_STYLE        = { kind = "line", sym = "#" }

-- Single-line comment symbol, for inline snippets that must stay on one
-- comment line even when the file header is a block comment.
local line_comment_by_ft   = {
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

-- Filetypes whose multi-line inline snippets (refs, drefs, cblock) use a
-- block comment. All others use consecutive line comments.
local inline_block_fts = {
  c = true,
  cpp = true,
  cs = true,
  java = true,
  html = true,
  xml = true,
  markdown = true,
}

local shebang_by_ft = {
  sh     = "#!/usr/bin/env sh",
  bash   = "#!/usr/bin/env bash",
  zsh    = "#!/usr/bin/env zsh",
  python = "#!/usr/bin/env python3",
  ruby   = "#!/usr/bin/env ruby",
  perl   = "#!/usr/bin/env perl",
  php    = "#!/usr/bin/env php",
}

local FIELD_WIDTH = 15

-- Pads a field name so header values line up in a column.
local function label(text)
  return text .. string.rep(" ", math.max(1, FIELD_WIDTH - #text))
end

-- Applies a comment style to one line of header content.
local function wrap(style, line)
  if style.kind == "line" then
    if line == "" then return style.sym end
    return style.sym .. " " .. line
  elseif style.kind == "block" then
    local mid = style.mid or " * "
    if line == "" then return (mid:gsub("%s+$", "")) end
    return mid .. line
  else
    return line
  end
end

-- Comment prefix for a line that starts with a placeholder, not a label.
local function line_prefix(style)
  if style.kind == "line" then
    return style.sym .. " "
  elseif style.kind == "block" then
    return style.mid or " * "
  else
    return ""
  end
end

-- Compile/run instructions for the `ehead` header.
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

-- Test-suite commands for the `thead` header. Unlike `usage_by_ft`, these
-- run the tests, not just the file.
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

-- Doc comments for `fnhead`, in each language's idiomatic format. These
-- build their own delimiters because the doc format dictates the syntax.
local doc_by_ft = {}

doc_by_ft.javascript = function()
  return {
    t({ "/**", " * " }), i(1, "Short description."),
    t({ "", " *", " * @param {" }), i(2, "type"), t("} "), i(3, "name"), t(" - "), i(4, "description"),
    t({ "", " * @returns {" }), i(5, "type"), t("} "), i(6, "description"),
    t({ "", " */" }),
  }
end
doc_by_ft.typescript = doc_by_ft.javascript

doc_by_ft.python = function()
  return {
    t('"""'), i(1, "Short description."),
    t({ "", "", "Args:" }),
    t({ "", "    " }), i(2, "name"), t(" ("), i(3, "type"), t("): "), i(4, "description."),
    t({ "", "", "Returns:" }),
    t({ "", "    " }), i(5, "type"), t(": "), i(6, "description."),
    t({ "", '"""' }),
  }
end

doc_by_ft.java = function()
  return {
    t({ "/**", " * " }), i(1, "Short description."),
    t({ "", " *", " * @param " }), i(2, "name"), t(" "), i(3, "description"),
    t({ "", " * @return " }), i(4, "description"),
    t({ "", " */" }),
  }
end
doc_by_ft.kotlin = doc_by_ft.java

doc_by_ft.c = function()
  return {
    t({ "/**", " * @brief " }), i(1, "Short description."),
    t({ "", " *", " * @param " }), i(2, "name"), t(" "), i(3, "description"),
    t({ "", " * @return " }), i(4, "description"),
    t({ "", " */" }),
  }
end
doc_by_ft.cpp = doc_by_ft.c

doc_by_ft.go = function()
  return {
    t("// "), i(1, "FuncName"), t(" "), i(2, "does X."),
    t({ "", "//", "// Parameters:" }),
    t({ "", "//   - " }), i(3, "name"), t(": "), i(4, "description"),
    t({ "", "//", "// Returns " }), i(5, "description."),
  }
end

doc_by_ft.rust = function()
  return {
    t("/// "), i(1, "Short description."),
    t({ "", "///", "/// # Arguments", "///", "/// * `" }), i(2, "name"), t("` - "), i(3, "description"),
    t({ "", "///", "/// # Returns", "///", "/// " }), i(4, "description"),
  }
end

doc_by_ft.php = function()
  return {
    t({ "/**", " * " }), i(1, "Short description."),
    t({ "", " *", " * @param " }), i(2, "type"), t(" $"), i(3, "name"), t(" "), i(4, "description"),
    t({ "", " * @return " }), i(5, "type"), t(" "), i(6, "description"),
    t({ "", " */" }),
  }
end

doc_by_ft.cs = function()
  return {
    t({ "/// <summary>", "/// " }), i(1, "Short description."),
    t({ "", "/// </summary>", '/// <param name="' }), i(2, "name"), t('">'), i(3, "description"), t("</param>"),
    t({ "", "/// <returns>" }), i(4, "description"), t("</returns>"),
  }
end

doc_by_ft.ruby = function()
  return {
    t("# "), i(1, "Short description."),
    t({ "", "#", "# @param " }), i(2, "name"), t(" ["), i(3, "Type"), t("] "), i(4, "description"),
    t({ "", "# @return [" }), i(5, "Type"), t("] "), i(6, "description"),
  }
end

-- Falls back to a one-line comment for filetypes without a doc format.
local function build_fnhead(_, _)
  local doc = doc_by_ft[vim.bo.filetype]
  if doc then
    local nodes = doc()
    table.insert(nodes, i(0))
    return sn(nil, nodes)
  end
  return sn(nil, {
    t(line_comment_sym(vim.bo.filetype) .. " "),
    i(1, "Short description."),
    i(0),
  })
end

-- Block and docstring styles need a line break after the opener.
local function open_and_first_line(add, style, first_line)
  if style.kind == "block" or style.kind == "docstring" then
    add(t(style.open))
    add(t({ "", wrap(style, first_line) }))
  else
    add(t(wrap(style, first_line)))
  end
end

-- Closes the header and adds a blank line before the code.
local function close_header(add, style)
  if style.kind == "block" then
    local indent = style.close_indent or " "
    add(t({ "", indent .. style.close, "", "" }))
  elseif style.kind == "docstring" then
    add(t({ "", style.close, "", "" }))
  else
    add(t({ "", "" }))
  end
end

-- `head`: File, Author, Created, Modified, Description. No license.
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

-- `shead`: for code written while studying a book or article. The license
-- is fixed to AGPL-3.0-only.
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

-- Trigger prefix -> SPDX identifier, for the `<prefix>head` snippets.
local licenses = {
  agpl    = "AGPL-3.0-only",
  gpl3    = "GPL-3.0-only",
  mit     = "MIT",
  apache2 = "Apache-2.0",
  bsd3    = "BSD-3-Clause",
  isc     = "ISC",
  mpl2    = "MPL-2.0",
}

-- Same as `head`, plus an SPDX line and a copyright notice.
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

-- `ahead`: proprietary header with an "All rights reserved." notice.
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

-- `ehead`: exercise header. `shead` fields plus a problem statement and
-- compile/run commands from `usage_by_ft`.
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
  add(t({ "", wrap(style, label("Source:")) }))
  add(i(2, "title of the book/article"))
  add(t({ "", wrap(style, label("By:")) }))
  add(i(3, "actual author(s) of the source material"))
  add(t({ "", wrap(style, label("Location:")) }))
  add(i(4, "chapter / pages / section"))
  add(t({ "", wrap(style, ""), line_prefix(style) }))
  add(i(5, "Longer description, if needed."))
  add(t({ "", wrap(style, ""), wrap(style, label("Problem Statement:")) }))
  add(t({ "", wrap(style, "    ") }))
  add(i(6, "Paste the exercise/assignment text here."))
  add(t({ "", wrap(style, ""), wrap(style, label("Usage:")) }))

  if usage_fn then
    for _, n in ipairs(usage_fn(style)) do add(n) end
  else
    add(t({ "", wrap(style, "    ") }))
    add(i(7, "how to compile/run this file"))
  end

  local refs_idx = usage_fn and 7 or 8

  add(t({ "", wrap(style, ""), wrap(style, label("References:")) }))
  add(t({ "", wrap(style, "    - ") }))
  add(i(refs_idx, "https://..."))
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

-- `thead`: test-file header with what is under test and the commands from
-- `test_usage_by_ft`.
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

local function inline_style(ft)
  local raw = comment_styles[ft]
  if raw and raw.kind == "block" and inline_block_fts[ft] then
    return raw
  end
  return { kind = "line", sym = line_comment_sym(ft) }
end

local function open_inline(add, style)
  if style.kind == "block" then
    add(t(style.open))
    add(t({ "", line_prefix(style) }))
  else
    add(t(line_prefix(style)))
  end
end

local function close_inline(add, style)
  if style.kind == "block" then
    add(t({ "", (style.close_indent or " ") .. style.close }))
  end
end

-- Opener and closer for a one-line comment. Languages with only a block
-- form (html, xml, markdown) get `<!-- ... -->`.
local function oneline_delims(ft)
  local sym = line_comment_by_ft[ft]
  if sym then
    return sym .. " ", ""
  end
  local raw = comment_styles[ft]
  if raw and raw.kind == "block" then
    return raw.open .. " ", " " .. raw.close
  end
  return DEFAULT_LINE_COMMENT .. " ", ""
end

-- Bare marker comment (`// TODO: `) with the cursor after the colon.
local function build_marker(text)
  return function(_, _)
    local pre, post = oneline_delims(vim.bo.filetype)
    local nodes = { t(pre .. text .. ": "), i(1) }
    if post ~= "" then table.insert(nodes, t(post)) end
    table.insert(nodes, i(0))
    return sn(nil, nodes)
  end
end

-- `spdx`: standalone SPDX line, without a full header.
local function build_spdx(_, _)
  local pre, post = oneline_delims(vim.bo.filetype)
  return sn(nil, {
    t(pre .. "SPDX-License-Identifier: "),
    i(1, "AGPL-3.0-only"),
    t(post),
    i(0),
  })
end

-- `chead`: smallest header (File, Created, Description) for scratch files.
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

local function build_shebang(_, _)
  local ft = vim.bo.filetype
  local line = shebang_by_ft[ft] or "#!/usr/bin/env sh"
  return sn(nil, { t(line), i(0) })
end

-- `see`: one-line reference, cursor ready to paste the link.
local function build_see(_, _)
  local sym = line_comment_sym(vim.bo.filetype)
  return sn(nil, {
    t(sym .. " See: "),
    i(1),
  })
end

local function build_mail(_, _)
  return sn(nil, { i(1, "contatomiqueiasalvesdev@gmail.com") })
end

local function build_gh(_, _)
  return sn(nil, { i(1, "https://github.com/miqu3iasg") })
end

-- `refs`: list of references, one bullet per source.
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

-- `drefs`: description plus references, for borrowed code where the reason
-- it was kept matters.
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

local snippets = {
  s("head", { d(1, build_head, {}) }),
  s("shead", { d(1, build_study, {}) }),
  s("ahead", { d(1, build_allhead, {}) }),
  s("thead", { d(1, build_testhead, {}) }),
  s("chead", { d(1, build_scratch, {}) }),
  s("ehead", { d(1, build_exs, {}) }),
  s("fnhead", { d(1, build_fnhead, {}) }),
  s("shebang", { d(1, build_shebang, {}) }),
  s("see", { d(1, build_see, {}) }),
  s("refs", { d(1, build_refs, {}) }),
  s("drefs", { d(1, build_snip, {}) }),
  s("spdx", { d(1, build_spdx, {}) }),
  s("mail", { d(1, build_mail, {}) }),
  s("gh", { d(1, build_gh, {}) }),
  s("author", { i(1, "Miquéias Alves Medeiros <https://github.com/miqu3iasg>") }),
}

local markers = {
  todo  = "TODO",
  fixme = "FIXME",
  note  = "NOTE",
  hack  = "HACK",
  xxx   = "XXX",
  bug   = "BUG",
  warn  = "WARNING",
  perf  = "PERF",
  depr  = "DEPRECATED",
}

for trigger, text in pairs(markers) do
  table.insert(snippets, s(trigger, { d(1, build_marker(text), {}) }))
end

for key, spdx in pairs(licenses) do
  table.insert(snippets, s(key .. "head", { d(1, build_licensed_head(spdx), {}) }))
end

return snippets
