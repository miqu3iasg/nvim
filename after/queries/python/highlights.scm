; extends

((module . (expression_statement (string (string_content) @injection.content)))
 (#set! injection.language "rst"))

((class_definition
   body: (block . (expression_statement (string (string_content) @injection.content))))
 (#set! injection.language "rst"))

((function_definition
   body: (block . (expression_statement (string (string_content) @injection.content))))
 (#set! injection.language "rst"))
