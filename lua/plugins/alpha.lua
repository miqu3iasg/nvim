-- ~/.config/nvim/lua/plugins/alpha.lua
--
-- Minimalist but information-dense dashboard:
--   - Header: weekday + time.
--   - Workspace: cwd, git branch, uncommitted changes.
--   - Recent commits of the current repo.
--   - Recent files with full path (dimmed directory, highlighted
--     filename). First 10 get a number/`0` shortcut; the rest are
--     still clickable/enterable, just without a dedicated key.
--   - Other recent projects (git roots outside the current cwd),
--     clickable to cd + open a file finder there.
--   - Essential commands in two columns.
--   - Footer: nvim version + plugin load stats.
--
-- Colors are NOT hardcoded: the highlight groups below are linked to
-- standard colorscheme groups (Function, Comment, String, Normal), so
-- the dashboard adapts automatically when you switch themes -- even
-- at runtime, via :colorscheme.

local MRU_COUNT = 15
local PROJECTS_COUNT = 5
local COMMITS_COUNT = 5
local OLDFILES_SCAN_LIMIT = 50 -- how many oldfiles entries to check for other projects

-- Layout style: try both and see which one you like.
--   true  -> flush left, like a normal text buffer
--   false -> centered as a single block (original style)
local LEFT_ALIGN = true
local LEFT_MARGIN = 2 -- indentation used when LEFT_ALIGN is true

-- ~~~ Colors: link our groups to the active colorscheme's groups ~~~
local function link_highlights()
  local links = {
    AlphaIndex = "Function", -- file index number
    AlphaDir = "Comment",    -- directory / secondary info (dimmed)
    AlphaFile = "Normal",    -- filename / primary info (highlighted)
    AlphaKey = "String",     -- command shortcut key / git branch / commit hash
    AlphaLabel = "Normal",   -- command description
    AlphaTitle = "Comment",  -- section titles
    AlphaFooter = "Comment", -- header / footer
  }
  for name, target in pairs(links) do
    vim.api.nvim_set_hl(0, name, { link = target, default = true })
  end
end

link_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = link_highlights })

