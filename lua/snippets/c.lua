local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local c = ls.choice_node

local function get_date()
  return os.date("%Y-%m-%d")
end

local function get_year()
  return os.date("%Y")
end

local function get_filename()
  local name = vim.fn.expand("%:t")
  return name ~= "" and name or "untitled.c"
end

local function get_basename()
  local name = vim.fn.expand("%:t:r")
  return name ~= "" and name or "untitled"
end

local FIELD_WIDTH = 15

local function label(text)
  return text .. string.rep(" ", math.max(1, FIELD_WIDTH - #text))
end

local function build_header(_, _)
  local nodes = {
    t({
      "/*",
      " * " .. label("File:"),
    }),
    f(get_filename, {}),
    t({ "", " * " .. label("Author:") }),
    i(1, "Miquéias Medeiros"),
    t({ "", " * " .. label("Created:") }),
    f(get_date, {}),
    t({ "", " * " .. label("Modified:") }),
    f(get_date, {}),
    t({ "", " *", " * " .. label("Description:") }),
    t({ "", " *     " }),
    i(2, "Longer description, if needed."),
    t({ "", " *", " * " .. label("Problem Statement:") }),
    t({ "", " *     " }),
    i(3, "Paste the exercise/assignment text here."),
    t({ "", " *", " * " .. label("Usage:") }),
    t({
      "",
      " *     Compile:",
      " *     $ gcc -Wall -Wextra -Wpedantic -std=c23 ",
    }),
    f(get_filename, {}),
    t({ " -o " }),
    f(get_basename, {}),
    t({ "", " *", " *     Run:" }),
    t({ "", " *     $ ./" }),
    f(get_basename, {}),
    t({ "", " *", " * " .. label("References:") }),
    t({ "", " *     - " }),
    i(4, "https://..."),
    t({ "", " *", " * SPDX-License-Identifier: MIT" }),
    t({ "", " * " .. label("Copyright:") }),
    t("\194\169 "),
    f(get_year, {}),
    t(" All rights reserved."),
    t({ "", " */", "" }),
    i(0),
  }

  return sn(nil, nodes)
end

-- Solution scaffolding for practice problems (LeetCode, Kattis, HackerRank, etc.)
-- Unlike Java, C has no class to keep in sync with the filename, so this is
-- just a `solve` function plus an `int main` that calls it and prints the
-- result — trivial to strip the `main`/printf when pasting into a judge.
local function build_sol_with_header(_, _)
  local nodes = {
    d(1, build_header, {}),
    t({ "", "", "#include <stdio.h>", "", "" }),
    i(2, "int"),
    t(" solve("),
    i(3, "int n"),
    t({ ") {", "\t" }),
    i(4, "// TODO: implement"),
    t({ "", "}", "", "int main(void) {" }),
    t({ "", "\tprintf(\"%d\\n\", solve(" }),
    i(5, "/* args */"),
    t({ "));", "\treturn 0;", "}" }),
    i(0),
  }

  return sn(nil, nodes)
end

-- "ivm" scaffolding (basic #include <stdio.h> + int main) prefixed with the
-- standard file header. Same idea as build_sol_with_header, but for a plain
-- main instead of the solve()/main() judge scaffold.
local function build_ivm_with_header(_, _)
  local nodes = {
    d(1, build_header, {}),
    t({
      "",
      "",
      "#include <stdio.h>",
      "",
      "int main(void) {",
      "    ",
    }),
    i(2),
    t({ "", "", "    return 0;", "}" }),
  }

  return sn(nil, nodes)
end

return {
  -- Control flow

  s("if", {
    t("if ("),
    i(1, "condition"),
    t({ ") {", "    " }),
    i(2),
    t({ "", "}" }),
  }),

  s("ife", {
    t("if ("),
    i(1, "condition"),
    t({ ") {", "    " }),
    i(2),
    t({ "", "} else {", "    " }),
    i(3),
    t({ "", "}" }),
  }),

  s("elif", {
    t("if ("),
    i(1, "condition"),
    t({ ") {", "    " }),
    i(2),
    t({ "", "} else if (" }),
    i(3, "condition"),
    t({ ") {", "    " }),
    i(4),
    t({ "", "} else {", "    " }),
    i(5),
    t({ "", "}" }),
  }),

  s("for", {
    t("for (int "),
    i(1, "i"),
    t(" = 0; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" < "),
    i(2, "n"),
    t("; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("++) {"),
    t({ "", "    " }),
    i(3),
    t({ "", "}" }),
  }),

  s("forr", {
    t("for (int "),
    i(1, "i"),
    t(" = "),
    i(2, "n - 1"),
    t("; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" >= 0; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("--) {"),
    t({ "", "    " }),
    i(3),
    t({ "", "}" }),
  }),

  s("for2", {
    t("for (int "),
    i(1, "i"),
    t(" = 0; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" < "),
    i(2, "n"),
    t("; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" += 2) {"),
    t({ "", "    " }),
    i(3),
    t({ "", "}" }),
  }),

  s("forhalf", {
    t("for (int "),
    i(1, "i"),
    t(" = 0; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" < "),
    i(2, "n"),
    t(" / 2; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("++) {"),
    t({ "", "    " }),
    i(3),
    t({ "", "}" }),
  }),

  s("foreach", {
    t("for (size_t "),
    i(1, "i"),
    t(" = 0; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" < "),
    i(2, "length"),
    t("; "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("++) {"),
    t({ "", "    " }),
    i(3),
    t({ "", "}" }),
  }),

  s("while", {
    t("while ("),
    i(1, "condition"),
    t({ ") {", "    " }),
    i(2),
    t({ "", "}" }),
  }),

  s("dowhile", {
    t({ "do {", "    " }),
    i(1),
    t({ "", "} while (" }),
    i(2, "condition"),
    t(");"),
  }),

  s("switch", {
    t("switch ("),
    i(1, "expression"),
    t({ ") {", "    case " }),
    i(2, "value"),
    t({ ":", "        " }),
    i(3),
    t({ "", "        break;", "    default:", "        " }),
    i(4),
    t({ "", "        break;", "}" }),
  }),

  s("case", {
    t("case "),
    i(1, "value"),
    t({ ":", "    " }),
    i(2),
    t({ "", "    break;" }),
  }),

  s("break", {
    t("break;"),
  }),

  s("continue", {
    t("continue;"),
  }),

  -- Functions

  s("fn", {
    i(1, "int"),
    t(" "),
    i(2, "function"),
    t("("),
    i(3, "void"),
    t({ ") {", "    " }),
    i(4),
    t({ "", "}" }),
  }),

  s("fnp", {
    i(1, "int"),
    t(" "),
    i(2, "function"),
    t("("),
    i(3, "int value"),
    t({ ") {", "    " }),
    i(4),
    t({ "", "}" }),
  }),

  s("fnptr", {
    i(1, "return_type"),
    t(" (*"),
    i(2, "function"),
    t(")("),
    i(3, "parameters"),
    t(");"),
  }),

  s("inline", {
    t("static inline "),
    i(1, "int"),
    t(" "),
    i(2, "function"),
    t("("),
    i(3, "void"),
    t({ ") {", "    " }),
    i(4),
    t({ "", "}" }),
  }),

  -- Main

  s("main", {
    t({ "int main(void) {", "    " }),
    i(1),
    t({ "", "", "    return 0;", "}" }),
  }),

  s("mainargs", {
    t({ "int main(int argc, char *argv[]) {", "    " }),
    i(1),
    t({ "", "", "    return 0;", "}" }),
  }),

  s("ivm", {
    t({
      "#include <stdio.h>",
      "",
      "int main(void) {",
      "    ",
    }),
    i(1),
    t({ "", "", "    return 0;", "}" }),
  }),

  s("ivmh", {
    d(1, build_ivm_with_header, {}),
  }),

  -- Variables

  s("var", {
    i(1, "int"),
    t(" "),
    i(2, "variable"),
    t(" = "),
    i(3, "value"),
    t(";"),
  }),

  s("const", {
    t("const "),
    i(1, "int"),
    t(" "),
    i(2, "variable"),
    t(" = "),
    i(3, "value"),
    t(";"),
  }),

  s("static", {
    t("static "),
    i(1, "int"),
    t(" "),
    i(2, "variable"),
    t(";"),
  }),

  s("staticconst", {
    t("static const "),
    i(1, "int"),
    t(" "),
    i(2, "CONSTANT"),
    t(" = "),
    i(3, "value"),
    t(";"),
  }),

  -- Arrays

  s("arr", {
    i(1, "int"),
    t(" "),
    i(2, "array"),
    t("["),
    i(3, "size"),
    t("];"),
  }),

  s("arrn", {
    i(1, "int"),
    t(" "),
    i(2, "array"),
    t("[n];"),
  }),

  s("arrinit", {
    i(1, "int"),
    t(" "),
    i(2, "array"),
    t("[] = {"),
    i(3, "1, 2, 3"),
    t("};"),
  }),

  s("arr2", {
    i(1, "int"),
    t(" "),
    i(2, "matrix"),
    t("["),
    i(3, "rows"),
    t("]["),
    i(4, "cols"),
    t("];"),
  }),

  s("len", {
    t("sizeof("),
    i(1, "array"),
    t(") / sizeof("),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("[0])"),
  }),

  s("size", {
    t("sizeof("),
    i(1, "variable"),
    t(")"),
  }),

  -- Strings

  s("str", {
    t("char "),
    i(1, "string"),
    t("["),
    i(2, "size"),
    t("];"),
  }),

  s("strinit", {
    t("char "),
    i(1, "string"),
    t("[] = \""),
    i(2, "text"),
    t("\";"),
  }),

  s("strlen", {
    t("strlen("),
    i(1, "string"),
    t(")"),
  }),

  s("strcmp", {
    t("strcmp("),
    i(1, "str1"),
    t(", "),
    i(2, "str2"),
    t(")"),
  }),

  s("strncmp", {
    t("strncmp("),
    i(1, "str1"),
    t(", "),
    i(2, "str2"),
    t(", "),
    i(3, "n"),
    t(")"),
  }),

  s("strcpy", {
    t("strcpy("),
    i(1, "destination"),
    t(", "),
    i(2, "source"),
    t(");"),
  }),

  s("strncpy", {
    t("strncpy("),
    i(1, "destination"),
    t(", "),
    i(2, "source"),
    t(", "),
    i(3, "n"),
    t(");"),
  }),

  s("strcat", {
    t("strcat("),
    i(1, "destination"),
    t(", "),
    i(2, "source"),
    t(");"),
  }),

  s("strchr", {
    t("strchr("),
    i(1, "string"),
    t(", '"),
    i(2, "c"),
    t("')"),
  }),

  s("strstr", {
    t("strstr("),
    i(1, "string"),
    t(", \""),
    i(2, "substring"),
    t("\")"),
  }),

  -- Pointers

  s("ptr", {
    i(1, "int"),
    t(" *"),
    i(2, "ptr"),
    t(";"),
  }),

  s("ptrinit", {
    i(1, "int"),
    t(" *"),
    i(2, "ptr"),
    t(" = &"),
    i(3, "variable"),
    t(";"),
  }),

  s("addr", {
    t("&"),
    i(1, "variable"),
  }),

  s("deref", {
    t("*"),
    i(1, "ptr"),
  }),

  s("null", {
    t("NULL"),
  }),

  s("nullptr", {
    t("NULL"),
  }),

  s("ptrcheck", {
    t("if ("),
    i(1, "ptr"),
    t({ " == NULL) {", "    " }),
    i(2),
    t({ "", "}" }),
  }),

  s("ptrnotnull", {
    t("if ("),
    i(1, "ptr"),
    t({ " != NULL) {", "    " }),
    i(2),
    t({ "", "}" }),
  }),

  -- Memory allocation

  s("malloc", {
    i(1, "int"),
    t(" *"),
    i(2, "array"),
    t(" = malloc("),
    i(3, "n"),
    t(" * sizeof(*"),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t("));"),
  }),

  s("malloccheck", {
    i(1, "int"),
    t(" *"),
    i(2, "array"),
    t(" = malloc("),
    i(3, "n"),
    t(" * sizeof(*"),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t({ "));", "", "if (" }),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t({ " == NULL) {", "    " }),
    i(4, "perror(\"malloc\")"),
    t({ ";", "    return 1;", "}" }),
  }),

  s("calloc", {
    i(1, "int"),
    t(" *"),
    i(2, "array"),
    t(" = calloc("),
    i(3, "n"),
    t(", sizeof(*"),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t("));"),
  }),

  s("calloccheck", {
    i(1, "int"),
    t(" *"),
    i(2, "array"),
    t(" = calloc("),
    i(3, "n"),
    t(", sizeof(*"),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t({ "));", "", "if (" }),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t({ " == NULL) {", "    " }),
    i(4, "perror(\"calloc\")"),
    t({ ";", "    return 1;", "}" }),
  }),

  s("realloc", {
    i(1, "int"),
    t(" *tmp = realloc("),
    i(2, "array"),
    t(", "),
    i(3, "new_size"),
    t(" * sizeof(*"),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t("));"),
  }),

  s("realloccheck", {
    i(1, "int"),
    t(" *tmp = realloc("),
    i(2, "array"),
    t(", "),
    i(3, "new_size"),
    t(" * sizeof(*"),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t({ "));", "", "if (tmp == NULL) {", "    " }),
    i(4, "perror(\"realloc\")"),
    t({ ";", "    free(" }),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t({ ");", "    return 1;", "}", "", "" }),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t(" = tmp;"),
  }),

  s("free", {
    t("free("),
    i(1, "ptr"),
    t({ ");", "" }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" = NULL;"),
  }),

  -- Algorithms

  s("swap", {
    i(1, "int"),
    t(" temp = "),
    i(2, "a"),
    t(";"),
    t({ "", "" }),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t(" = "),
    i(3, "b"),
    t(";"),
    t({ "", "" }),
    f(function(args)
      return args[3][1]
    end, { 3 }),
    t(" = temp;"),
  }),

  s("swapfn", {
    t("void swap("),
    i(1, "int"),
    t(" *a, "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" *b) {"),
    t({ "", "    " }),
    i(2, "int temp = *a;"),
    t({ "", "    *a = *b;", "    *b = temp;", "}" }),
  }),

  s("min", {
    t("("),
    i(1, "a"),
    t(" < "),
    i(2, "b"),
    t(" ? "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" : "),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t(")"),
  }),

  s("max", {
    t("("),
    i(1, "a"),
    t(" > "),
    i(2, "b"),
    t(" ? "),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" : "),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t(")"),
  }),

  s("minfn", {
    t("int min("),
    i(1, "int a"),
    t(", "),
    i(2, "int b"),
    t({ ") {", "    return a < b ? a : b;", "}" }),
  }),

  s("maxfn", {
    t("int max("),
    i(1, "int a"),
    t(", "),
    i(2, "int b"),
    t({ ") {", "    return a > b ? a : b;", "}" }),
  }),

  s("qsort", {
    t("qsort("),
    i(1, "array"),
    t(", "),
    i(2, "n"),
    t(", sizeof("),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("[0]), "),
    i(3, "compare"),
    t(");"),
  }),

  s("qsortfn", {
    t({
      "int compare(const void *a, const void *b) {",
      "    const ",
    }),
    i(1, "int"),
    t(" *x = a;"),
    t({ "", "    const " }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" *y = b;"),
    t({ "", "    return (*x > *y) - (*x < *y);", "}" }),
  }),

  s("qsortdesc", {
    t({
      "int compare(const void *a, const void *b) {",
      "    const ",
    }),
    i(1, "int"),
    t(" *x = a;"),
    t({ "", "    const " }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t(" *y = b;"),
    t({ "", "    return (*y > *x) - (*y < *x);", "}" }),
  }),

  s("bsearch", {
    t("bsearch("),
    i(1, "target"),
    t(", "),
    i(2, "array"),
    t(", "),
    i(3, "n"),
    t(", sizeof("),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t("[0]), "),
    i(4, "compare"),
    t(")"),
  }),

  -- Memory functions

  s("memcpy", {
    t("memcpy("),
    i(1, "destination"),
    t(", "),
    i(2, "source"),
    t(", "),
    i(3, "size"),
    t(");"),
  }),

  s("memmove", {
    t("memmove("),
    i(1, "destination"),
    t(", "),
    i(2, "source"),
    t(", "),
    i(3, "size"),
    t(");"),
  }),

  s("memset", {
    t("memset("),
    i(1, "array"),
    t(", "),
    i(2, "0"),
    t(", "),
    i(3, "size"),
    t(");"),
  }),

  s("memcmp", {
    t("memcmp("),
    i(1, "a"),
    t(", "),
    i(2, "b"),
    t(", "),
    i(3, "size"),
    t(")"),
  }),

  -- Input and output

  s("printf", {
    t("printf(\""),
    i(1, "%d\\n"),
    t("\", "),
    i(2, "value"),
    t(");"),
  }),

  s("pf", {
    t("printf(\""),
    i(1, "%d\\n"),
    t("\", "),
    i(2, "value"),
    t(");"),
  }),

  s("ps", {
    t('printf("%s\\n", '),
    i(1, "string"),
    t(");"),
  }),

  s("pi", {
    t('printf("%d\\n", '),
    i(1, "value"),
    t(");"),
  }),

  s("pu", {
    t('printf("%u\\n", '),
    i(1, "value"),
    t(");"),
  }),

  s("pl", {
    t('printf("%ld\\n", '),
    i(1, "value"),
    t(");"),
  }),

  s("pzu", {
    t('printf("%zu\\n", '),
    i(1, "value"),
    t(");"),
  }),

  s("px", {
    t('printf("%x\\n", '),
    i(1, "value"),
    t(");"),
  }),

  s("pc", {
    t('printf("%c\\n", '),
    i(1, "value"),
    t(");"),
  }),

  s("pfmt", {
    t('printf("'),
    i(1, "format"),
    t('", '),
    i(2, "value"),
    t(");"),
  }),

  s("scanf", {
    t("scanf(\""),
    i(1, "%d"),
    t("\", &"),
    i(2, "value"),
    t(");"),
  }),

  s("sscanf", {
    t("sscanf("),
    i(1, "string"),
    t(', "'),
    i(2, "%d"),
    t("\", &"),
    i(3, "value"),
    t(");"),
  }),

  s("puts", {
    t("puts(\""),
    i(1, "text"),
    t("\");"),
  }),

  s("putchar", {
    t("putchar("),
    i(1, "c"),
    t(");"),
  }),

  s("getchar", {
    t("getchar()"),
  }),

  s("fgets", {
    t("fgets("),
    i(1, "buffer"),
    t(", sizeof("),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("), stdin);"),
  }),

  s("snprintf", {
    t("snprintf("),
    i(1, "buffer"),
    t(", sizeof("),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t('), "'),
    i(2, "%d"),
    t('", '),
    i(3, "value"),
    t(");"),
  }),

  -- Error handling

  s("assert", {
    t("assert("),
    i(1, "condition"),
    t(");"),
  }),

  s("perror", {
    t('perror("'),
    i(1, "error"),
    t('");'),
  }),

  s("exit", {
    t("exit("),
    c(1, {
      t("EXIT_SUCCESS"),
      t("EXIT_FAILURE"),
      i(nil, "status"),
    }),
    t(");"),
  }),

  s("abort", {
    t("abort();"),
  }),

  s("errcheck", {
    t("if ("),
    i(1, "condition"),
    t({ ") {", "    perror(\"" }),
    i(2, "error"),
    t({ "\");", "    return " }),
    i(3, "1"),
    t({ ";", "}" }),
  }),

  -- Structs

  s("struct", {
    t("struct "),
    i(1, "Name"),
    t({ " {", "    " }),
    i(2, "int field;"),
    t({ "", "};" }),
  }),

  s("structvar", {
    t("struct "),
    i(1, "Name"),
    t(" "),
    i(2, "variable"),
    t(";"),
  }),

  s("typedef", {
    t("typedef "),
    i(1, "struct "),
    i(2, "Name"),
    t({ " {", "    " }),
    i(3, "int field;"),
    t({ "", "} " }),
    f(function(args)
      return args[2][1]
    end, { 2 }),
    t(";"),
  }),

  s("typedefstruct", {
    t({
      "typedef struct {",
      "    ",
    }),
    i(1, "int field;"),
    t({ "", "} " }),
    i(2, "Name"),
    t(";"),
  }),

  s("structp", {
    i(1, "struct Name"),
    t(" *"),
    i(2, "ptr"),
    t(";"),
  }),

  s("arrow", {
    i(1, "ptr"),
    t("->"),
    i(2, "field"),
  }),

  s("dot", {
    i(1, "object"),
    t("."),
    i(2, "field"),
  }),

  -- Enum

  s("enum", {
    t("enum "),
    i(1, "Name"),
    t({ " {", "    " }),
    i(2, "VALUE_ONE"),
    t(","),
    t({ "", "    " }),
    i(3, "VALUE_TWO"),
    t({ "", "};" }),
  }),

  s("typedefenum", {
    t({
      "typedef enum {",
      "    ",
    }),
    i(1, "VALUE_ONE"),
    t(","),
    t({ "", "    " }),
    i(2, "VALUE_TWO"),
    t({ "", "} " }),
    i(3, "Name"),
    t(";"),
  }),

  -- Union

  s("union", {
    t("union "),
    i(1, "Name"),
    t({ " {", "    " }),
    i(2, "int field;"),
    t({ "", "};" }),
  }),

  s("typedefunion", {
    t({
      "typedef union {",
      "    ",
    }),
    i(1, "int field;"),
    t({ "", "} " }),
    i(2, "Name"),
    t(";"),
  }),

  -- Function pointers

  s("callback", {
    t("void (*"),
    i(1, "callback"),
    t(")("),
    i(2, "int value"),
    t(");"),
  }),

  s("callbackparam", {
    t("void function("),
    t("void (*"),
    i(1, "callback"),
    t(")("),
    i(2, "int"),
    t(")) {"),
    t({ "", "    " }),
    i(3),
    t({ "", "}" }),
  }),

  -- File handling

  s("file", {
    t("FILE *"),
    i(1, "file"),
    t(" = fopen(\""),
    i(2, "file.txt"),
    t("\", \""),
    i(3, "r"),
    t("\");"),
  }),

  s("filecheck", {
    t("FILE *"),
    i(1, "file"),
    t(" = fopen(\""),
    i(2, "file.txt"),
    t({ "\", \"" }),
    i(3, "r"),
    t({ "\");", "", "if (" }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t({ " == NULL) {", "    perror(\"fopen\");", "    return 1;", "}" }),
  }),

  s("fopen", {
    t("FILE *"),
    i(1, "file"),
    t(" = fopen(\""),
    i(2, "file.txt"),
    t("\", \""),
    i(3, "r"),
    t("\");"),
  }),

  s("fclose", {
    t("fclose("),
    i(1, "file"),
    t(");"),
  }),

  s("fread", {
    t("fread("),
    i(1, "buffer"),
    t(", sizeof("),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("[0]), "),
    i(2, "count"),
    t(", "),
    i(3, "file"),
    t(");"),
  }),

  s("fwrite", {
    t("fwrite("),
    i(1, "buffer"),
    t(", sizeof("),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("[0]), "),
    i(2, "count"),
    t(", "),
    i(3, "file"),
    t(");"),
  }),

  s("fprintf", {
    t("fprintf("),
    i(1, "file"),
    t(', "'),
    i(2, "%d\\n"),
    t('", '),
    i(3, "value"),
    t(");"),
  }),

  s("fscanf", {
    t("fscanf("),
    i(1, "file"),
    t(', "'),
    i(2, "%d"),
    t("\", &"),
    i(3, "value"),
    t(");"),
  }),

  s("fgetsfile", {
    t("fgets("),
    i(1, "buffer"),
    t(", sizeof("),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t("), "),
    i(2, "file"),
    t(");"),
  }),

  -- Includes

  s("inc", {
    t("#include <"),
    i(1, "header.h"),
    t(">"),
  }),

  s("stdio", {
    t("#include <stdio.h>"),
  }),

  s("stdlib", {
    t("#include <stdlib.h>"),
  }),

  s("string", {
    t("#include <string.h>"),
  }),

  s("stdbool", {
    t("#include <stdbool.h>"),
  }),

  s("stdint", {
    t("#include <stdint.h>"),
  }),

  s("stddef", {
    t("#include <stddef.h>"),
  }),

  s("asserth", {
    t("#include <assert.h>"),
  }),

  s("math", {
    t("#include <math.h>"),
  }),

  s("ctype", {
    t("#include <ctype.h>"),
  }),

  s("time", {
    t("#include <time.h>"),
  }),

  s("limits", {
    t("#include <limits.h>"),
  }),

  s("float", {
    t("#include <float.h>"),
  }),

  s("errno", {
    t("#include <errno.h>"),
  }),

  -- Preprocessor

  s("define", {
    t("#define "),
    i(1, "NAME"),
    t(" "),
    i(2, "value"),
  }),

  s("ifdef", {
    t("#ifdef "),
    i(1, "NAME"),
    t({
      "",
      "",
      "#endif",
    }),
  }),

  s("ifndef", {
    t("#ifndef "),
    i(1, "NAME"),
    t({
      "",
      "#define ",
    }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t({
      "",
      "",
      "#endif",
    }),
  }),

  s("pragma", {
    t("#pragma "),
    i(1, "once"),
  }),

  s("pragmaonce", {
    t("#pragma once"),
  }),

  -- Header guards

  s("guard", {
    t("#ifndef "),
    i(1, "MY_HEADER_H"),
    t({ "", "#define " }),
    f(function(args)
      return args[1][1]
    end, { 1 }),
    t({
      "",
      "",
      "#endif",
    }),
  }),

  s("header", {
    t({
      "#pragma once",
      "",
      "",
    }),
    i(0),
  }),

  -- Character utilities

  s("isdigit", {
    t("isdigit("),
    i(1, "c"),
    t(")"),
  }),

  s("isalpha", {
    t("isalpha("),
    i(1, "c"),
    t(")"),
  }),

  s("isalnum", {
    t("isalnum("),
    i(1, "c"),
    t(")"),
  }),

  s("isspace", {
    t("isspace("),
    i(1, "c"),
    t(")"),
  }),

  s("tolower", {
    t("tolower("),
    i(1, "c"),
    t(")"),
  }),

  s("toupper", {
    t("toupper("),
    i(1, "c"),
    t(")"),
  }),

  -- Math

  s("abs", {
    t("abs("),
    i(1, "value"),
    t(")"),
  }),

  s("fabs", {
    t("fabs("),
    i(1, "value"),
    t(")"),
  }),

  s("sqrt", {
    t("sqrt("),
    i(1, "value"),
    t(")"),
  }),

  s("pow", {
    t("pow("),
    i(1, "base"),
    t(", "),
    i(2, "exponent"),
    t(")"),
  }),

  s("floor", {
    t("floor("),
    i(1, "value"),
    t(")"),
  }),

  s("ceil", {
    t("ceil("),
    i(1, "value"),
    t(")"),
  }),

  s("round", {
    t("round("),
    i(1, "value"),
    t(")"),
  }),

  -- Boolean patterns

  s("bool", {
    t("bool "),
    i(1, "condition"),
    t(" = "),
    i(2, "true"),
    t(";"),
  }),

  s("true", {
    t("true"),
  }),

  s("false", {
    t("false"),
  }),

  -- Comments

  s("//", {
    t("// "),
    i(0),
  }),

  s("/*", {
    t({ "/*", " * " }),
    i(0),
    t({ "", " */" }),
  }),

  s("todo", {
    t("// TODO: "),
    i(0),
  }),

  s("fixme", {
    t("// FIXME: "),
    i(0),
  }),

  -- Documentation

  s("doc", {
    t({
      "/**",
      " * ",
    }),
    i(1, "Description."),
    t({ "", " *" }),
    t({ "", " * @param " }),
    i(2, "parameter"),
    t(" "),
    i(3, "Description."),
    t({ "", " * @return " }),
    i(4, "Description."),
    t({ "", " */" }),
  }),

  -- Compiler

  s("compile", {
    t("gcc -Wall -Wextra -Wpedantic -std=c23 "),
    f(get_filename, {}),
    t(" -o "),
    f(get_basename, {}),
  }),

  s("run", {
    t("./"),
    f(get_basename, {}),
  }),

  -- Solution scaffolding

  s("sol", {
    d(1, build_sol_with_header, {}),
  }),

  -- File header

  s("exs", {
    d(1, build_header, {}),
  }),
}
