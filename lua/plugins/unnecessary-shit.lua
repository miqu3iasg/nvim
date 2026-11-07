-- lua/plugins/unnecessary-shit.lua

-- Miscellaneous quality-of-life mini.nvim modules (and other small plugins)
-- that are not essential, but make editing feel nicer.
--
-- Commenting (gc/gcc/gc<motion>) is Neovim's builtin since 0.12, so there is
-- no mini.comment setup here.

local ai = require("mini.ai")
local ts = ai.gen_spec.treesitter

-- One liners
require("mini.align").setup({})

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

-- Register the ]t/[t jumps and :Todos (search/navigation of
-- TODO|FIXME|HACK|BUG|XXX comments); see lua/features/todos.lua.
-- <leader>ft (fzf grep) lives in lua/plugins/fzf.lua.
require("features.todos").setup()
