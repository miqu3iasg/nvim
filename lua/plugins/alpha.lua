-- ~/.config/nvim/lua/plugins/alpha.lua
--
-- Raw, no-nonsense dashboard. No logo, no icons, no fluff.
-- Two MRU (Most Recently Used) sections + the three shortcuts you actually need.
--
-- Layout rule: the whole block is centered as a single unit (one shared left
-- margin computed from the longest line), but every line inside that block
-- is left-aligned -- no per-line auto-centering, no ragged edges.

local MRU_COUNT = 12 -- files per section

-- Return up to `count` real, readable files from oldfiles, most recent first
local function get_oldfiles(count)
  local files = {}
  for _, file in ipairs(vim.v.oldfiles) do
    if #files >= count then
      break
    end
    if not file:match("^%a+://") and vim.fn.filereadable(file) == 1 then
      table.insert(files, vim.fn.fnamemodify(file, ":p")) -- normalize to full path
    end
  end
  return files
end

-- Raw (unpadded) entry describing one line. `hl` ranges are relative to
-- `text`, and get shifted once the shared left margin is known.
local function raw_line(text, hl, key, on_press)
  return { text = text, hl = hl, key = key, on_press = on_press }
end

local function mru_entry(key, path, open_target)
  local text = string.format("[%s] %s", key, path)
  return raw_line(text, {
    { "AlphaMruIndex", 0,        #key + 2 },
    { "AlphaMruPath",  #key + 2, #text },
  }, key, function()
    vim.cmd("edit " .. vim.fn.fnameescape(open_target))
  end)
end

local function title_entry(text)
  return raw_line(text, { { "AlphaMruHeader", 0, #text } }, nil, nil)
end

local function button_entry(key, label, cmd)
  local text = string.format("[%s] %s", key, label)
  return raw_line(text, { { "AlphaButtons", 0, #text } }, key, function()
    vim.cmd(cmd)
  end)
end

-- Turn a raw entry into a real alpha element, left-aligned, prefixed by the
-- shared `margin` so the whole block reads as centered on screen.
local function render(entry, margin)
  local pad = string.rep(" ", margin)
  local val = pad .. entry.text
  local hl = {}
  for _, range in ipairs(entry.hl) do
    table.insert(hl, { range[1], range[2] + margin, range[3] + margin })
  end

  if entry.key then
    return {
      type = "button",
      val = val,
      on_press = entry.on_press,
      opts = {
        shortcut = entry.key,
        cursor = margin + 1,
        keymap = { "n", entry.key, "", { noremap = true, silent = true } },
        hl = hl,
      },
    }
  end

  return { type = "text", val = val, opts = { hl = hl } }
end

local function build_opts()
  local files = get_oldfiles(MRU_COUNT)
  local home = vim.env.HOME or ""
  local home_label = home ~= "" and home or "/home/user"
  local letters = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l" }

  -- Section 1: "MRU" -- full absolute paths
  local mru_full = {}
  for i, file in ipairs(files) do
    table.insert(mru_full, mru_entry(tostring(i - 1), file, file))
  end

  -- Section 2: "MRU /home/<user>" -- same files, path relative to $HOME
  local mru_home = {}
  for i, file in ipairs(files) do
    local rel = file
    if home ~= "" and vim.startswith(file, home .. "/") then
      rel = file:sub(#home + 2)
    end
    table.insert(mru_home, mru_entry(letters[i] or tostring(i), rel, file))
  end

  local buttons = {
    button_entry("n", "New file", "enew | startinsert"),
    button_entry("/", "Find file", "FzfLua files"),
    button_entry("q", "Quit", "qa"),
  }

  local mru_title = title_entry("MRU")
  local home_title = title_entry("MRU " .. home_label)

  -- One shared left margin for the whole block, based on the longest line
  local all_entries = { mru_title, home_title }
  for _, e in ipairs(mru_full) do
    table.insert(all_entries, e)
  end
  for _, e in ipairs(mru_home) do
    table.insert(all_entries, e)
  end
  for _, e in ipairs(buttons) do
    table.insert(all_entries, e)
  end

  local max_width = 0
  for _, e in ipairs(all_entries) do
    max_width = math.max(max_width, #e.text)
  end
  local win_width = vim.api.nvim_win_get_width(0)
  local margin = math.max(0, math.floor((win_width - max_width) / 2))

  -- Vertical centering: count rendered lines (entries + paddings below)
  local content_lines = 1 + #mru_full + 1 + 1 + #mru_home + 2 + #buttons
  local win_height = vim.api.nvim_win_get_height(0)
  local top_pad = math.max(1, math.floor((win_height - content_lines) / 2))

  local layout = { { type = "padding", val = top_pad } }

  table.insert(layout, render(mru_title, margin))
  table.insert(layout, { type = "padding", val = 1 })
  for _, e in ipairs(mru_full) do
    table.insert(layout, render(e, margin))
  end

  table.insert(layout, { type = "padding", val = 1 })
  table.insert(layout, render(home_title, margin))
  table.insert(layout, { type = "padding", val = 1 })
  for _, e in ipairs(mru_home) do
    table.insert(layout, render(e, margin))
  end

  table.insert(layout, { type = "padding", val = 2 })
  for _, b in ipairs(buttons) do
    table.insert(layout, render(b, margin))
  end

  return {
    layout = layout,
    opts = {
      margin = 0,
      redraw_on_resize = true,
    },
  }
end

return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  enabled = false,
  -- No "opts" field on purpose: the whole config is built and applied
  -- directly in `config`, so nothing merges over it and drops the layout.
  config = function()
    local function setup()
      require("alpha").setup(build_opts())
    end

    setup()

    -- Recompute every time the dashboard opens (fresh oldfiles list)
    vim.api.nvim_create_autocmd("User", {
      pattern = "AlphaReady",
      callback = setup,
    })

    -- Recompute on resize so it stays centered
    vim.api.nvim_create_autocmd("VimResized", {
      callback = function()
        if vim.bo.filetype == "alpha" then
          setup()
        end
      end,
    })
  end,
}
