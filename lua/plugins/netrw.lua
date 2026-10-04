-- lua/plugins/netrw.lua
-- netrw configured to mimic oil/canola (disable oil.lua to avoid conflicts)

-- Off by default (oil is the main explorer). To use netrw instead, set
-- enabled = true here and add `enabled = false` to oil.lua
local enabled = false
if not enabled then
  return {}
end

-- Global options (must be set before netrw loads)
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 1               -- long listing: name, size, mtime
vim.g.netrw_timefmt = "%d/%m %H:%M"
vim.g.netrw_sizestyle = "H"             -- human-readable sizes
vim.g.netrw_keepdir = 1                 -- browsing doesn't change cwd
vim.g.netrw_sort_by = "name"
vim.g.netrw_sort_sequence = [[[\/]$,*]] -- directories first

-- Show hidden files by default; `gh` (built-in) toggles
vim.g.netrw_hide = 0
vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]

-- Splits and preview
vim.g.netrw_preview = 1 -- vertical preview
vim.g.netrw_alto = 1    -- horizontal split opens below
vim.g.netrw_altv = 1    -- vertical split opens right
vim.g.netrw_winsize = 50

-- Full path of the entry under the cursor
local function cursor_path()
  local dir = vim.b.netrw_curdir
  if not dir then
    return nil
  end
  local ok, word = pcall(vim.fn["netrw#Call"], "NetrwGetWord")
  if not ok or not word or word == "" then
    word = vim.fn.expand("<cfile>")
  end
  if word == "" then
    return nil
  end
  return (dir .. "/" .. word):gsub("//+", "/")
end

local app_map = {
  pdf = { "zathura" },
  djvu = { "zathura" },
  epub = { "zathura" },
  cbz = { "zathura" },
  cbr = { "zathura" },
  xps = { "zathura" },

  png = { "imv" },
  jpg = { "imv" },
  jpeg = { "imv" },
  gif = { "imv" },
  webp = { "imv" },
  bmp = { "imv" },
  svg = { "imv" },

  mp4 = { "mpv" },
  mkv = { "mpv" },
  webm = { "mpv" },
  mov = { "mpv" },
  avi = { "mpv" },
  mp3 = { "mpv" },
  flac = { "mpv" },
  wav = { "mpv" },
}

-- Open with a specific app by extension, else OS default
local function open_with_app()
  local path = cursor_path()
  if not path then
    return
  end
  local ext = path:match("^.+%.(.+)$")
  ext = ext and ext:lower() or nil
  local cmd = ext and app_map[ext]
  if cmd then
    vim.fn.jobstart(vim.list_extend(vim.deepcopy(cmd), { path }), { detach = true })
  else
    vim.ui.open(path)
  end
end

-- Cycle sort: name -> time -> size
local sorts = { "name", "time", "size" }
local function cycle_sort()
  local current = vim.g.netrw_sort_by or "name"
  local idx = 1
  for i, s in ipairs(sorts) do
    if s == current then
      idx = i
    end
  end
  vim.g.netrw_sort_by = sorts[(idx % #sorts) + 1]
  vim.api.nvim_feedkeys(vim.keycode("<Plug>NetrwRefresh"), "m", false)
  vim.notify("netrw sort: " .. vim.g.netrw_sort_by)
end

-- Return to previous buffer, else delete the netrw buffer
local function close()
  if not pcall(vim.cmd, "Rexplore") then
    pcall(vim.cmd, "bdelete")
  end
end

local function setup_buffer()
  local buf = vim.api.nvim_get_current_buf()
  local function map(lhs, rhs, opts)
    opts = vim.tbl_extend("force", { buffer = buf, silent = true, nowait = true }, opts or {})
    vim.keymap.set("n", lhs, rhs, opts)
  end

  -- Disable netrw defaults
  for _, key in ipairs({ "<C-c>", "<C-h>", "<C-l>" }) do
    pcall(vim.keymap.del, "n", key, { buffer = buf })
  end

  -- remap = true reuses netrw's built-in mappings
  map("h", "-", { remap = true })    -- parent directory
  map("<BS>", "-", { remap = true })
  map("l", "<CR>", { remap = true }) -- open file or enter directory
  map("r", "<Plug>NetrwRefresh", { remap = true })
  map("sh", "o", { remap = true })   -- horizontal split
  map("sv", "v", { remap = true })   -- vertical split
  map("gp", "p", { remap = true })   -- preview
  map("gs", cycle_sort)
  map("gx", open_with_app)
  map("gy", function()
    local path = cursor_path()
    if path then
      vim.fn.setreg("+", path)
      vim.notify("Copied: " .. path)
    end
  end)
  map("q", close)

  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = "no"
  vim.opt_local.cursorline = true
end

local group = vim.api.nvim_create_augroup("NetrwOilLike", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "netrw",
  callback = setup_buffer,
})
-- netrw reapplies its mappings when changing directory
vim.api.nvim_create_autocmd("BufEnter", {
  group = group,
  callback = function()
    if vim.bo.filetype == "netrw" then
      setup_buffer()
    end
  end,
})

local function explore(path)
  vim.cmd("Explore " .. vim.fn.fnameescape(path))
end

vim.keymap.set("n", "go", "<CMD>Explore<CR>", { desc = "Open parent directory" })
vim.keymap.set("n", "gb", function() explore(vim.fn.expand("~/.config")) end, { desc = "Open ~/.config directory" })
vim.keymap.set("n", "gw", function() explore(vim.fn.expand("~/repos")) end, { desc = "Open repos directory" })
vim.keymap.set("n", "g~", function() explore(vim.fn.expand("~")) end, { desc = "Open home directory" })
vim.keymap.set("n", "g.", function() explore(vim.fn.getcwd()) end, { desc = "Open cwd" })

-- lazy.nvim requires a table (empty = no plugins)
return {}
