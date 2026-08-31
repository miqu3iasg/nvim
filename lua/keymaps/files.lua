local km = vim.keymap.set

-- File and folder operations (all under <leader>n)

km("n", "<leader>nw", "<cmd>Setwd<CR>", { desc = "Set working directory to current file" })

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

km("n", "<leader>nb", "<cmd>enew<CR>", { desc = "New empty buffer (:enew)" })

km("n", "<leader>np", function()
  local dir = vim.fn.input("New folder: ", vim.fn.expand("%:p:h") .. "/", "dir")
  if dir ~= "" then
    vim.fn.mkdir(dir, "p")
    print("Created folder: " .. dir)
  end
end, { desc = "Create new folder" })

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

-- Soft delete: moves the file into a trash dir under nvim's own data
-- path instead of removing it permanently. Complements <leader>nk --
-- use this one by default, fall back to nk when you really mean it.
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

-- Move/rename the current file on disk and open it at the new location
km("n", "<leader>ng", function()
  local old_path = vim.fn.expand("%:p")
  if old_path == "" then
    print("No file in buffer")
    return
  end
  local new_path = vim.fn.input("Move/rename to: ", old_path, "file")
  if new_path == "" or new_path == old_path then
    return
  end
  local new_dir = vim.fn.fnamemodify(new_path, ":h")
  if vim.fn.isdirectory(new_dir) == 0 then
    vim.fn.mkdir(new_dir, "p")
  end
  local ok, err = os.rename(old_path, new_path)
  if not ok then
    print("Failed to move file: " .. (err or "unknown error"))
    return
  end
  local old_buf = vim.api.nvim_get_current_buf()
  vim.cmd("edit " .. vim.fn.fnameescape(new_path))
  vim.api.nvim_buf_delete(old_buf, { force = true })
  print("Moved to: " .. new_path)
end, { desc = "Move/rename current file" })

-- Duplicate the current file on disk and open the copy
km("n", "<leader>nc", function()
  local old_path = vim.fn.expand("%:p")
  if old_path == "" then
    print("No file in buffer")
    return
  end
  local new_path = vim.fn.input("Copy to: ", old_path, "file")
  if new_path == "" or new_path == old_path then
    return
  end
  local new_dir = vim.fn.fnamemodify(new_path, ":h")
  if vim.fn.isdirectory(new_dir) == 0 then
    vim.fn.mkdir(new_dir, "p")
  end
  local ok, err = vim.uv.fs_copyfile(old_path, new_path)
  if not ok then
    print("Failed to copy file: " .. (err or "unknown error"))
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(new_path))
  print("Copied to: " .. new_path)
end, { desc = "Duplicate current file" })

-- Toggle executable permission (handy for shell scripts)
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

-- Copy the current file's path relative to cwd
km("n", "<leader>nr", function()
  local path = vim.fn.expand("%:.")
  if path == "" then
    print("No file in buffer")
    return
  end
  vim.fn.setreg("+", path)
  print("Copied relative path: " .. path)
end, { desc = "Copy relative file path to clipboard" })

-- Copy just the containing directory's path (handy for cd, drag-drop
-- targets, pasting into other tools)
km("n", "<leader>nh", function()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    print("No file in buffer")
    return
  end
  vim.fn.setreg("+", dir)
  print("Copied directory: " .. dir)
end, { desc = "Copy containing directory path to clipboard" })

-- Copy a "path:line" reference (handy for PRs, chat, TODOs)
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

-- Reveal the current file in the OS file explorer (Finder/Explorer/file manager)
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
    -- file managers don't support "select this file" via xdg-open.
    vim.fn.system({ "xdg-open", vim.fn.fnamemodify(file, ":h") })
  end
end, { desc = "Reveal current file in file explorer" })
