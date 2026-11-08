-- lua/plugins/completions.lua

-- Completion without a completion plugin, using native LSP completion and
-- LuaSnip for snippets. The menu has the LSP as its only source, so snippets
-- sent by language servers show up there, but LuaSnip's own snippets do not.
-- Those are expanded by trigger, autosnippet or through the snippet keymaps
-- below.
--
-- The menu opens automatically only on the filetypes listed in
-- `TRIGGER_FILETYPES`. On every other filetype completion is manual, and the
-- LSP omnifunc is also available, which VimTeX hooks into as well.
--
-- LuaSnip must be declared in `pack.lua` and installed through the plugin
-- manager. Snippet definitions live under `lua/snippets/` and are loaded lazily
-- by filetype.
--
-- Completion depends on the language servers configured in
-- `lua/plugins/lsp.lua`. Language servers and formatters are installed through
-- Mason, according to the languages in use, with `:Mason` or `:MasonInstall`
-- followed by package names.
--
-- On Arch Linux, install the Tree-sitter CLI and the system dependencies with:
--
-- $ sudo pacman -S tree-sitter-cli nodejs npm jdk-openjdk typst typstyle
-- $ sudo pacman -S texlive-basic texlive-bin texlive-latexextra texlive-fontsextra
--
-- Then install the Tree-sitter parsers from Neovim:
--
-- :TSInstall c java python lua scheme racket sql markdown javascript typescript
-- :TSInstall html css json jsonc yaml toml bash latex typst
--
-- See: lua/plugins/lsp.lua
-- See: lua/plugins/formatting.lua
-- See: https://github.com/L3MON4D3/LuaSnip
-- See: https://github.com/nvim-treesitter/nvim-treesitter
-- See: https://github.com/mason-org/mason.nvim
-- See: :help vim.lsp.completion

-- Keys are filetypes and values are modules under `lua/snippets/`, required the
-- first time a buffer of that filetype is opened. `common` is loaded by the
-- filetypes that inherit it.
---@type table<string, string>
local snippet_modules = {
	tex = "snippets.latex",
	typst = "snippets.typst",
	c = "snippets.c",
	python = "snippets.python",
	java = "snippets.java",
	lisp = "snippets.lisp",
	sql = "snippets.sql",
	markdown = "snippets.markdown",
	common = "snippets.common",
}

---@type table<string, string>
local aliases = {
	scheme = "lisp",
	mysql = "sql",
	plsql = "sql",
}

---@type table<string, boolean>
local common_filetypes = {
	python = true,
	c = true,
	scheme = true,
	lua = true,
	java = true,
	javascript = true,
	typescript = true,
	go = true,
	sh = true,
	markdown = true,
	tex = true,
	typst = true,
	sql = true,
	mysql = true,
	plsql = true,
	html = true,
	css = true,
}

---@type table<string, boolean>
local TRIGGER_FILETYPES = {
	javascript = true,
	javascriptreact = true,
	typescript = true,
	typescriptreact = true,
	html = true,
	htmlangular = true,
	css = true,
	scss = true,
	tex = true,
	json = true,
	jsonc = true,
	yaml = true,
	toml = true,
}

-- Tracked per buffer, so it survives the client id changing.
---@type table<integer, boolean>
local completion_bufs = {}

---Enable native LSP completion on `buf` when the client supports it and the
---buffer is not guarded against it. Enabling it is what sets the buffer's
---`omnifunc`, so it happens for every filetype, and only the automatic popup is
---restricted to `TRIGGER_FILETYPES`. Huge files never get completion.
---@param client vim.lsp.Client
---@param buf integer
local function maybe_enable(client, buf)
	if completion_bufs[buf] or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	if not client:supports_method("textDocument/completion", buf) then
		return
	end
	if vim.b[buf].completion == false or require("utils.bigfile").is_big(buf) then
		return
	end

	completion_bufs[buf] = true

	local autotrigger = TRIGGER_FILETYPES[vim.bo[buf].filetype] == true
	vim.lsp.completion.enable(true, client.id, buf, { autotrigger = autotrigger })
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("NativeLspCompletion", { clear = true }),
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client then
			return
		end
		maybe_enable(client, ev.buf)
	end,
})

