-- lua/keymaps/files.lua

-- Helpers

local km = vim.keymap.set

-- Normal-mode mapping shorthand
local function map(lhs, rhs, desc, opts)
	km("n", lhs, rhs, vim.tbl_extend("force", { desc = desc }, opts or {}))
end

-- Returns the absolute path of the current file, or nil (with a message) if none
local function current_file()
	local file = vim.fn.expand("%:p")
	if file == "" then
		print("No file in buffer")
		return nil
	end
	return file
end

-- Copies a non-empty value to the system clipboard
local function yank(value)
	if value == "" then
		return
	end
	vim.fn.setreg("+", value)
end

-- Maps a key that yanks the result of a filename-modifier expression (see :help filename-modifiers)
local function yank_map(lhs, modifier, desc)
	map(lhs, function()
		yank(vim.fn.expand(modifier))
	end, desc)
end

-- Navigation and working directory

-- Set the working directory to the current file's directory
map("<leader>nw", "<cmd>Setwd<CR>", "Set working directory to current file")

-- Print the current working directory
map("<leader>.", function()
	vim.notify("Current directory: " .. vim.fn.getcwd(), vim.log.levels.INFO)
end, "Show current working directory", { silent = true })

-- File operations

-- Prompt for a new file path, create missing parent directories, and open it
map("<leader>nf", function()
	local current_dir = vim.fn.expand("%:p:h")
	if current_dir == "" or current_dir == "." then
		current_dir = vim.fn.getcwd()
	end

	local file = vim.fn.input("New file: ", current_dir .. "/", "file")
	if file == "" then
		return
	end

	local dir = vim.fn.fnamemodify(file, ":h")
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
	vim.cmd("edit " .. vim.fn.fnameescape(file))
end, "Create new file")

-- Prompt for a new path, save the buffer there, and delete the old file
map("<leader>nr", function()
	local old = vim.fn.expand("%:p")
	local new = vim.fn.input("Rename to: ", old, "file")
	if new == "" or new == old then
		return
	end

	vim.cmd("saveas " .. vim.fn.fnameescape(new))
	vim.fn.delete(old)
	vim.cmd("bd " .. vim.fn.bufnr(old))
end, "Rename current file")

-- Permanently delete the current file after confirmation and close its buffer
map("<leader>nk", function()
	local file = current_file()
	if not file then
		return
	end

	if vim.fn.confirm("Delete " .. file .. "?", "&Yes\n&No", 2) ~= 1 then
		return
	end

	if vim.fn.delete(file) ~= 0 then
		vim.notify("Failed to delete: " .. file, vim.log.levels.ERROR)
		return
	end
	vim.cmd("bd!")
	print("Deleted: " .. file)
end, "Delete current file")

-- Add or remove the executable permission of the current file
map("<leader>nx", function()
	local file = current_file()
	if not file then
		return
	end

	local is_exec = vim.fn.executable(file) == 1
	vim.fn.system({ "chmod", is_exec and "-x" or "+x", file })
	print((is_exec and "Removed" or "Added") .. " executable permission: " .. file)
end, "Toggle executable permission on current file")

-- Reveal the current file in the operating system's file explorer
map("<leader>ne", function()
	local file = current_file()
	if not file then
		return
	end

	local os_name = require("utils.system").get_os()
	if os_name == "mac" then
		vim.fn.system({ "open", "-R", file })
	elseif os_name == "windows" then
		-- explorer.exe parses the raw command line and needs backslashes,
		-- so go through os.execute (cmd.exe) with a plain string instead of an argv list
		local win_path = file:gsub("/", "\\")
		os.execute(string.format('start "" explorer.exe /select,"%s"', win_path))
	else
		-- xdg-open can't select a file, so open the containing folder
		vim.fn.system({ "xdg-open", vim.fn.fnamemodify(file, ":h") })
	end
end, "Reveal current file in file explorer")

-- Yank paths

yank_map("<leader>yp", "%:p", "Yank absolute file path")
yank_map("<leader>yr", "%:.", "Yank relative file path")
yank_map("<leader>yn", "%:t", "Yank file name")
yank_map("<leader>yd", "%:p:h", "Yank containing directory path")

-- Copy the relative file path and cursor line number as file:line
map("<leader>yl", function()
	local path = vim.fn.expand("%:.")
	if path == "" then
		return
	end
	yank(path .. ":" .. vim.fn.line("."))
end, "Yank file:line reference")
