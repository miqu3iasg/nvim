;; extends

; Highlights for the "classic" colorscheme (Java).
; The first line makes these rules stack on top of nvim-treesitter's defaults.

; import / package (same role as #include in C)
[
  "import"
  "package"
] @keyword.import

; public, static, final...
[
  "public"
  "private"
  "protected"
  "static"
  "final"
  "abstract"
  "synchronized"
  "native"
  "transient"
  "volatile"
  "strictfp"
] @keyword.modifier

; int, double, boolean, void
(integral_type) @type.builtin
(floating_point_type) @type.builtin
(boolean_type) @type.builtin
(void_type) @type.builtin

; String, List, MyClass
(type_identifier) @type

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
] @keyword.repeat

[
  "try"
  "catch"
  "finally"
  "throw"
  "throws"
] @keyword.exception

; Strings, chars and escapes
(string_literal) @string
(character_literal) @character
(escape_sequence) @string.escape

; @Override, @Deprecated
(marker_annotation
  name: (identifier) @attribute)

(annotation
  name: (identifier) @attribute)
