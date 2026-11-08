-- lua/shared/pandoc.lua

-- Exports the current Markdown buffer to PDF, EPUB, DOCX or HTML by running
-- `pandoc` asynchronously, so the editor never blocks. The buffer is sent
-- through stdin, so unsaved changes are exported too. The result goes to the
-- exports folder and is opened in zathura for PDF and EPUB, or in xdg-open for
-- DOCX and HTML.
--
-- Preview mode builds and opens the document once, then rebuilds it on every
-- save. Zathura reloads the file by itself.
--
-- Each export loads the pipeline in `~/.config/nvim/pandoc/defaults.yaml`, an
-- optional `defaults.yaml` in the note's folder or a parent folder, the default
-- layout and language in `metadata.yaml`, and a profile from `profiles/` when
-- one is requested. Later files win, and the YAML header of the note overrides
-- all of them.
--
-- Wikilinks become plain text, and Obsidian image embeds become real images,
-- looked up in any `attachments/` folder above the note. Citations are
-- disabled, so `@john` is always plain text. A second filter adds a block with
-- the reference fields of the note below the title, with labels that follow the
-- `lang` of the document.
--
-- Nothing is notified on success. Errors and pandoc warnings are shown with
-- pandoc's own message.
--
-- On Arch Linux, install the viewer and the export tools with:
--
-- $ sudo pacman -S pandoc-cli zathura zathura-pdf-mupdf xdg-utils
--
-- PDF export through XeTeX needs these TeX Live packages:
--
-- $ sudo pacman -S texlive-xetex texlive-latex texlive-latexextra texlive-latexrecommended texlive-fontsrecommended texlive-langportuguese
--
-- See: lua/shared/exports.lua
-- See: https://pandoc.org/MANUAL.html
-- See: :help vim.system()

local exports = require("shared.exports")

---@class SharedPandoc
---@field formats string[] Supported export formats.
---@field viewers table<string, string> External application used to open each format.
---@field config_dir string Path to the Pandoc configuration directory.
---@field last table<integer, string> Last exported file, indexed by buffer number.

---@class PandocBuildOptions
---@field fmt? string Export format. Defaults to `"pdf"`.
---@field profile? string Name of a profile in `pandoc/profiles/`.
---@field buf? integer Buffer number to export. Defaults to the current buffer.

---@type SharedPandoc
local M = {}

M.formats = { "pdf", "epub", "docx", "html" }
M.viewers = { pdf = "zathura", epub = "zathura", docx = "xdg-open", html = "xdg-open" }
M.config_dir = vim.fn.stdpath("config") .. "/pandoc"
M.last = {}

local home = vim.uv.os_homedir()

---@param msg string
local function notify_error(msg)
	vim.notify("pandoc: " .. vim.trim(msg), vim.log.levels.ERROR)
end

---@param path string
---@return boolean
local function readable(path)
	return vim.fn.filereadable(path) == 1
end

---Folder of the note, or the current directory for an unnamed buffer.
---@param buf integer
---@return string
local function note_dir(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then
		return vim.uv.cwd()
	end
	return vim.fs.dirname(name)
end

---Whether the YAML header of the note defines `key`.
---@param buf integer
---@param key string
---@return boolean
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

---@return string[] Profile names without the `.yaml` extension.
local function list_profiles()
	local names = {}
	for _, f in ipairs(vim.fn.glob(M.config_dir .. "/profiles/*.yaml", false, true)) do
		names[#names + 1] = vim.fn.fnamemodify(f, ":t:r")
	end
	return names
end

---@type table<string, boolean>
local image_exts = { png = true, jpg = true, jpeg = true, pdf = true, svg = true }

---Convert Obsidian embeds, which pandoc does not parse reliably. An image embed
---becomes a Markdown image, where `|300` sets the width and `|text` sets the
---caption. An embed of another note becomes its plain name.
---@param text string
---@return string
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

---Colon-separated resource path made of the note's folder and every
---`attachments/` folder in the parents up to `$HOME`.
---@param indir string
---@return string
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

---Export a buffer asynchronously.
---@param opts? PandocBuildOptions
---@param on_done? fun(output_path: string) Called after a successful export.
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

	-- Pandoc applies options as they appear, so later ones win.
	local cmd = { "pandoc", "-o", out, "-d", defaults }

	local project = vim.fs.find("defaults.yaml", { path = indir, upward = true, stop = home })[1]
	if project and vim.fs.normalize(project) ~= vim.fs.normalize(defaults) then
		vim.list_extend(cmd, { "-d", project })
	end

	-- Metadata files lose against the YAML header of the note, so any note can
	-- override language, margins and font size.
	local meta = M.config_dir .. "/metadata.yaml"
	if readable(meta) then
		cmd[#cmd + 1] = "--metadata-file=" .. meta
	end
	if profile_file then
		cmd[#cmd + 1] = "--metadata-file=" .. profile_file
	end

	-- The wikilinks filter runs first, so links inside the metadata values are
	-- already plain text when the metadata block is built.
	cmd[#cmd + 1] = "--lua-filter=" .. M.config_dir .. "/filters/wikilinks.lua"
	cmd[#cmd + 1] = "--lua-filter=" .. M.config_dir .. "/filters/metadata-block.lua"
	cmd[#cmd + 1] = "--resource-path=" .. resource_path(indir)

	-- The buffer goes through stdin, so pandoc does not know the file name.
	-- Command-line metadata wins over the YAML header, so this also overrides
	-- `file_name` in the note.
	if name ~= "" then
		cmd[#cmd + 1] = "--metadata=file_name:" .. vim.fs.basename(name)
	end

	-- EPUB needs a title and HTML needs a page title, so the file name is used
	-- when the note has none.
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

---@param file string
function M.open(file)
	local viewer = M.viewers[file:match("%.(%w+)$")] or "xdg-open"
	local ok, err = pcall(vim.system, { viewer, file }, { detach = true })
	if not ok then
		notify_error(tostring(err))
	end
end

---Toggle the preview of the current buffer. Turning it on builds and opens the
---document once and rebuilds it on every save, and turning it off removes the
---rebuild.
---@param opts? PandocBuildOptions
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

---Register the buffer-local commands and keymaps. Meant to be called from the
---Markdown ftplugin.
function M.setup()
	---@param a { fargs: string[] }
	---@return PandocBuildOptions
	local function parse(a)
		return { fmt = a.fargs[1], profile = a.fargs[2] }
	end

	---Complete the format first and the profile second.
	---@param lead string
	---@param line string
	---@return string[]
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
