-- lua/keymaps/files.lua

local km = vim.keymap.set

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

-- Copy the relative file path and cursor line number as file:line.
km("n", "<leader>yl", function()
  local path = vim.fn.expand("%:.")
  if path == "" then
    return
  end
  yank(path .. ":" .. vim.fn.line("."))
end, { desc = "Yank file:line reference" })

-- Reveal the current file in the operating system's file explorer
km("n", "<leader>ne", function()
  local utils = require("utils.system")
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
    -- so go through os.execute (cmd.exe) with a plain string instead of an argv list
    local win_path = file:gsub("/", "\\")
    os.execute(string.format('start "" explorer.exe /select,"%s"', win_path))
  else
    -- xdg-open can't select a file, so open the containing folder
    vim.fn.system({ "xdg-open", vim.fn.fnamemodify(file, ":h") })
  end
end, { desc = "Reveal current file in file explorer" })
