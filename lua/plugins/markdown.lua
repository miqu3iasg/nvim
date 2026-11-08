-- lua/plugins/markdown.lua

-- Markdown note-taking workflow built on obsidian.nvim and img-clip.nvim, so
-- notes in an Obsidian vault can be created, linked and searched without
-- leaving Neovim, and images can be pasted straight from the clipboard.
--
-- The vault path must point to an existing Obsidian vault. Notes are searched
-- and navigated through fzf-lua, so `fzf.lua` must be loaded before this file.
-- obsidian.nvim, img-clip.nvim and plenary.nvim must be installed through the
-- plugin manager.
--
-- Pasted images are saved in `<project-root>/attachments`. Inside the vault they
-- use the wikilink template, and anywhere else they use the standard Markdown
-- link.
--
-- Markdown language-server features require Marksman to be both installed and
-- enabled in `lua/plugins/lsp.lua`. The Obsidian app is only needed to open
-- notes in it. On Arch Linux:
--
-- $ sudo pacman -S obsidian
--
-- Install Marksman through Mason:
--
-- :MasonInstall marksman
--
-- See: after/ftplugin/markdown.lua
-- See: lua/plugins/lsp.lua
-- See: ~/.local/bin/on
-- See: https://github.com/HakonHarnes/img-clip.nvim
-- See: https://github.com/obsidian-nvim/obsidian.nvim
-- See: https://github.com/nvim-lua/plenary.nvim
-- See: https://github.com/ibhagwan/fzf-lua
-- See: https://github.com/artempyanykh/marksman

local VAULT_PATH = "~/personal/documents/vault"

local DEFAULT_TEMPLATE = "note_template"
local INBOX_TEMPLATE = "inbox_template"

local km = vim.keymap.set

require("img-clip").setup({
	default = {
		dir_path = function()
			local root = vim.fs.root(0, { ".git", ".obsidian" }) or vim.fn.expand("%:p:h")
			return root .. "/attachments"
		end,
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

local function new_inbox_capture()
	local title = "CAP-" .. os.date("%Y%m%d-%H%M%S")
	vim.cmd("Obsidian new " .. title)
	-- The template is applied on the next tick, once the new note is open.
	vim.schedule(function()
		vim.cmd("Obsidian template " .. INBOX_TEMPLATE)
	end)
end

km("n", "<leader>os", "<cmd>Obsidian quick_switch<cr>", { desc = "Obsidian: jump to a note" })
km("n", "<leader>oi", "<cmd>Obsidian new<cr>", { desc = "Obsidian: quick capture" })
km("n", "<leader>oc", new_inbox_capture, { desc = "Obsidian: new inbox capture" })
km("n", "<leader>od", "<cmd>Obsidian today<cr>", { desc = "Obsidian: daily note (today)" })
km("n", "<leader>ow", "<cmd>e ~/personal/documents/vault/Dumping.md<cr>", { desc = "Open Dumping.md note" })
km("n", "<leader>ot", "<cmd>Obsidian new_from_template<cr>", { desc = "Obsidian: new note (pick template)" })

local opts = {
	legacy_commands = false,

	workspaces = {
		{ name = "Brain", path = VAULT_PATH },
	},
	new_notes_location = "notes_subdir",
	notes_subdir = "_inbox",

	ui = {
		enable = false,
	},
	footer = {
		enabled = false,
	},
	frontmatter = {
		enabled = false,
	},

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

	daily_notes = {
		-- The year is computed when this file loads.
		folder = "journal/daily/" .. os.date("%Y"),
		date_format = "DD-MM-YYYY",
		workdays_only = true,
	},

	templates = {
		folder = "system/templates",
		date_format = "YYYY-MM-DD",
		time_format = "HH:mm",
		substitutions = {
			["DATE:YYYYMMDD-HHmmss"] = function()
				return os.date("%Y%m%d-%H%M%S")
			end,
			["DATE: YYYYMMDD-HHmmss"] = function()
				return os.date("%Y%m%d-%H%M%S")
			end,
			-- Legacy format, kept for older templates.
			["DATE:YYYYMMDDHHmm"] = function()
				return os.date("%Y%m%d%H%M")
			end,
			["DATE: YYYYMMDDHHmm"] = function()
				return os.date("%Y%m%d%H%M")
			end,
		},
	},

	note_id_func = function(title)
		-- The title may already carry the prefix, as in `new_inbox_capture`.
		if title and title:match("^CAP%-%d+%-%d+") then
			return title
		end

		local prefix = "CAP-" .. os.date("%Y%m%d-%H%M%S")

		if title == nil or title == "" then
			return prefix
		end

		local slug = title:gsub(" ", "-"):gsub("[^%w-]", ""):lower()

		if slug == "" then
			return prefix
		end

		return prefix .. "-" .. slug
	end,
}

require("obsidian").setup(opts)

vim.api.nvim_create_autocmd("CmdlineChanged", {
	group = vim.api.nvim_create_augroup("obsidian_cmdline_wildtrigger", { clear = true }),
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
