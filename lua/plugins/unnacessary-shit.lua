-- lua/plugins/unnacessary-shit.lua

-- The most unnecessary shit that I installed intead of coding (newbie edition)

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

-- require("mini.cmdline").setup()

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

-- Default mappings move to <Plug> so they don't clash with these prefixes
require("mini.surround").setup({
	mappings = {
		add = "<Plug>(surround-add)",
		delete = "<Plug>(surround-delete)",
		replace = "<Plug>(surround-replace)",
		find = "sf",
		find_left = "sF",
		highlight = "sh",
		update_n_lines = "sn",
	},
})

local surrounds = {
	p = ")", -- parentheses
	b = "}", -- braces
	c = "]", -- brackets
	q = '"', -- double quotes
	s = "'", -- single quotes
	k = "`", -- backtick
	a = ">", -- angle brackets
}

local pending_char = nil

_G.__surround_add_operator = function(motion_type)
	local reselect = (motion_type == "line") and "'[V']" or "`[v`]"
	vim.cmd("normal! " .. reselect)
	vim.api.nvim_feedkeys(vim.keycode("<Plug>(surround-add)") .. pending_char, "mx", false)
end

for key, char in pairs(surrounds) do
	vim.keymap.set("n", "sa" .. key, function()
		pending_char = char
		vim.o.operatorfunc = "v:lua.__surround_add_operator"
		return "g@"
	end, { expr = true, desc = "Surround add " .. char })

	vim.keymap.set("x", "sa" .. key, "<Plug>(surround-add)" .. char, {
		remap = true,
		desc = "Surround add " .. char,
	})

	vim.keymap.set("n", "sd" .. key, "<Plug>(surround-delete)" .. char, {
		remap = true,
		desc = "Surround delete " .. char,
	})

	for key2, char2 in pairs(surrounds) do
		if key ~= key2 then
			vim.keymap.set("n", "qr" .. key .. key2, "<Plug>(surround-replace)" .. char .. char2, {
				remap = true,
				desc = "Surround replace " .. char .. " -> " .. char2,
			})
		end
	end
end

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
