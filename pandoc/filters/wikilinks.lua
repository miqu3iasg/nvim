-- Obsidian [[wikilinks]] for pandoc output.

-- [[Note]] and [[Note|alias]] become plain text: a link to "Note" would be a
-- broken link inside a PDF. (Image embeds, ![[image.png]], are rewritten to
-- plain markdown images by lua/shared/pandoc.lua before pandoc runs, because
-- pandoc does not parse them reliably.)

local function is_wikilink(el)
	-- pandoc marks wikilinks with the title "wikilink"; newer versions may use
	-- a class instead, so both are accepted
	return el.title == "wikilink" or el.classes:includes("wikilink")
end

function Link(el)
	if is_wikilink(el) then
		return el.content
	end
end