-- Buffers attached before this file ran, such as restored sessions, missed
-- their LspAttach event.
for _, client in ipairs(vim.lsp.get_clients({ bufnr = -1 })) do
	for _, buf in ipairs(client.attached_buffers) do
		maybe_enable(client, buf)
	end
end

-- Markdown is prose, so it is deliberately not in `TRIGGER_FILETYPES`.
-- Obsidian's completion triggers through its LSP separately, so note-link
-- completion works when typing `[[`.

local luasnip = require("luasnip")

luasnip.setup({
	enable_autosnippets = true,
	store_selection_keys = "<leader>s",
	update_events = "TextChanged,TextChangedI",
	region_check_events = "InsertEnter",
	delete_check_events = "TextChanged",
})

for ft in pairs(common_filetypes) do
	luasnip.filetype_extend(ft, { "common" })
end

for ft, base in pairs(aliases) do
	luasnip.filetype_extend(ft, { base })
end

-- Each snippet module is required only once.
---@type table<string, boolean>
local loaded = {}

---Require one snippet module and register its snippets. Failures are reported
---with `vim.notify` instead of raised, so a broken snippet file never blocks
---completion.
---@param name string Key of `snippet_modules`, after alias resolution.
local function load(name)
	local module = snippet_modules[name]

	if not module or loaded[name] then
		return
	end

	loaded[name] = true
	local ok, snippets = pcall(require, module)
	if ok then
		luasnip.add_snippets(name, snippets)
	else
		vim.notify(("Failed to load snippets '%s': %s"):format(module, snippets), vim.log.levels.ERROR)
	end
end

---Load the snippets of a filetype, resolving aliases first and adding the
---`common` snippets when the filetype inherits them.
---@param ft string
local function load_snippets(ft)
	load(aliases[ft] or ft)
	if common_filetypes[ft] then
		load("common")
	end
end

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("LazySnippets", { clear = true }),
	callback = function(args)
		load_snippets(args.match)
	end,
})

-- Buffers opened before this file ran missed their FileType event.
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
	if vim.api.nvim_buf_is_loaded(buf) then
		load_snippets(vim.bo[buf].filetype)
	end
end

local map = vim.keymap.set

-- Opens the completion menu on demand where there is no autotrigger.
map("i", "<C-y>", function()
	if vim.bo.omnifunc == "" then
		vim.notify("No LSP completion available for this buffer", vim.log.levels.WARN)
		return ""
	end
	return "<C-x><C-o>"
end, { expr = true, desc = "Trigger LSP completion" })

map("i", "<CR>", function()
	return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true, desc = "Accept completion or newline" })

-- The choice change is scheduled to avoid a re-entrant jump out of the expr
-- mapping.
local function select_item(dir)
	return function()
		if luasnip.choice_active() then
			vim.schedule(function()
				luasnip.change_choice(dir)
			end)
			return ""
		end
		return dir == 1 and "<C-n>" or "<C-p>"
	end
end

map("i", "<C-n>", select_item(1), { expr = true, desc = "Next completion item / cycle snippet choice" })
map("i", "<C-p>", select_item(-1), { expr = true, desc = "Prev completion item / cycle snippet choice" })

-- A single expr mapping, so the checks run in order and fall through.
map("i", "<Tab>", function()
	if luasnip.expandable() then
		return "<cmd>lua require('luasnip').expand()<cr>"
	end
	if vim.fn.pumvisible() == 1 then
		return "<C-n>"
	end
	if luasnip.jumpable(1) then
		return "<cmd>lua require('luasnip').jump(1)<cr>"
	end
	return "<Tab>"
end, { expr = true, desc = "Expand snippet, next completion item or next placeholder" })

map("i", "<S-Tab>", function()
	if vim.fn.pumvisible() == 1 then
		return "<C-p>"
	end
	if luasnip.jumpable(-1) then
		return "<cmd>lua require('luasnip').jump(-1)<cr>"
	end
	return "<S-Tab>"
end, { expr = true, desc = "Prev completion item or previous placeholder" })

map("i", "<C-q>", function()
	if luasnip.in_snippet() then
		luasnip.unlink_current()
	end
end, { desc = "Unlink active snippet" })
