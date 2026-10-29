-- pandoc/filters/cites_to_text.lua

-- Used when no bibliography is available. Citation elements are replaced
-- with the literal content originally written in the Markdown source, so
-- references such as "@john" or "[@a; @b]" do not become unresolved
-- citation markers such as "(john?)".

---Replace a Pandoc citation element with its original inline content.
---@param el pandoc.Cite Citation element supplied by Pandoc.
---@return pandoc.Inline[] Literal citation content, without citation processing.
function Cite(el)
	return el.content
end
