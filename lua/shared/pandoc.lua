-- lua/shared/pandoc.lua

-- Converts the current markdown buffer to PDF, EPUB, DOCX or HTML by running
-- `pandoc` asynchronously through `vim.system`, so the editor never blocks.
-- The buffer is sent through stdin, so unsaved changes are exported too. The
-- result goes to <repo>/exports/ (see lua/shared/exports.lua) and is opened in
-- zathura (PDF/EPUB) or xdg-open (DOCX/HTML).
--
-- Preview mode builds and opens the document once, then rebuilds it on every
-- `:w`; zathura reloads the file by itself.
--
-- Each export loads, in order, the pipeline in ~/.config/nvim/pandoc/
-- defaults.yaml, an optional `defaults.yaml` in the note's folder or a parent
-- folder, the default layout and language in metadata.yaml, and a profile from
-- profiles/<name>.yaml if one is requested (`:Pandoc pdf abnt`). Later files
-- win, and the YAML header of the note overrides all of them.
--
-- Wikilinks become plain text, and ![[image.png|300]] becomes a real image,
-- looked up in any `attachments/` folder above the note. Citations are
-- disabled, so "@john" is always plain text.
--
-- A second filter (filters/metadata-block.lua) adds a block with the reference
-- fields of the note (file_name, authors, description, source, location,
-- external_urls) below the title. Its labels follow the `lang` of the
-- document.
--
-- Nothing is notified on success. Errors and pandoc warnings are shown with
-- pandoc's own message.
--
-- Packages on Arch Linux:
--
--   $ sudo pacman -S pandoc-cli zathura zathura-pdf-mupdf
--
--   $ sudo pacman -S texlive-xetex texlive-latex texlive-latexextra texlive-latexrecommended texlive-fontsrecommended texlive-langportuguese
--
-- See: https://pandoc.org/MANUAL.html
-- See: https://neovim.io/doc/user/lua.html#vim.system()

local exports = require("shared.exports")

local M = {}

M.formats = { "pdf", "epub", "docx", "html" }
M.viewers = { pdf = "zathura", epub = "zathura", docx = "xdg-open", html = "xdg-open" }
M.config_dir = vim.fn.stdpath("config") .. "/pandoc"

-- Last file built for each buffer
M.last = {}

local home = vim.uv.os_homedir()

local function notify_error(msg)
	vim.notify("pandoc: " .. vim.trim(msg), vim.log.levels.ERROR)
end

local function readable(path)
	return vim.fn.filereadable(path) == 1
end

-- Folder of the note, or the cwd for an unnamed buffer
local function note_dir(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then
		return vim.uv.cwd()
	end
	return vim.fs.dirname(name)
end

-- True when the YAML header of the note defines `key`
local function frontmatter_has(buf, key)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, 300, false)
	if not (lines[1] and lines[1]:match("^%-%-%-%s*$")) then
		return false
	end
	for i = 2, #lines do
		if lines[i]:match("^%-%-%-%s*$") or lines[i]:match("^%.%.%.%s*$") then
			return false
		end
		if lines[i]:match("^" .. key .. "%s*:") then
			return true
		end
	end
	return false
end

