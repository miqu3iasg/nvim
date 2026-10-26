-- lua/plugins/markdown.lua

-- This configuration groups the plugins used for writing Markdown notes: image
-- pasting with img-clip.nvim and integration with the Obsidian desktop application
-- through obsidian.nvim.
--
-- All plugins are declared in `lua/config/pack.lua` and must be installed
-- before this file is loaded. Obsidian.nvim also depends on plenary.nvim and
-- fzf-lua. The `fzf.lua` plugin configuration must be loaded before this file
-- because fzf-lua is used as the picker for searching and navigating notes.
--
-- On Arch Linux, install Obsidian with pacman:
--
-- $ sudo pacman -S obsidian
--
-- The vault path below must point to an existing Obsidian vault.
--
-- Images pasted inside the vault use the `![[$FILE_NAME]]` wikilink template,
-- while images pasted anywhere else use the standard Markdown link template.
-- In both cases they are saved in `<project-root>/attachments`.
--
-- Marksman provides Markdown language-server features, including navigation,
-- document symbols and diagnostics. Install it through Mason:
--
-- :MasonInstall marksman
--
-- Installing Marksman is not enough: it must also be configured and enabled in
-- the Neovim LSP setup. The LSP configuration is located in
-- `lua/plugins/lsp.lua`; make sure Marksman is configured there for Markdown
-- buffers.
--
-- See: https://github.com/HakonHarnes/img-clip.nvim
-- See: https://github.com/obsidian-nvim/obsidian.nvim
-- See: https://github.com/nvim-lua/plenary.nvim
-- See: https://github.com/ibhagwan/fzf-lua
-- See: https://github.com/artempyanykh/marksman

local VAULT_PATH = "~/personal/documents/vault"

local DEFAULT_TEMPLATE = "note_template"
local INBOX_TEMPLATE = "inbox_template"

local km = vim.keymap.set

-- Images

require("img-clip").setup({
	default = {
		-- Always save images in <project-root>/attachments
		dir_path = function()
			local root = vim.fs.root(0, { ".git", ".obsidian" }) or vim.fn.expand("%:p:h")
			return root .. "/attachments"
		end,
		-- dir_path = "attachments",
		relative_to_current_file = false,
		relative_template_path = true,
		use_absolute_path = false,
		file_name = "%Y-%m-%d-%H-%M-%S",
		prompt_for_file_name = false,
		insert_mode_after_paste = false,
		embed_image_as_base64 = false,
		verbose = false,
		drag_and_drop = {
			enabled = true,
			insert_mode = true,
		},
	},

	filetypes = {
		markdown = {
			url_encode_path = true,
			template = "![$CURSOR]($FILE_PATH)",
			download_images = true,
		},
	},

	dirs = {
		[VAULT_PATH] = {
			url_encode_path = false,
			template = "![[$FILE_NAME]]",
		},
	},
})

-- Obsidian

local function new_inbox_capture()
	local title = "CAP-" .. os.date("%Y%m%d-%H%M%S")
	vim.cmd("Obsidian new " .. title)
	vim.schedule(function()
		vim.cmd("Obsidian template " .. INBOX_TEMPLATE)
	end)
end

-- Global mappings, available from any buffer or filetype
km("n", "<leader>os", "<cmd>Obsidian quick_switch<cr>", { desc = "Obsidian: jump to a note" })
km("n", "<leader>oi", "<cmd>Obsidian new<cr>", { desc = "Obsidian: quick capture" })
km("n", "<leader>oc", new_inbox_capture, { desc = "Obsidian: new inbox capture" })
km("n", "<leader>od", "<cmd>Obsidian today<cr>", { desc = "Obsidian: daily note (today)" })
km("n", "<leader>ow", "<cmd>e ~/personal/documents/vault/Dumping.md<cr>", { desc = "Open Dumping.md note" })
km("n", "<leader>ot", "<cmd>Obsidian new_from_template<cr>", { desc = "Obsidian: new note (pick template)" })

local opts = {
	legacy_commands = false,

	-- Workspace and note creation
	workspaces = {
		{ name = "Brain", path = VAULT_PATH },
	},
	new_notes_location = "notes_subdir",
	notes_subdir = "_inbox",

	-- UI and metadata
	ui = {
		enable = false,
	},
	footer = {
		enabled = false,
	},
	frontmatter = {
		enabled = false,
	},

	-- Links, attachments and completion
	link = {
		style = "wiki",
		format = "shortest",
	},
	attachments = {
		folder = "attachments",
	},
	completion = {
		min_chars = 2,
		match_case = true,
		create_new = true,
	},
	picker = {
		name = "fzf-lua",
	},

	-- Daily notes
	daily_notes = {
		-- The year used to be hardcoded, which breaks on January 1st.
		folder = "journal/daily/" .. os.date("%Y"),
		date_format = "DD-MM-YYYY",
		workdays_only = true,
	},

	-- Templates
	templates = {
		folder = "system/templates",
		date_format = "YYYY-MM-DD",
		time_format = "HH:mm",
		substitutions = {
			["DATE:YYYYMMDDHHmm"] = function()
				return os.date("%Y%m%d%H%M")
			end,
			-- Also handles the variant with a space after the colon.
			["DATE: YYYYMMDDHHmm"] = function()
				return os.date("%Y%m%d%H%M")
			end,
		},
	},

	-- Generate filenames from note titles instead of random IDs.
	note_id_func = function(title)
		if title == nil or title == "" then
			return tostring(os.time())
		end

		if title:match("^CAP%-%d+%-%d+$") then
			return title
		end

		return title:gsub(" ", "-"):gsub("[^%w-]", ""):lower()
	end,
}

require("obsidian").setup(opts)

-- Trigger command-line completion for partially typed Obsidian commands.
vim.api.nvim_create_autocmd("CmdlineChanged", {
	callback = function()
		if vim.fn.getcmdtype() ~= ":" then
			return
		end
		local cmdline = vim.fn.getcmdline()
		if not cmdline:match("^Obsidian[A-Za-z0-9]*$") then
			return
		end
		vim.fn.wildtrigger()
	end,
})

-- Register mappings only in buffers recognized as vault notes.
vim.api.nvim_create_autocmd("User", {
	pattern = "ObsidianNoteEnter",
	callback = function()
		local actions = require("obsidian.actions")

		local function map(mode, lhs, rhs, desc)
			km(mode, lhs, rhs, {
				buffer = true,
				silent = true,
				desc = desc,
			})
		end

		map(
			"n",
			"<leader>on",
			"<cmd>Obsidian template " .. DEFAULT_TEMPLATE .. "<cr>",
			"Insert default template into this note"
		)
		map("n", "<leader>oo", "<cmd>Obsidian open<cr>", "Open this note in the Obsidian app")
		map("n", "<leader>om", actions.move_note, "Move note to another folder")
		map("n", "<leader>or", vim.lsp.buf.rename, "Rename note")
		map("n", "<leader>of", actions.workspace_symbol, "Search notes, aliases and headings")
		map("n", "<leader>og", "<cmd>Obsidian search<cr>", "Search text in vault (grep)")
	end,
})
