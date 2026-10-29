-- pandoc/filters/metadata-block.lua

-- Inserts a definition-list block containing the note's reference metadata
-- (authors, source, links, etc.) immediately below the document title.
-- Only fields that are present and contain at least one non-empty item are
-- rendered.
--
-- Labels are selected from the primary language subtag in `lang` (for
-- example, `pt-BR` uses the `pt` labels). If that language is not defined,
-- the filter falls back to `default_lang`.
--
-- Disable the block for an individual note with:
--
-- # show-metadata: false
--
-- See: https://pandoc.org/lua-filters.html

---@alias MetadataMode "inline"|"list"
---@alias MetadataItem pandoc.Inline[]

---@class MetadataField
---@field key string Metadata key to read from the document's YAML metadata.
---@field mode MetadataMode How the field's items are displayed.

---@type table<string, table<string, string>>
local labels = {
	en = {
		file_name = "File",
		authors = "Authors",
		description = "Description",
		source = "Source",
		location = "Location",
		external_urls = "Links",
		summary = "Summary",
		related = "Related",
		created_at = "Created",
		modified_at = "Modified",
	},
	pt = {
		file_name = "Arquivo",
		authors = "Autores",
		description = "Descrição",
		source = "Fonte",
		location = "Local",
		external_urls = "Links",
		summary = "Resumo",
		related = "Relacionado",
		created_at = "Criado em",
		modified_at = "Modificado em",
	},
}

---@type string
local default_lang = "en"

-- Fields are rendered in this order. `inline` joins items with commas,
-- while `list` creates a bullet list with one item per line.
---@type MetadataField[]
local fields = {
	{ key = "file_name", mode = "inline" },
	{ key = "authors", mode = "inline" },
	{ key = "description", mode = "inline" },
	{ key = "source", mode = "inline" },
	{ key = "location", mode = "inline" },
	{ key = "external_urls", mode = "list" },
	-- { key = "summary", mode = "inline" },
	-- { key = "related", mode = "inline" },
	-- { key = "created_at", mode = "inline" },
	-- { key = "modified_at", mode = "inline" },
}

---Select the label table matching the document language.
---Uses the primary language subtag and falls back to `default_lang`.
---@param meta table<string, any> Pandoc document metadata.
---@return table<string, string> Labels for the selected language.
local function labels_for(meta)
	local lang = meta.lang and pandoc.utils.stringify(meta.lang) or ""
	local primary = lang:match("^(%a+)")
	return labels[primary and primary:lower() or default_lang] or labels[default_lang]
end

---Check whether a string is an HTTP or HTTPS URL.
---@param s string Candidate URL.
---@return boolean `true` when the entire string is an HTTP(S) URL.
local function is_url(s)
	return s:match("^https?://%S+$") ~= nil
end

---Flatten a metadata value into a list of Pandoc inline elements.
---Nested lists are recursively flattened; empty values are skipped and URL
---strings are converted into clickable links.
---@param v any Metadata value: a string, Pandoc inline value, or nested list.
---@param out? MetadataItem Accumulator used during recursive calls.
---@return MetadataItem Flattened inline items.
local function items_of(v, out)
	out = out or {}
	local t = pandoc.utils.type(v)
	if t == "List" then
		for _, item in ipairs(v) do
			items_of(item, out)
		end
		return out
	end
	local s = pandoc.utils.stringify(v)
	if s == "" then
		return out
	end
	if is_url(s) then
		out[#out + 1] = pandoc.Inlines({ pandoc.Link({ pandoc.Str(s) }, s) })
	elseif t == "Inlines" then
		out[#out + 1] = v
	else
		out[#out + 1] = pandoc.Inlines({ pandoc.Str(s) })
	end
	return out
end

---Build Pandoc blocks from flattened metadata items.
---In `list` mode, each item becomes a bullet; otherwise, items are joined
---into a single paragraph separated by commas.
---@param items MetadataItem Items to render.
---@param mode MetadataMode Display mode for the field.
---@return pandoc.Block[] One block containing the rendered items.
local function render(items, mode)
	if mode == "list" then
		local bullets = {}
		for _, inl in ipairs(items) do
			bullets[#bullets + 1] = { pandoc.Plain(inl) }
		end
		return { pandoc.BulletList(bullets) }
	end
	local joined = pandoc.Inlines({})
	for i, inl in ipairs(items) do
		if i > 1 then
			joined:insert(pandoc.Str(","))
			joined:insert(pandoc.Space())
		end
		joined:extend(inl)
	end
	return { pandoc.Plain(joined) }
end

---Transform the document by inserting its reference metadata below the title.
---If `show-metadata` is false, no metadata block is inserted. When the
---document has `file_name` but no `title`, the file name (without extension)
---is also used as the document title.
---@param doc pandoc.Pandoc Document being processed by Pandoc.
---@return pandoc.Pandoc Transformed document.
function Pandoc(doc)
	if doc.meta["show-metadata"] == false then
		return nil
	end

	local names = labels_for(doc.meta)

	-- Without `title`, use `file_name` so the output does not lack a heading
	-- (delete this block if you do not want that)
	if not doc.meta.title and doc.meta.file_name then
		local name = pandoc.utils.stringify(doc.meta.file_name):gsub("%.%w+$", "")
		doc.meta.title = pandoc.MetaInlines({ pandoc.Str(name) })
	end

	local entries = {}
	for _, f in ipairs(fields) do
		local value = doc.meta[f.key]
		if value ~= nil then
			local items = items_of(value)
			if #items > 0 then
				entries[#entries + 1] = {
					{ pandoc.Strong({ pandoc.Str((names[f.key] or f.key) .. ":") }) },
					{ render(items, f.mode) },
				}
			end
		end
	end

	-- The title change above must be returned even when there is no block
	if #entries > 0 then
		doc.blocks:insert(1, pandoc.HorizontalRule())
		doc.blocks:insert(1, pandoc.DefinitionList(entries))
	end
	return doc
end
