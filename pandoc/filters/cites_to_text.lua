-- pandoc/filters/cites_to_text.lua

-- Used when no bibliography is available: citations are left as the literal
-- text that was typed, so "@john" or "[@a; @b]" never turns into "(john?)".
function Cite(el)
	return el.content
end
