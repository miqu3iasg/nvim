-- lua/shared/citekeys.lua

-- blink.cmp source that completes pandoc citations ([@key], @key, -@key)
-- from the bibliography found by shared.bib. It needs no extra plugin.
-- Only keys made of letters, digits and _ are replaced cleanly: a key that
-- contains "." or ":" keeps the part typed before it

local bib = require("shared.bib")

local source = {}

-- Index of the "@" if the text before the cursor ends inside a citation key
function source.citation_at(before)
	local s = before:find("@[%w_:%.%-]*$")
	if s and not before:sub(s - 1, s - 1):match("%w") then
		return s
	end
end

function source.new()
	return setmetatable({}, { __index = source })
end

function source:enabled()
	return vim.bo.filetype == "markdown"
end

function source:get_trigger_characters()
	return { "@" }
end

function source:get_completions(ctx, callback)
	local empty = { items = {}, is_incomplete_forward = false, is_incomplete_backward = false }
	local before = ctx.line:sub(1, ctx.cursor[2])
	if not source.citation_at(before) then
		callback(empty)
		return function() end
	end

	local files = bib.resolve(0).files
	local items = {}
	for _, e in ipairs(bib.entries(files)) do
		local short = (e.author ~= "" or e.year ~= "") and ("%s (%s)"):format(e.author, e.year) or ""
		items[#items + 1] = {
			label = e.key,
			filterText = e.key .. " " .. short,
			insertText = e.key,
			kind = 18, -- Reference
			labelDetails = { description = short },
			detail = e.title,
			documentation = {
				kind = "markdown",
				value = ("**%s**\n\n%s\n\n_%s_"):format(e.title ~= "" and e.title or e.key, short, e.kind),
			},
		}
	end

	callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
	return function() end
end

return source
