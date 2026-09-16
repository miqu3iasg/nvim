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

-- Copy the current file's absolute path to the system clipboard
km("n", "<leader>ny", function()
  local path = vim.fn.expand("%:p")
  if path == "" then
    print("No file in buffer")
    return
  end
  vim.fn.setreg("+", path)
  print("Copied path: " .. path)
end, { desc = "Copy absolute file path to clipboard" })

-- Copy the current file's path relative to the working directory
km("n", "<leader>nr", function()
  local path = vim.fn.expand("%:.")
  if path == "" then
    print("No file in buffer")
    return
  end
  vim.fn.setreg("+", path)
  print("Copied relative path: " .. path)
end, { desc = "Copy relative file path to clipboard" })

-- Copy the containing directory's absolute path
-- Useful for terminal navigation and file manager operations
km("n", "<leader>nh", function()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    print("No file in buffer")
    return
  end
  vim.fn.setreg("+", dir)
  print("Copied directory: " .. dir)
end, { desc = "Copy containing directory path to clipboard" })

-- Copy a file:line reference for use in pull requests, chat, and TODOs
km("n", "<leader>ns", function()
  local path = vim.fn.expand("%:.")
  if path == "" then
    print("No file in buffer")
    return
  end
  local ref = path .. ":" .. vim.fn.line(".")
  vim.fn.setreg("+", ref)
  print("Copied: " .. ref)
end, { desc = "Copy file:line reference to clipboard" })

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