-- ~~~ Data: header (weekday + time) ~~~
local function header_entry()
  local text = os.date("%A, %d %B  ·  %H:%M")
  return { text = text, hl = { { "AlphaFooter", 0, #text } } }
end

-- ~~~ Data: workspace (cwd + git branch + changes) ~~~
local function workspace_entry()
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
  local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("%s+$", "")
  local has_git = vim.v.shell_error == 0 and branch ~= ""

  local segments = { { text = cwd, hl = "AlphaFile" } }

  if has_git then
    table.insert(segments, { text = "   ", hl = "AlphaDir" })
    table.insert(segments, { text = branch, hl = "AlphaKey" })

    local status = vim.fn.system("git status --porcelain 2>/dev/null")
    local modified, untracked = 0, 0
    for line in status:gmatch("[^\n]+") do
      if line:match("^%?%?") then
        untracked = untracked + 1
      else
        modified = modified + 1
      end
    end

    if modified > 0 then
      table.insert(segments, { text = string.format("   %d modified", modified), hl = "AlphaDir" })
    end
    if untracked > 0 then
      table.insert(segments, { text = string.format("   %d untracked", untracked), hl = "AlphaDir" })
    end
    if modified == 0 and untracked == 0 then
      table.insert(segments, { text = "   clean", hl = "AlphaDir" })
    end
  end

  local text, hl = "", {}
  for _, seg in ipairs(segments) do
    local start = #text
    text = text .. seg.text
    table.insert(hl, { seg.hl, start, #text })
  end
  return { text = text, hl = hl }
end

-- ~~~ Data: recent commits of the current repo ~~~
local function get_recent_commits(count)
  local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("%s+$", "")
  if vim.v.shell_error ~= 0 or branch == "" then
    return {}
  end

  local fmt = "%h¦%s¦%cr" -- hash, subject, relative date -- ¦ is unlikely to collide
  local cmd = string.format("git log -n %d --pretty=format:'%s' 2>/dev/null", count, fmt)
  local log = vim.fn.systemlist(cmd)

  local commits = {}
  for _, line in ipairs(log) do
    local hash, msg, rel = line:match("^(.-)¦(.-)¦(.*)$")
    if hash then
      table.insert(commits, { hash = hash, msg = msg, rel = rel })
    end
  end
  return commits
end

local function commit_line(commit)
  local msg = commit.msg
  if #msg > 55 then
    msg = msg:sub(1, 52) .. "..."
  end
  local text = string.format("%s  %s  %s", commit.hash, msg, commit.rel)

  local hash_end = #commit.hash
  local msg_start = hash_end + 2
  local msg_end = msg_start + #msg

  return {
    text = text,
    hl = {
      { "AlphaKey",  0,         hash_end },
      { "AlphaFile", msg_start, msg_end },
      { "AlphaDir",  msg_end,   #text },
    },
  }
end

-- ~~~ Data: footer (nvim version + plugin stats) ~~~
local function footer_entry()
  local v = vim.version()
  local nvim_ver = string.format("nvim %d.%d.%d", v.major, v.minor, v.patch)

  local ok, lazy = pcall(require, "lazy")
  local text = nvim_ver
  if ok then
    local stats = lazy.stats()
    local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
    text = string.format("%s   %d/%d plugins   %.2fms", nvim_ver, stats.loaded, stats.count, ms)
  end
  return { text = text, hl = { { "AlphaFooter", 0, #text } } }
end

-- ~~~ Data: recent files ~~~
local function get_oldfiles(count)
  local files = {}
  for _, file in ipairs(vim.v.oldfiles) do
    if #files >= count then
      break
    end
    if not file:match("^%a+://") and vim.fn.filereadable(file) == 1 then
      table.insert(files, vim.fn.fnamemodify(file, ":p"))
    end
  end
  return files
end

-- splits "~/dir/sub/" from "file.ext", already normalized with ~
local function split_path(full)
  local home = vim.env.HOME
  local display = full
  if home and vim.startswith(full, home) then
    display = "~" .. full:sub(#home + 1)
  end
  local dir, file = display:match("^(.*/)([^/]+)$")
  return dir or "", file or display
end

-- only the first 10 files get a dedicated single-key shortcut (1-9, 0);
-- beyond that, items are still buttons (navigable/clickable) but with
-- no bound key, to avoid clashing with letters used by `commands` below
local function index_key(i)
  if i <= 9 then
    return tostring(i)
  elseif i == 10 then
    return "0"
  end
  return nil
end

local function file_line(i, full_path)
  local key = index_key(i)
  local label = tostring(i)
  local dir, file = split_path(full_path)
  local text = string.format("%s  %s%s", label, dir, file)

  local dir_start = #label + 2 -- 2 spaces after the index
  local dir_end = dir_start + #dir
  local file_end = dir_end + #file

  return {
    text = text,
    key = key,
    open = full_path,
    hl = {
      { "AlphaIndex", 0,         #label },
      { "AlphaDir",   dir_start, dir_end },
      { "AlphaFile",  dir_end,   file_end },
    },
  }
end

-- ~~~ Data: other recent projects (git roots outside the current cwd) ~~~
local function get_recent_projects(count)
  local cwd = vim.fn.getcwd()
  local seen, projects = {}, {}
  local scanned = 0

  for _, file in ipairs(vim.v.oldfiles) do
    if #projects >= count or scanned >= OLDFILES_SCAN_LIMIT then
      break
    end
    if not file:match("^%a+://") and vim.fn.filereadable(file) == 1 then
      scanned = scanned + 1
      local dir = vim.fn.fnamemodify(file, ":p:h")
      local root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel 2>/dev/null")
      [1]
      if root and root ~= "" and root ~= cwd and not seen[root] then
        seen[root] = true
        table.insert(projects, root)
      end
    end
  end

  return projects
end

local function project_line(root)
  local home = vim.env.HOME
  local display = root
  if home and vim.startswith(root, home) then
    display = "~" .. root:sub(#home + 1)
  end
  local parent, name = display:match("^(.*/)([^/]+)/?$")
  parent = parent or ""
  name = name or display
  local text = parent .. name

  return {
    text = text,
    -- no `key`: navigate with j/k + <CR>, or click
    open = root,
    on_press = function()
      vim.cmd("cd " .. vim.fn.fnameescape(root))
      require("fzf-lua").files() -- swap for require("telescope.builtin").find_files() if you use telescope
    end,
    hl = {
      { "AlphaDir",  0,       #parent },
      { "AlphaFile", #parent, #text },
    },
  }
end

-- ~~~ Commands: single cell + join into a 2-column row ~~~
local function cmd_cell(key, label)
  local text = string.format("%s  %s", key, label)
  return {
    text = text,
    hl = {
      { "AlphaKey",   0,        #key },
      { "AlphaLabel", #key + 2, #text },
    },
  }
end

local function cmd_row(cell_a, cell_b, col_width)
  local pad = string.rep(" ", math.max(1, col_width - #cell_a.text))
  local text = cell_a.text .. pad .. (cell_b and cell_b.text or "")
  local hl = {}
  for _, r in ipairs(cell_a.hl) do
    table.insert(hl, r)
  end
  if cell_b then
    local offset = #cell_a.text + #pad
    for _, r in ipairs(cell_b.hl) do
      table.insert(hl, { r[1], r[2] + offset, r[3] + offset })
    end
  end
  return { text = text, hl = hl }
end

-- ~~~ Rendering: applies left margin and turns it into an alpha element ~~~
-- An entry becomes a clickable/enterable button if it has `open` or a
-- custom `on_press`. `key`, if present, additionally wires up a
-- single-key shortcut. Entries with neither are rendered as plain text.
local function to_element(entry, margin)
  local pad = string.rep(" ", margin)
  local val = pad .. entry.text
  local hl = {}
  for _, r in ipairs(entry.hl) do
    table.insert(hl, { r[1], r[2] + margin, r[3] + margin })
  end

  if entry.open or entry.on_press then
    local press = entry.on_press
        or function()
          vim.cmd("edit " .. vim.fn.fnameescape(entry.open))
        end

    local opts = { cursor = margin, hl = hl }
    if entry.key then
      opts.keymap = { "n", entry.key, "", { noremap = true, silent = true } }
    end

    return { type = "button", val = val, on_press = press, opts = opts }
  end

  return { type = "text", val = val, opts = { hl = hl } }
end

local function section_title(text, margin)
  return { type = "text", val = string.rep(" ", margin) .. text, opts = { hl = "AlphaTitle" } }
end

-- ~~~ Builds the whole layout ~~~
local function build_layout()
  local files = get_oldfiles(MRU_COUNT)
  local file_entries = {}
  for i, f in ipairs(files) do
    table.insert(file_entries, file_line(i, f))
  end

  local commits = get_recent_commits(COMMITS_COUNT)
  local commit_entries = {}
  for _, c in ipairs(commits) do
    table.insert(commit_entries, commit_line(c))
  end

  local projects = get_recent_projects(PROJECTS_COUNT)
  local project_entries = {}
  for _, p in ipairs(projects) do
    table.insert(project_entries, project_line(p))
  end

  -- edit the available actions and keys here
  local commands = {
    { cmd_cell("n", "new file"),  cmd_cell("s", "restore session") },
    { cmd_cell("f", "find file"), cmd_cell("e", "file explorer") },
    { cmd_cell("g", "grep text"), cmd_cell("q", "quit") },
  }

  local col_width = 0
  for _, row in ipairs(commands) do
    col_width = math.max(col_width, #row[1].text)
  end
  col_width = col_width + 4

  local cmd_lines = {}
  for _, row in ipairs(commands) do
    table.insert(cmd_lines, cmd_row(row[1], row[2], col_width))
  end

  local header = header_entry()
  local workspace = workspace_entry()
  local footer = footer_entry()

  local max_width = math.max(#header.text, #workspace.text, #footer.text)
  for _, group in ipairs({ file_entries, commit_entries, project_entries, cmd_lines }) do
    for _, e in ipairs(group) do
      max_width = math.max(max_width, #e.text)
    end
  end

  local margin
  if LEFT_ALIGN then
    margin = LEFT_MARGIN
  else
    local win_width = vim.api.nvim_win_get_width(0)
    margin = math.max(0, math.floor((win_width - max_width) / 2))
  end

  -- rough line count, used only for vertical centering when LEFT_ALIGN = false
  local content_lines = 1 + 1 + 1                               -- header + pad + workspace
  if #commit_entries > 0 then
    content_lines = content_lines + 2 + 1 + 1 + #commit_entries -- pad+title+pad+lines
  end
  content_lines = content_lines + 2 + 1 + 1 + #file_entries
  if #project_entries > 0 then
    content_lines = content_lines + 2 + 1 + 1 + #project_entries
  end
  content_lines = content_lines + 2 + 1 + 1 + #cmd_lines + 2 + 1 -- commands + pad + footer

  local top_pad
  if LEFT_ALIGN then
    top_pad = 2
  else
    local win_height = vim.api.nvim_win_get_height(0)
    top_pad = math.max(1, math.floor((win_height - content_lines) / 2))
  end

  local layout = { { type = "padding", val = top_pad } }

  table.insert(layout, to_element(header, margin))
  table.insert(layout, { type = "padding", val = 1 })
  table.insert(layout, to_element(workspace, margin))

  if #commit_entries > 0 then
    table.insert(layout, { type = "padding", val = 2 })
    table.insert(layout, section_title("recent commits", margin))
    table.insert(layout, { type = "padding", val = 1 })
    for _, e in ipairs(commit_entries) do
      table.insert(layout, to_element(e, margin))
    end
  end

  table.insert(layout, { type = "padding", val = 2 })
  table.insert(layout, section_title("recent files", margin))
  table.insert(layout, { type = "padding", val = 1 })
  for _, e in ipairs(file_entries) do
    table.insert(layout, to_element(e, margin))
  end

  if #project_entries > 0 then
    table.insert(layout, { type = "padding", val = 2 })
    table.insert(layout, section_title("other projects", margin))
    table.insert(layout, { type = "padding", val = 1 })
    for _, e in ipairs(project_entries) do
      table.insert(layout, to_element(e, margin))
    end
  end

  table.insert(layout, { type = "padding", val = 2 })
  table.insert(layout, section_title("commands", margin))
  table.insert(layout, { type = "padding", val = 1 })
  for _, e in ipairs(cmd_lines) do
    table.insert(layout, to_element(e, margin))
  end

  table.insert(layout, { type = "padding", val = 2 })
  table.insert(layout, to_element(footer, margin))

  return layout
end

return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")

    local function setup()
      alpha.setup({ layout = build_layout(), opts = { margin = 0, redraw_on_resize = true } })
    end

    setup()

    vim.api.nvim_create_autocmd("User", { pattern = "AlphaReady", callback = setup })
    vim.api.nvim_create_autocmd("VimResized", {
      callback = function()
        if vim.bo.filetype == "alpha" then
          setup()
        end
      end,
    })

    -- strip the number gutter every time the alpha window gets focus.
    -- Using vim.schedule + re-checking the filetype makes this win even
    -- against other autocmds (e.g. a "number toggle" on BufEnter/WinEnter)
    -- that would otherwise turn numbers back on right after us.
    local function strip_gutter(buf)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "alpha" then
          return
        end
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"
        vim.opt_local.cursorline = false
      end)
    end

    vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "WinEnter" }, {
      pattern = "*",
      callback = function(args)
        if vim.bo[args.buf].filetype == "alpha" then
          strip_gutter(args.buf)
        end
      end,
    })

    -- command keys: wired up once, when the alpha buffer is created
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "alpha",
      callback = function(args)
        local map = function(key, cmd)
          vim.keymap.set("n", key, cmd, { buffer = args.buf, silent = true })
        end
        map("n", "<Cmd>enew | startinsert<CR>")
        map("f", function()
          require("fzf-lua").files() -- swap for require("telescope.builtin").find_files() if you use telescope
        end)
        map("g", function()
          require("fzf-lua").live_grep() -- swap for require("telescope.builtin").live_grep()
        end)
        map("s", function()
          require("persistence").load() -- remove if you don't use persistence.nvim
        end)
        map("e", "<Cmd>Oil<CR>")        -- swap for your explorer (Oil, nvim-tree, etc.)
        map("q", "<Cmd>qa<CR>")
      end,
    })
  end,
}
