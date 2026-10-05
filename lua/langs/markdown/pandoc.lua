-- lua/langs/markdown/pandoc.lua

-- It converts the current buffer to PDF or EPUB by running `pandoc`
-- asynchronously through `vim.system`, so the editor never blocks. The
-- result is always opened in zathura. A preview mode builds and opens the
-- document once, then rebuilds it on every `:w`; zathura reloads the file
-- by itself. Nothing is notified on success: the only message you will
-- ever see is an error, carrying pandoc's stderr. You can install the
-- required packages running on Arch Linux the following commands:
--
--   $ sudo pacman -S pandoc-cli zathura zathura-pdf-mupdf
--
--   $ sudo pacman -S texlive-latex texlive-latexextra
--
-- See: https://pandoc.org/MANUAL.html
-- See: https://neovim.io/doc/user/lua.html#vim.system()

local M = {}

M.formats = { "pdf", "epub" }
M.opts = {
  "--standalone",
  "--pdf-engine=xelatex",
  "-V", "geometry:margin=2.5cm",
}
M.viewer = "zathura"

local function notify_error(msg)
  vim.notify("pandoc: " .. vim.trim(msg), vim.log.levels.ERROR)
end

function M.build(fmt, on_done)
  fmt = (fmt and fmt ~= "") and fmt or "pdf"
  local input = vim.api.nvim_buf_get_name(0)

  if input == "" then
    return notify_error("save the buffer first")
  end

  local dir = vim.fn.fnamemodify(input, ":p:h") .. "/build"
  vim.fn.mkdir(dir, "p")
  local out = dir .. "/" .. vim.fn.fnamemodify(input, ":t:r") .. "." .. fmt

  local cmd = { "pandoc", input, "-o", out }
  vim.list_extend(cmd, M.opts)
  if vim.fn.filereadable("defaults.yaml") == 1 then
    vim.list_extend(cmd, { "-d", "defaults.yaml" })
  end

  vim.system(cmd, { text = true }, vim.schedule_wrap(function(r)
    if r.code ~= 0 then
      return notify_error(r.stderr)
    end
    if on_done then on_done(out) end
  end))
end

function M.open(file)
  vim.system({ M.viewer, file }, { detach = true })
end

-- preview build and open once; rebuild on every :w (zathura reloads by itself)
function M.preview(fmt)
  local buf = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup("PandocPreview" .. buf, { clear = true })
  if vim.b[buf].pandoc_preview then
    vim.b[buf].pandoc_preview = false
    return
  end
  vim.b[buf].pandoc_preview = true
  M.build(fmt, M.open)
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    buffer = buf,
    callback = function() M.build(fmt) end,
  })
end

function M.setup()
  vim.api.nvim_buf_create_user_command(0, "Pandoc", function(a)
    M.build(a.args, M.open)
  end, { nargs = "?", complete = function() return M.formats end })

  vim.api.nvim_buf_create_user_command(0, "PandocPreview", function(a)
    M.preview(a.args)
  end, { nargs = "?", complete = function() return M.formats end })

  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", "<localleader>" .. lhs, rhs, { buffer = true, desc = "Pandoc: " .. desc })
  end
  map("pb", function() M.build("pdf") end, "build pdf")
  map("pp", function() M.preview("pdf") end, "preview (watch)")
  map("pf", function()
    vim.ui.select(M.formats, { prompt = "Format:" }, function(f)
      if f then M.build(f, M.open) end
    end)
  end, "choose format")
end

return M
