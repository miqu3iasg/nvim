-- pandoc/filters/wikilinks.lua

-- Handles Obsidian-style [[wikilinks]] during Pandoc conversion.
--
-- [[Note]] and [[Note|alias]] are converted to their visible text instead of
-- remaining links. A link to an Obsidian note would otherwise point to a
-- destination that generally does not exist in the exported PDF.
--
-- Image embeds such as ![[image.png]] are handled earlier by
-- lua/shared/pandoc.lua, which rewrites them as ordinary Markdown images
-- because Pandoc does not parse Obsidian image embeds reliably.

---Determine whether a Pandoc link represents an Obsidian wikilink.
---Both the `wikilink` title and class are accepted for compatibility with
---different Pandoc versions.
---@param el pandoc.Link Link element supplied by Pandoc.
---@return boolean `true` when the link is an Obsidian wikilink.
local function is_wikilink(el)
	return el.title == "wikilink" or el.classes:includes("wikilink")
end

---Replace an Obsidian wikilink with its visible inline content.
---Returning nil for ordinary links leaves them unchanged.
---@param el pandoc.Link Link element supplied by Pandoc.
---@return pandoc.Inline[]|nil Visible link content, or nil to keep the link.
function Link(el)
	if is_wikilink(el) then
		return el.content
	end
end
