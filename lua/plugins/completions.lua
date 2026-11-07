-- lua/plugins/completions.lua

-- Completion without any completion plugin: native LSP completion
-- (`vim.lsp.completion.enable`, autotrigger only on the filetypes listed in
-- TRIGGER_FILETYPES) plus LuaSnip for snippets.
--
-- The menu has the LSP as its only source. Snippets sent by language servers
-- show up there, but LuaSnip's own snippets do not: those are expanded by
-- trigger, autosnippet or <Tab> (see the keymaps below). Outside
-- TRIGGER_FILETYPES completion is manual with <C-y>, and <C-x><C-o> opens the
-- LSP omnifunc (VimTeX also hooks in through it).
--
-- Snippet definitions live under lua/snippets/ and are loaded lazily by
-- filetype.
--
-- Completion depends on the language servers and formatters configured in
-- lua/plugins/lsp.lua and lua/plugins/formatting.lua. Mason installs the
-- external tools; the LSP configuration decides how Neovim starts them.
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
-- Language servers and formatters are installed through Mason (:Mason, or
-- :MasonInstall followed by package names), according to the languages you use.
--
-- See: https://github.com/L3MON4D3/LuaSnip
-- See: https://github.com/nvim-treesitter/nvim-treesitter
-- See: https://github.com/mason-org/mason.nvim
-- See: :h vim.lsp.completion

-- FIXME: there's a bug in completion popups. I tested open it in a java buffer hitting
-- <C-y>, but I got this error message: "E764: Option 'omnifunc' is not set"

-- Modules under lua/snippets/, required lazily the first time a buffer of that
-- filetype is opened. Keys are filetypes, values are Lua module names.
-- `common` is loaded with the first filetype that inherits it.
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

-- Filetypes that reuse the snippets of another filetype.
---@type table<string, string>
local aliases = {
	scheme = "lisp",
	mysql = "sql",
	plsql = "sql",
}

-- Filetypes that also inherit the "common" snippets.
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

-- LSP Completion (native)

-- Filetypes where the completion menu opens automatically. Every other
-- filetype completes on demand with <C-y>.
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

-- Buffers that already got completion configured (per-buffer state survives
-- the client id changing, and keeps the map from growing unbounded).
---@type table<integer, boolean>
local completion_bufs = {}

---Enable native LSP completion on `buf` when the client supports it, the
---filetype is in TRIGGER_FILETYPES, and no feature guard turned completion
---off for the buffer. The bigfile check re-uses the same heuristic so huge
---files never get an autotrigger.
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
	vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
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

-- Buffers attached before this file ran (e.g. restored sessions) missed their
-- LspAttach event.
for _, client in ipairs(vim.lsp.get_clients({ bufnr = -1 })) do
	for _, buf in ipairs(client.attached_buffers) do
		maybe_enable(client, buf)
	end
end

-- Markdown is prose: it is deliberately not in TRIGGER_FILETYPES. Obsidian's
-- completion triggers through its LSP separately, so note-link completion
-- works when typing [[.

-- LuaSnip Setup

local luasnip = require("luasnip")

luasnip.setup({
	enable_autosnippets = true,
	store_selection_keys = "<leader>s",
	update_events = "TextChanged,TextChangedI",
	region_check_events = "InsertEnter",
	delete_check_events = "TextChanged",
})

-- `filetype_extend` is cheap, so it stays eager
for ft in pairs(common_filetypes) do
	luasnip.filetype_extend(ft, { "common" })
end

for ft, base in pairs(aliases) do
	luasnip.filetype_extend(ft, { base })
end

-- Lazy Snippet Loading

-- Buffers whose filetype already went through the lazy loader, so the
-- snippets module is required only once per filetype.
---@type table<string, boolean>
local loaded = {}

--- Requires one snippet module and registers its snippets for the filetype.
--- Failures are reported with `vim.notify` instead of raising an error, so a
--- broken snippet file never blocks completion.
---@param name string Filetype key into `snippet_modules` (after alias resolution).
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

--- Entry point for the lazy snippet loader. Resolves aliases first, then
--- additionally loads the shared `common` snippets when the filetype opts in.
---@param ft string Filetype of the buffer that triggered the load.
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

-- Buffers opened before this file ran missed their FileType event
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
	if vim.api.nvim_buf_is_loaded(buf) then
		load_snippets(vim.bo[buf].filetype)
	end
end

-- Keymaps (completion and snippets)

local map = vim.keymap.set

-- <C-y>: open the LSP/omni completion menu on demand, where no autotrigger
-- exists (vim.lsp.completion is wired to the omni menu in 0.12+).
map("i", "<C-y>", "<C-x><C-o>", { desc = "Trigger LSP completion" })

-- <CR>: accept the selected item, or newline when the menu is closed.
map("i", "<CR>", function()
	return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true, desc = "Accept completion or newline" })

-- <C-n>/<C-p>: navigate the popup, or cycle LuaSnip choices when one is
-- active. `vim.schedule` around change_choice avoids a re-entrant jump out of
-- the expr mapping.
local function select_item(dir)
	return function()
		if luasnip.choice_active() then
			vim.schedule(function()
				luasnip.change_choice(dir)
			end)
			return ""
		end
		return vim.fn.pumvisible() == 1 and (dir == 1 and "<C-n>" or "<C-p>") or (dir == 1 and "<C-n>" or "<C-p>")
	end
end

map("i", "<C-n>", select_item(1), { expr = true, desc = "Next completion item / cycle snippet choice" })
map("i", "<C-p>", select_item(-1), { expr = true, desc = "Prev completion item / cycle snippet choice" })

-- <Tab>: expand a snippet when one matches, otherwise navigate the menu
-- (native "smart tab") / jump to the next placeholder. <S-Tab> jumps back.
-- Kept as one expr mapping so the checks run in order and fall through.
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

-- <C-q>: unlink the active snippet (delete the active node tree completely).
map("i", "<C-q>", function()
	if luasnip.in_snippet() then
		luasnip.unlink_current()
	end
end, { desc = "Unlink active snippet" })
