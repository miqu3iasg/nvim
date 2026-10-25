-- filters/metadata-block.lua

-- Inserts a block with the note's reference fields (authors, source, links...)
-- right below the title. Only fields that exist and are not empty are shown.
--
-- Labels follow the document language (`lang`, set in metadata.yaml and
-- overridable in each note). A language without a table falls back to
-- `default_lang`.
--
-- To turn the block off in a note: `show-metadata: false`
--
-- See: https://pandoc.org/lua-filters.html

-- Labels per language (primary code of `lang`: pt, en, ...)
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
local default_lang = "en"

-- Order and display mode of each field
-- inline is items separated by comma and list is a bullet list, one item per line
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

-- Parse language
local function labels_for(meta)
	local lang = meta.lang and pandoc.utils.stringify(meta.lang) or ""
	local primary = lang:match("^(%a+)")
	return labels[primary and primary:lower() or default_lang] or labels[default_lang]
end

local function is_url(s)
	return s:match("^https?://%S+$") ~= nil
end

-- Flattens a value (string, list, nested list) into a list of Inlines,
-- skipping empty items and turning URLs into links
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
