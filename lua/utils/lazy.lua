-- lua/utils/lazy.lua

-- Generic lazy-loading for vim.pack plugins.
--
-- Usage: the PLUGIN'S OWN CONFIG FILE in lua/plugins/ calls M.setup with one
-- spec (this is the established pattern; lua/config/pack.lua stays
-- declarations-only for eager plugins). The module:
--   * adds the source with vim.pack.add(..., { load = function() end }),
--     which puts the plugin on the runtimepath but does NOT run its
--     plugin/ scripts at startup (ftdetect/ still works when a matching
--     file is opened later),
--   * installs a single shared FileType autocmd (augroup "LazyPack") that
--     loads (configure + :packadd) the plugin on the first buffer of a
--     listed filetype; packadd inside the FileType event runs before the
--     buffer's ftplugin, so the plugin's ftplugins apply as usual,
--   * loads immediately when setup runs while the session already has a
--     buffer of one of the filetypes open (e.g. a restored session),
--   * exposes M.load(name) for manual triggers (e.g. a rarely used keymap).
--
-- Established pattern - copy this into the plugin config file:
--
--   -- at the end of lua/plugins/myplugin.lua
--   require("utils.lazy").setup({
--     -- https://github.com/author/myplugin
--     -- One-line description of what the plugin does.
--     src = "https://github.com/author/myplugin",
--     filetypes = { "foo", "bar" }, -- filetypes that trigger the load
--     -- Optional: name of the module (this same file is common) with a
--     -- configure() that runs BEFORE the :packadd, or a direct function.
--     configure = "plugins.myplugin",
--     -- Optional: runs after the :packadd.
--     -- after = function() ... end,
--   })

---@class lazy.Spec
---@field src string            -- plugin source (a vim.pack spec)
---@field filetypes? string[]   -- filetypes that trigger the load
---@field version? string       -- optional, passed through to vim.pack
---@field configure? string|fun() -- module name with configure() (globals BEFORE packadd) or a function
---@field after? fun()          -- optional, runs after the packadd

local M = {}

-- name -> spec, filetype -> array of plugin names, load-once guard
local registered = {}
local ft_map = {}
local loaded = {}
local gate_installed = false

---Resolve the plugin name from its source (basename, without ".git").
---@param src string
---@return string
local function name_of(src)
	return (src:gsub("%.git$", ""):match("[^/]+$"))
end

---Install the shared FileType gate, once, no matter how many setups ran.
local function ensure_gate()
	if gate_installed then
		return
	end
	gate_installed = true

	-- No pattern on purpose: an O(1) table lookup is as cheap as the event
	-- matching, and all lazy plugins stay inspectable in one place (`:au LazyPack`).
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("LazyPack", { clear = true }),
		callback = function(ev)
			local names = ft_map[ev.match]
			if not names then
				return
			end
			for _, name in ipairs(names) do
				M.load(name)
			end
		end,
	})
end

---Load one plugin (once per session). Safe to call repeatedly, also before
---setup on the same name (a no-op then).
---@param name string
function M.load(name)
	local spec = registered[name]
	if not spec or loaded[name] then
		return
	end
	loaded[name] = true

	if spec.configure then
		local fn = type(spec.configure) == "string"
			and function()
				require(spec.configure).configure()
			end
			or spec.configure
		local ok, err = pcall(fn)
		if not ok then
			vim.notify(("LazyPack: configuring %s failed: %s"):format(name, err), vim.log.levels.ERROR)
		end
	end

	local ok, err = pcall(vim.cmd.packadd, name)
	if not ok then
		vim.notify(("LazyPack: packadd %s failed: %s"):format(name, err), vim.log.levels.ERROR)
		return
	end

	if spec.after then
		pcall(spec.after)
	end
end

---Declare one lazy plugin: defer its plugin/ scripts and load it later on
---filetype. Called from the plugin's own config file in lua/plugins/.
---@param spec lazy.Spec
function M.setup(spec)
	local name = name_of(spec.src)
	registered[name] = spec
	for _, ft in ipairs(spec.filetypes or {}) do
		ft_map[ft] = ft_map[ft] or {}
		table.insert(ft_map[ft], name)
	end

	local add_spec = { src = spec.src }
	if spec.version then
		add_spec.version = spec.version
	end
	local ok, err = pcall(vim.pack.add, { add_spec }, { load = function() end })
	if not ok then
		vim.notify(("LazyPack: adding %s failed: %s"):format(spec.src, err), vim.log.levels.ERROR)
	end

	ensure_gate()

	-- Catch-up for buffers that already have one of the filetypes (restored
	-- sessions and files opened before this module got required).
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local ft = vim.bo[buf].filetype
		if ft and vim.list_contains(spec.filetypes or {}, ft) then
			M.load(name)
			break
		end
	end
end

return M
