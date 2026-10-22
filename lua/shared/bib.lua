-- lua/shared/bib.lua

-- Finds and reads the bibliography of a markdown buffer. Shared by the pandoc
-- exporter (lua/shared/pandoc.lua) and the @citekey completion source
-- (lua/shared/citekeys.lua), so both always agree on which .bib is in use
--
-- Resolution order:
--
-- 1. `bibliography:` in the YAML header of the note (relative paths are
--     relative to the note). Pandoc reads it by itself.
-- 2. The first refs.bib / references.bib / bibliography.bib / library.bib
--    found in the note's folder or any parent folder, up to $HOME.
-- 3. M.global, the file your reference manager (Zotero + Better BibTeX) keeps up to date.

local M = {}

M.global = vim.fs.normalize("~/personal/documents/refs.bib")
M.names = { "refs.bib", "references.bib", "bibliography.bib", "library.bib" }

function M.dir(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then
		return vim.uv.cwd()
	end
	return vim.fs.dirname(name)
end

-- Lines of the YAML header (without the --- fences), or {} if there is none
function M.frontmatter(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, 300, false)
	if not (lines[1] and lines[1]:match("^%-%-%-%s*$")) then
		return {}
	end
	local fm = {}
	for i = 2, #lines do
		if lines[i]:match("^%-%-%-%s*$") or lines[i]:match("^%.%.%.%s*$") then
			return fm
		end
		fm[#fm + 1] = lines[i]
	end
	return {}
end

function M.has_key(fm, key)
	for _, line in ipairs(fm) do
		if line:match("^" .. key .. "%s*:") then
			return true
		end
	end
	return false
end

local function unquote(s)
	s = vim.trim(s)
	return (s:gsub("^[\"'](.*)[\"']$", "%1"))
end

-- Values of a key that holds a string, an inline list or a block list.
-- Returns nil when the key is absent
local function list_field(fm, key)
	for i, line in ipairs(fm) do
		local rest = line:match("^" .. key .. "%s*:%s*(.-)%s*$")
		if rest then
			local vals = {}
			if rest == "" then
				for j = i + 1, #fm do
					local item = fm[j]:match("^%s*%-%s*(.-)%s*$")
					if not item then
						break
					end
					vals[#vals + 1] = unquote(item)
				end
			elseif rest:sub(1, 1) == "[" then
				local inner = rest:gsub("^%[", "")
				inner = inner:gsub("%]%s*$", "")
				for item in inner:gmatch("[^,]+") do
					vals[#vals + 1] = unquote(item)
				end
			else
				vals[1] = unquote(rest)
			end
			return vals
		end
	end
	return nil
end

local function absolute(p, dir)
	p = p:gsub("%${([%w_]+)}", function(v)
		return os.getenv(v) or ""
	end)
	p = vim.fs.normalize(p)
	if p:sub(1, 1) ~= "/" then
		p = vim.fs.joinpath(dir, p)
	end
	return p
end

-- Returns:
--   declared      the note declares its own bibliography (or inline references)
--   fallback      files came from the search above, pandoc must be told about them
--   csl_declared  the note chooses its own citation style
--   files         absolute paths of the .bib files
function M.resolve(buf)
	buf = (buf and buf ~= 0) and buf or vim.api.nvim_get_current_buf()
	local dir = M.dir(buf)
	local fm = M.frontmatter(buf)
	local listed = list_field(fm, "bibliography")
	local inline = M.has_key(fm, "references")

	local res = {
		declared = listed ~= nil or inline,
		fallback = listed == nil and not inline,
		csl_declared = M.has_key(fm, "csl"),
		files = {},
	}

	if listed then
		for _, p in ipairs(listed) do
			res.files[#res.files + 1] = absolute(p, dir)
		end
	elseif res.fallback then
		local found = vim.fs.find(M.names, { path = dir, upward = true, limit = 1, stop = vim.uv.os_homedir() })[1]
		if found then
			res.files[1] = found
		elseif vim.fn.filereadable(M.global) == 1 then
			res.files[1] = M.global
		end
	end
	return res
end

-- BibTeX / BibLaTeX parsing (only what completion needs)

local function clean(s)
	s = s:gsub("[{}]", "")
	s = s:gsub("%s+", " ")
	return vim.trim(s)
end

local function field(body, lower, name)
	local _, e = lower:find("[%s,]" .. name .. "%s*=%s*")
	if not e then
		return nil
	end
	local c = body:sub(e + 1, e + 1)
	if c == "{" then
		local depth = 0
		for i = e + 1, #body do
			local ch = body:sub(i, i)
			if ch == "{" then
				depth = depth + 1
			elseif ch == "}" then
				depth = depth - 1
				if depth == 0 then
					return clean(body:sub(e + 2, i - 1))
				end
			end
		end
	elseif c == '"' then
		local close = body:find('"', e + 2, true)
		if close then
			return clean(body:sub(e + 2, close - 1))
		end
	else
		local raw = body:match("^[^,%s}]+", e + 1)
		return raw and clean(raw) or nil
	end
	return nil
end

local function short_author(authors)
	if not authors or authors == "" then
		return ""
	end
	local list = vim.split(authors, "%s+and%s+")
	local first = list[1]
	local last
	if first:find(",", 1, true) then
		last = vim.trim(first:match("^[^,]+"))
	else
		last = first:match("(%S+)%s*$") or first
	end
	if #list > 1 then
		last = last .. " et al."
	end
	return last
end

local skipped = { comment = true, string = true, preamble = true }

local function parse(text)
	local entries = {}
	local pos = 1
	while true do
		local s, e, kind, key = text:find("@(%a+)%s*[{(]%s*([^,%s}]+)%s*,", pos)
		if not s then
			break
		end
		local nxt = text:find("\n%s*@%a+%s*[{(]", e) or (#text + 1)
		if not skipped[kind:lower()] then
			local body = text:sub(e, nxt - 1)
			local lower = body:lower()
			local author = field(body, lower, "author") or field(body, lower, "editor") or ""
			local year = field(body, lower, "year") or (field(body, lower, "date") or ""):match("%d%d%d%d") or ""
			entries[#entries + 1] = {
				key = key,
				author = short_author(author),
				year = year,
				title = field(body, lower, "title") or "",
				kind = kind:lower(),
			}
		end
		pos = nxt
	end
	return entries
end

local cache = {}

local function read(path)
	local stat = vim.uv.fs_stat(path)
	if not stat then
		return {}
	end
	local stamp = stat.mtime.sec .. ":" .. stat.mtime.nsec
	local hit = cache[path]
	if hit and hit.stamp == stamp then
		return hit.entries
	end
	local f = io.open(path, "rb")
	if not f then
		return {}
	end
	local text = f:read("*a")
	f:close()
	local entries = parse(text)
	cache[path] = { stamp = stamp, entries = entries }
	return entries
end

-- Entries of every file, without duplicated keys. Re-read only when a file changes
function M.entries(files)
	local seen, all = {}, {}
	for _, path in ipairs(files) do
		for _, entry in ipairs(read(path)) do
			if not seen[entry.key] then
				seen[entry.key] = true
				all[#all + 1] = entry
			end
		end
	end
	return all
end

return M
