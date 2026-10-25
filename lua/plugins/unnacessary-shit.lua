-- lua/plugins/unnacessary-shit.lua

-- The most unnecessary shit that I installed intead of coding (newbie edition)

local ai = require("mini.ai")
local ts = ai.gen_spec.treesitter

require("mini.align").setup({})
require("mini.comment").setup({})
require("mini.splitjoin").setup({})

local ai_opts = {
	n_lines = 500,
	custom_textobjects = {
		f = ts({ a = "@function.outer", i = "@function.inner" }),
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

-- vim-tmux-navigator
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