local function list_profiles()
	local names = {}
	for _, f in ipairs(vim.fn.glob(M.config_dir .. "/profiles/*.yaml", false, true)) do
		names[#names + 1] = vim.fn.fnamemodify(f, ":t:r")
	end
	return names
end

local image_exts = { png = true, jpg = true, jpeg = true, pdf = true, svg = true }

-- Obsidian embeds, which pandoc does not parse reliably:
--   ![[img.png]]        ->  ![](img.png)
--   ![[img.png|300]]    ->  ![](img.png){width=300px}
--   ![[img.png|a cap]]  ->  ![a cap](img.png)
--   ![[Other note]]     ->  Other note
local function preprocess(text)
	return (
		text:gsub("!%[%[([^%]\n]-)%]%]", function(inner)
			local path, alias = inner:match("^(.-)|(.*)$")
			path = vim.trim(path or inner)
			local ext = path:match("%.(%w+)$")
			if not (ext and image_exts[ext:lower()]) then
				return (alias and alias ~= "") and alias or path
			end
			local url = path:gsub(" ", "%%20")
			local caption, attrs = "", ""
			if alias then
				local w, h = alias:match("^(%d+)x(%d+)$")
				if w then
					attrs = ("{width=%spx height=%spx}"):format(w, h)
				elseif alias:match("^%d+$") then
					attrs = ("{width=%spx}"):format(alias)
				else
					caption = alias
				end
			end
			return ("![%s](%s)%s"):format(caption, url, attrs)
		end)
	)
end

-- Folders named `attachments` in the note's folder and in every parent up to $HOME
local function resource_path(indir)
	local dirs = { "." }
	for dir in vim.fs.parents(indir .. "/x") do
		if vim.fn.isdirectory(dir .. "/attachments") == 1 then
			dirs[#dirs + 1] = dir .. "/attachments"
		end
		if dir == home then
			break
		end
	end
	return table.concat(dirs, ":")
end

-- opts: { fmt = "pdf", profile = "abnt", buf = <bufnr> }
function M.build(opts, on_done)
	opts = opts or {}
	local fmt = (opts.fmt and opts.fmt ~= "") and opts.fmt or "pdf"
	local profile = (opts.profile and opts.profile ~= "") and opts.profile or nil
	local buf = opts.buf or vim.api.nvim_get_current_buf()

	local name = vim.api.nvim_buf_get_name(buf)
	local indir = note_dir(buf)
	local base = name ~= "" and vim.fn.fnamemodify(name, ":t:r") or "scratch"

	local defaults = M.config_dir .. "/defaults.yaml"
	if not readable(defaults) then
		return notify_error("missing " .. defaults)
	end

	local profile_file
	if profile then
		profile_file = M.config_dir .. "/profiles/" .. profile .. ".yaml"
		if not readable(profile_file) then
			return notify_error("unknown profile: " .. profile)
		end
	end

	local text = preprocess(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n")

	local out = exports.output_path(buf, fmt)
	vim.fn.mkdir(vim.fs.dirname(out), "p")

	-- Order matters, pandoc applies options as they appear, later ones win
	local cmd = { "pandoc", "-o", out, "-d", defaults }

	local project = vim.fs.find("defaults.yaml", { path = indir, upward = true, stop = home })[1]
	if project and vim.fs.normalize(project) ~= vim.fs.normalize(defaults) then
		vim.list_extend(cmd, { "-d", project })
	end

	-- Metadata files lose against the YAML header of the note, so any note can
	-- override language, margins, font size...
	local meta = M.config_dir .. "/metadata.yaml"
	if readable(meta) then
		cmd[#cmd + 1] = "--metadata-file=" .. meta
	end
	if profile_file then
		cmd[#cmd + 1] = "--metadata-file=" .. profile_file
	end

	-- Filters run in this order: wikilinks first, so [[links]] inside the
	-- metadata values are already plain text when the block is built
	cmd[#cmd + 1] = "--lua-filter=" .. M.config_dir .. "/filters/wikilinks.lua"
	cmd[#cmd + 1] = "--lua-filter=" .. M.config_dir .. "/filters/metadata-block.lua"
	cmd[#cmd + 1] = "--resource-path=" .. resource_path(indir)

	-- The buffer goes through stdin, so pandoc does not know the file name;
	-- always pass the real one (with extension). Command-line metadata wins
	-- over the YAML header, so this also overrides `file_name` in the note
	if name ~= "" then
		cmd[#cmd + 1] = "--metadata=file_name:" .. vim.fs.basename(name)
	end

	-- EPUB needs a title and HTML a page title; use the file name when the
	-- note has none
	if not frontmatter_has(buf, "title") then
		if fmt == "epub" then
			cmd[#cmd + 1] = "--metadata=title:" .. base
		elseif fmt == "html" then
			cmd[#cmd + 1] = "--metadata=pagetitle:" .. base
		end
	end

	local ok, err = pcall(
		vim.system,
		cmd,
		{ text = true, cwd = indir, stdin = text },
		vim.schedule_wrap(function(r)
			local stderr = vim.trim(r.stderr or "")
			if r.code ~= 0 then
				return notify_error(stderr ~= "" and stderr or ("exit code " .. r.code))
			end
			if stderr ~= "" then
				vim.notify("pandoc: " .. stderr, vim.log.levels.WARN)
			end
			M.last[buf] = out
			if on_done then
				on_done(out)
			end
		end)
	)
	if not ok then
		notify_error(tostring(err))
	end
end

function M.open(file)
	local viewer = M.viewers[file:match("%.(%w+)$")] or "xdg-open"
	local ok, err = pcall(vim.system, { viewer, file }, { detach = true })
	if not ok then
		notify_error(tostring(err))
	end
end

-- preview: build and open once; rebuild on every :w (zathura reloads by itself)
function M.preview(opts)
	opts = vim.deepcopy(opts or {})
	local buf = vim.api.nvim_get_current_buf()
	opts.buf = buf
	local group_name = "PandocPreview" .. buf

	if vim.b[buf].pandoc_preview then
		vim.b[buf].pandoc_preview = false
		pcall(vim.api.nvim_del_augroup_by_name, group_name)
		vim.notify("pandoc preview: off")
		return
	end

	vim.b[buf].pandoc_preview = true
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup(group_name, { clear = true }),
		buffer = buf,
		callback = function()
			M.build(opts)
		end,
	})
	vim.notify("pandoc preview: on (rebuilds on :w)")
	M.build(opts, M.open)
end

function M.setup()
	local function parse(a)
		return { fmt = a.fargs[1], profile = a.fargs[2] }
	end

	-- :Pandoc [format] [profile]
	local function complete(lead, line)
		local args = vim.split(line, "%s+", { trimempty = true })
		local index = #args + (line:match("%s$") and 1 or 0)
		local list = index <= 2 and M.formats or list_profiles()
		return vim.tbl_filter(function(item)
			return item:find(lead, 1, true) == 1
		end, list)
	end

	vim.api.nvim_buf_create_user_command(0, "Pandoc", function(a)
		M.build(parse(a), M.open)
	end, { nargs = "*", complete = complete })

	vim.api.nvim_buf_create_user_command(0, "PandocPreview", function(a)
		M.preview(parse(a))
	end, { nargs = "*", complete = complete })

	local map = function(lhs, rhs, desc)
		vim.keymap.set("n", "<localleader>" .. lhs, rhs, { buffer = true, desc = "Pandoc: " .. desc })
	end

	map("pb", function()
		M.build({ fmt = "pdf" })
	end, "build pdf (no open)")

	map("po", function()
		local last = M.last[vim.api.nvim_get_current_buf()]
		if last and readable(last) then
			M.open(last)
		else
			M.build({ fmt = "pdf" }, M.open)
		end
	end, "open last build")

	map("pp", function()
		M.preview({ fmt = "pdf" })
	end, "preview (watch)")

	map("pf", function()
		vim.ui.select(M.formats, { prompt = "Format:" }, function(fmt)
			if not fmt then
				return
			end
			local profiles = vim.list_extend({ "(none)" }, list_profiles())
			vim.ui.select(profiles, { prompt = "Profile:" }, function(profile)
				if profile then
					M.build({ fmt = fmt, profile = profile ~= "(none)" and profile or nil }, M.open)
				end
			end)
		end)
	end, "choose format and profile")
end

return M
