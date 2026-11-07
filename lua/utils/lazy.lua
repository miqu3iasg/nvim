-- lua/utils/lazy.lua

-- Generic filetype-based lazy-loading for vim.pack plugins. Each plugin's own
-- config file in lua/plugins/ declares itself with `setup(spec)`;
-- lua/config/pack.lua stays declarations-only for eager plugins.
--
-- The plugin is added to the runtimepath at startup but its plugin/ scripts do
-- not run until the first buffer of one of the listed filetypes appears (or
-- until `load(name)` is called manually). Loading runs `configure`, then
-- `:packadd`, then `after`. Because it happens inside the FileType event, the
-- plugin's ftplugins still apply to that first buffer, and ftdetect/ works
-- even before the plugin is loaded. If a buffer of one of the filetypes is
-- already open when `setup` runs (e.g. a restored session), the plugin loads
-- immediately.
--
-- `configure` runs BEFORE `:packadd`, so it is the place for settings the
-- plugin reads while loading (e.g. globals). Use `after` for anything that
-- needs the plugin already loaded. The plugin name is derived from `src`
-- (basename without `.git`) and must match the directory vim.pack installs.
--
-- Usage, at the end of lua/plugins/myplugin.lua:
--
--   require("utils.lazy").setup({
--     src = "https://github.com/author/myplugin",
--     filetypes = { "foo", "bar" },
--     configure = "plugins.myplugin", -- module with configure(), or a function
--     after = function() end,         -- optional
--   })
--
-- Because the plugin is NOT on the runtimepath at filetype-detection time, a
-- filetype whose detection depends on a global the plugin owns (vimtex's
-- ftdetect sets g:tex_flavor, for example) must set that global in the plugin
-- file's top level - there it runs at startup, before any buffer opens.
--
-- Future extensions (documented here, deliberately not implemented):
--   * cmds - trigger when a user command is typed before its plugin defines
--     it (CmdUndefined event), then re-run the typed command after the
--     :packadd (the approach lazy.nvim takes). Nothing here needs it yet:
--     no lazy plugin is command-first.
--   * keys - trigger on the first use of a mapping owned by a lazy plugin,
--     replaying the typed keys so the real mapping answers it (install a
--     placeholder mapping, packadd, then feedkeys the original). Only worth
--     it for rare-use mappings of heavyweight plugins.
--
-- See: lua/config/pack.lua

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
		local fn = type(spec.configure) == "string" and function()
			require(spec.configure).configure()
		end or spec.configure
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
