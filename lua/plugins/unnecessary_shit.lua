-- lua/plugins/unnacessary-shit.lua

-- The most unnecessary shit that I installed intead of coding (newbie edition)

return {
	{
		"echasnovski/mini.nvim",
		version = false,
		event = "VeryLazy",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			local ai = require("mini.ai")
			local ts = ai.gen_spec.treesitter

			require("mini.align").setup({
				mappings = {
					start = "ga",
					start_with_preview = "gA",
				},
			})

			require("mini.comment").setup({
				mappings = {
					comment = "gc",
					comment_line = "gcc",
					comment_visual = "gc",
					textobject = "gc",
				},
			})

			require("mini.splitjoin").setup({
				mappings = {
					toggle = "gS",
					split = "",
					join = "",
					detect = "",
				},
				options = {
					split_join_toggle = {
						separators = { "[", "]", "{", "}", "(", ")" },
					},
				},
			})

			local ai_opts = {
				n_lines = 500,
				custom_textobjects = {
					f = ts({ a = "@function.outer", i = "@function.inner" }),
					c = ts({ a = "@class.outer", i = "@class.inner" }),
					a = ts({ a = "@parameter.outer", i = "@parameter.inner" }),

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
		end,
	},

	-- Treesitter queries provider for mini.ai
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		lazy = true,
	},

	{
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
		},
		keys = {
			{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
			{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
	},

	-- I don't like icons btw.
	{ "nvim-tree/nvim-web-devicons", enabled = false },
}
