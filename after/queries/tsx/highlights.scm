;; extends

; after/queries/tsx/highlights.scm

(jsx_opening_element name: (identifier) @tag.component (#lua-match? @tag.component "^[A-Z]"))
(jsx_closing_element name: (identifier) @tag.component (#lua-match? @tag.component "^[A-Z]"))
(jsx_self_closing_element name: (identifier) @tag.component (#lua-match? @tag.component "^[A-Z]"))
(jsx_opening_element name: (member_expression) @tag.component)
(jsx_closing_element name: (member_expression) @tag.component)
(jsx_self_closing_element name: (member_expression) @tag.component)

(jsx_opening_element name: (identifier) @tag.intrinsic (#lua-match? @tag.intrinsic "^[a-z]"))
(jsx_closing_element name: (identifier) @tag.intrinsic (#lua-match? @tag.intrinsic "^[a-z]"))
(jsx_self_closing_element name: (identifier) @tag.intrinsic (#lua-match? @tag.intrinsic "^[a-z]"))

((call_expression function: (identifier) @function.call.hook)
 (#lua-match? @function.call.hook "^use%u"))
((call_expression function: (member_expression property: (property_identifier) @function.call.hook))
 (#lua-match? @function.call.hook "^use%u"))

((jsx_attribute
   (property_identifier) @_attr
   (string (string_fragment) @string.tailwind))
 (#any-of? @_attr "className" "class"))

((jsx_attribute
   (property_identifier) @_attr
   (jsx_expression (string (string_fragment) @string.tailwind)))
 (#any-of? @_attr "className" "class"))

((call_expression
   function: (identifier) @_fn
   arguments: (arguments (string (string_fragment) @string.tailwind)))
 (#any-of? @_fn "cn" "clsx" "cva" "twMerge" "classNames" "tw"))
