-- lua/plugins/unnecessary-shit.lua

-- Miscellaneous quality-of-life mini.nvim modules (and other small plugins)
-- that are not essential, but make editing feel nicer.

local ai = require("mini.ai")
local ts = ai.gen_spec.treesitter

-- One liners
require("mini.align").setup({})
require("mini.comment").setup({})

-- Split Join
local split_join = require("mini.splitjoin")

split_join.setup({
	mappings = {
		toggle = "",
	},
})

vim.keymap.set({ "n", "x" }, "sj", function()
	split_join.join()
end, { desc = "Join arguments" })

vim.keymap.set({ "n", "x" }, "sk", function()
	split_join.split()
end, { desc = "Split arguments" })

-- Text Objects
local ai_opts = {
	n_lines = 500,
	custom_textobjects = {
		c = ts({ a = "@class.outer", i = "@class.inner" }),
		a = ts({ a = "@parameter.outer", i = "@parameter.inner" }),
		k = ts({ a = "@code_block.outer", i = "@code_block.inner" }),
		m = ts({ a = "@comment.outer", i = "@comment.inner" }),

		-- Entire file
		e = function()
			return {
				from = { line = 1, col = 1 },
				to = {
					line = vim.fn.line("$"),
					col = math.max(vim.fn.getline("$"):len(), 1),
				},
			}
		end,
	},
}
ai.setup(ai_opts)

-- Tmux Navigator
vim.keymap.set("n", "<c-h>", "<cmd>TmuxNavigateLeft<cr>")
vim.keymap.set("n", "<c-j>", "<cmd>TmuxNavigateDown<cr>")
vim.keymap.set("n", "<c-k>", "<cmd>TmuxNavigateUp<cr>")
vim.keymap.set("n", "<c-l>", "<cmd>TmuxNavigateRight<cr>")
vim.keymap.set("n", "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>")

-- Colorizer
require("colorizer").setup({
	event = { "BufReadPre", "BufNewFile" },
	init = function()
		if vim.lsp.document_color then
			vim.lsp.document_color.enable(false)
		end
	end,
	opts = {
		filetypes = {
			"css",
			"scss",
			"lua",
			"vue",
			"svelte",
			"astro",
			"html",
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
		},
		user_default_options = {
			names = false,
			tailwind = false,
		},
	},
})

-- Task Comments
require("todo-comments").setup({
	signs = false,

	-- Highlighting is disabled on purpose: treesitter already colors TODO,
	-- FIXME, HACK, etc. inside comments, so the plugin's colored blocks would
	-- only duplicate (and clash with) it. The plugin is kept just for the
	-- fzf-lua picker (:TodoFzfLua) and the ]t / [t navigation, which rely on
	-- the search pattern and not on the highlight.
	--
	-- See: lua/plugins/fzf.lua
	-- See: lua/plugins/treesitter.lua
	highlight = {
		before = "",
		keyword = "",
		after = "",
	},
	keywords = {
		XXX = { color = "warning" },
	},
})

vim.keymap.set("n", "]t", function()
	require("todo-comments").jump_next()
end, { desc = "Next todo comment" })

vim.keymap.set("n", "[t", function()
	require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })
