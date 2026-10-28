;; extends

; Highlights for the "classic" colorscheme (C).
; The first line makes these rules stack on top of nvim-treesitter's defaults.

; Preprocessor: #include, #define, #if...
[
  "#include"
  "#define"
  "#if"
  "#ifdef"
  "#ifndef"
  "#else"
  "#elif"
  "#endif"
  (preproc_directive)
] @keyword.directive

; <stdio.h> and "header.h"
(system_lib_string) @string.special.path

(preproc_include
  path: (string_literal) @string.special.path)

; const, volatile, restrict
(type_qualifier) @keyword.modifier

; int, char, void, unsigned long...
(primitive_type) @type.builtin

[
  "unsigned"
  "signed"
  "long"
  "short"
] @type.builtin

; return / if / for
"return" @keyword.return

[
  "if"
  "else"
  "switch"
  "case"
  "default"
] @keyword.conditional

[
  "for"
  "while"
  "do"
  "break"
  "continue"
  "goto"
] @keyword.repeat

"sizeof" @keyword.operator

; Escapes inside strings and chars: \n, \t, \0
(escape_sequence) @string.escape
