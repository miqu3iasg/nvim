-- lua/keymaps/files.lua

local km = vim.keymap.set

-- Set the working directory to the current file's directory
km("n", "<leader>nw", "<cmd>Setwd<CR>", { desc = "Set working directory to current file" })

-- Create a new file, creating missing parent directories as needed
km("n", "<leader>nf", function()
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
end, { desc = "Create new file" })

-- Permanently delete the current file after confirmation
km("n", "<leader>nk", function()
  local file = vim.fn.expand("%:p")
  if file == "" then
    print("No file in buffer")
    return
  end
  local confirm = vim.fn.confirm("Delete " .. file .. "?", "&Yes\n&No", 2)
  if confirm == 1 then
    vim.fn.delete(file)
    vim.cmd("bd!")
    print("Deleted: " .. file)
  end
end, { desc = "Delete current file" })

-- Display the current working directory
km("n", "<leader>.", ":pwd<CR>", { desc = "Show current working directory" })

-- Move the current file to Neovim's data directory trash
-- Use this as the default alternative to permanent deletion
km("n", "<leader>nz", function()
  local file = vim.fn.expand("%:p")
  if file == "" then
    print("No file in buffer")
    return
  end
  local trash_dir = vim.fn.stdpath("data") .. "/trash"
  if vim.fn.isdirectory(trash_dir) == 0 then
    vim.fn.mkdir(trash_dir, "p")
  end
  local dest = trash_dir .. "/" .. os.date("%Y%m%d-%H%M%S") .. "-" .. vim.fn.fnamemodify(file, ":t")
  local confirm = vim.fn.confirm("Move to trash: " .. file .. "?", "&Yes\n&No", 2)
  if confirm ~= 1 then
    return
  end
  local ok, err = os.rename(file, dest)
  if not ok then
    print("Failed to trash file: " .. (err or "unknown error"))
    return
  end
  vim.cmd("bd!")
  print("Trashed to: " .. dest)
end, { desc = "Move current file to trash (soft delete)" })

-- Toggle the executable permission of the current file
-- Useful for shell scripts and other executable files
km("n", "<leader>nx", function()
  local file = vim.fn.expand("%:p")
  if file == "" then
    print("No file in buffer")
    return
  end
  local is_exec = vim.fn.executable(file) == 1
  vim.fn.system({ "chmod", is_exec and "-x" or "+x", file })
  print((is_exec and "Removed" or "Added") .. " executable permission: " .. file)
end, { desc = "Toggle executable permission on current file" })

-- Yank file info to the system clipboard
local function yank(value)
  if value == "" then
    return
  end
  vim.fn.setreg("+", value)
end

km("n", "<leader>yp", function()
  yank(vim.fn.expand("%:p"))
end, { desc = "Yank absolute file path" })

km("n", "<leader>yr", function()
  yank(vim.fn.expand("%:."))
end, { desc = "Yank relative file path" })

km("n", "<leader>yn", function()
  yank(vim.fn.expand("%:t"))
end, { desc = "Yank file name" })

-- Useful for terminal navigation and file manager operations
km("n", "<leader>yd", function()
  yank(vim.fn.expand("%:p:h"))
end, { desc = "Yank containing directory path" })

-- Useful for pull requests, chat, and TODOs
km("n", "<leader>yl", function()
  local path = vim.fn.expand("%:.")
  if path == "" then
    return
  end
  yank(path .. ":" .. vim.fn.line("."))
end, { desc = "Yank file:line reference" })

-- Reveal the current file in the operating system's file explorer
-- macOS selects the file; Linux opens its containing directory
km("n", "<leader>ne", function()
  local utils = require("utils")
  local os_name = utils.get_os()
  local file = vim.fn.expand("%:p")
  if file == "" then
    print("No file in buffer")
    return
  end
  if os_name == "mac" then
    vim.fn.system({ "open", "-R", file })
  elseif os_name == "windows" then
    -- explorer.exe parses the raw command line itself (not argv), and is
    -- picky about forward slashes, so go through cmd.exe with a plain
    -- string instead of vim.fn.system's argv-list form.
    -- os.execute always shells out via cmd.exe on Windows, regardless of
    -- vim's 'shell' setting, so this works even though 'shell' is powershell.
    local win_path = file:gsub("/", "\\")
    os.execute(string.format('start "" explorer.exe /select,"%s"', win_path))
  else
    -- Linux: fall back to opening the containing folder, since most
    -- file managers don't support "select this file" via xdg-open
    vim.fn.system({ "xdg-open", vim.fn.fnamemodify(file, ":h") })
  end
end, { desc = "Reveal current file in file explorer" })
