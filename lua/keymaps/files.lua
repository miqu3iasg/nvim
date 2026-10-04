-- lua/keymaps/files.lua

local km = vim.keymap.set

-- Move a file from src to dest and return true on success, or false plus an error message on failure.
-- It first tries vim.uv.fs_rename, which is atomic but fails with EXDEV when src and dest are on
-- different filesystems (e.g. /tmp -> ~/.local/share).
-- On EXDEV it copies src to dest and then unlinks src; if the unlink fails, the copy at dest is
-- removed so no duplicate is left behind.
-- Any other rename error is returned as-is without trying the fallback.
local function move_file(src, dest)
  local ok, err, errname = vim.uv.fs_rename(src, dest)
  if ok then
    return true
  end
  if errname ~= "EXDEV" then
    return false, err
  end

  local copied, copy_err = vim.uv.fs_copyfile(src, dest)
  if not copied then
    return false, copy_err
  end

  local removed, rm_err = vim.uv.fs_unlink(src)
  if not removed then
    vim.uv.fs_unlink(dest) -- remove the copy if the original can't be unlinked
    return false, rm_err
  end
  return true
end

-- Set the working directory to the current file's directory.
km("n", "<leader>nw", "<cmd>Setwd<CR>", { desc = "Set working directory to current file" })

-- Prompt for a new file path, create missing parent directories, and open it.
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

-- Permanently delete the current file after confirmation and close its buffer.
km("n", "<leader>nk", function()
  local file = vim.fn.expand("%:p")
  if file == "" then
    print("No file in buffer")
    return
  end
  local confirm = vim.fn.confirm("Delete " .. file .. "?", "&Yes\n&No", 2)
  if confirm ~= 1 then
    return
  end
  if vim.fn.delete(file) ~= 0 then
    vim.notify("Failed to delete: " .. file, vim.log.levels.ERROR)
    return
  end
  vim.cmd("bd!")
  print("Deleted: " .. file)
end, { desc = "Delete current file" })

-- Prompt for a new path, save the buffer there, and delete the old file.
km("n", "<leader>nr", function()
  local old = vim.fn.expand("%:p")
  local new = vim.fn.input("Rename to: ", old, "file")
  if new ~= "" and new ~= old then
    vim.cmd("saveas " .. vim.fn.fnameescape(new))
    vim.fn.delete(old)
    vim.cmd("bd " .. vim.fn.bufnr(old))
  end
end, { desc = "Rename current file" })

-- Print the current working directory.
km("n", "<leader>.", function()
  vim.notify(vim.fn.getcwd(), vim.log.levels.INFO)
end, { desc = "Show current working directory", silent = true })

-- Move the current file to a timestamped path in Neovim's data trash directory after confirmation.
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
  local ok, err = move_file(file, dest)
  if not ok then
    vim.notify("Failed to trash file: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end
  vim.cmd("bd!")
  print("Trashed to: " .. dest)
end, { desc = "Move current file to trash (soft delete)" })

-- Add or remove the executable permission of the current file.
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

-- Copy a non-empty value to the system clipboard.
local function yank(value)
  if value == "" then
    return
  end
  vim.fn.setreg("+", value)
end

-- Copy the absolute path of the current file.
km("n", "<leader>yp", function()
  yank(vim.fn.expand("%:p"))
end, { desc = "Yank absolute file path" })

-- Copy the path of the current file relative to the working directory.
km("n", "<leader>yr", function()
  yank(vim.fn.expand("%:."))
end, { desc = "Yank relative file path" })

-- Copy the name of the current file.
km("n", "<leader>yn", function()
  yank(vim.fn.expand("%:t"))
end, { desc = "Yank file name" })

-- Copy the absolute path of the current file's directory.
km("n", "<leader>yd", function()
  yank(vim.fn.expand("%:p:h"))
end, { desc = "Yank containing directory path" })

-- Copy the cursor line's file:line reference, text, and diagnostics.
km("n", "<leader>ye", function()
  local lnum = vim.fn.line(".") - 1
  local diags = vim.diagnostic.get(0, { lnum = lnum })
  if #diags == 0 then
    return vim.notify("No diagnostics on this line", vim.log.levels.WARN)
  end
  local out = { vim.fn.expand("%:.") .. ":" .. (lnum + 1), vim.api.nvim_get_current_line(), "" }
  for _, d in ipairs(diags) do
    out[#out + 1] = string.format("[%s] %s", vim.diagnostic.severity[d.severity], d.message)
  end
  vim.fn.setreg("+", table.concat(out, "\n"))
  vim.notify("Copied line + diagnostics")
end, { desc = "Yank file:line, text and diagnostics" })

-- Copy the relative file path and cursor line number as file:line.
km("n", "<leader>yl", function()
  local path = vim.fn.expand("%:.")
  if path == "" then
    return
  end
  yank(path .. ":" .. vim.fn.line("."))
end, { desc = "Yank file:line reference" })

-- Reveal the current file in the operating system's file explorer.
-- macOS: runs `open -R`, which opens Finder with the file selected.
-- Windows: runs `explorer.exe /select`, which opens Explorer with the file selected.
-- Linux: runs `xdg-open` on the containing directory, so the file itself is not selected.
-- Prints a message and does nothing if the buffer has no file.
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
    -- explorer.exe parses the raw command line and needs backslashes,
    -- so go through os.execute (cmd.exe) with a plain string instead of an argv list.
    local win_path = file:gsub("/", "\\")
    os.execute(string.format('start "" explorer.exe /select,"%s"', win_path))
  else
    -- xdg-open can't select a file, so open the containing folder.
    vim.fn.system({ "xdg-open", vim.fn.fnamemodify(file, ":h") })
  end
end, { desc = "Reveal current file in file explorer" })
