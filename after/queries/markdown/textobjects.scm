; after/queries/markdown/textobjects.scm
; extends

(fenced_code_block) @code_block.outer
(fenced_code_block (code_fence_content) @code_block.inner)
