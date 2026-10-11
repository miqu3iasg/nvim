-- after/ftplugin/typst.lua
-- See: lua/plugins/typst.lua

local o = vim.opt_local
o.wrap = true
o.linebreak = true
o.breakindent = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.spell = true
o.spelllang = "en,pt_br"
o.commentstring = "// %s"

local buf = vim.api.nvim_get_current_buf()

local function map(lhs, rhs, desc)
  vim.keymap.set("n", "<localleader>" .. lhs, rhs, { buffer = buf, desc = "Typst: " .. desc })
end

local function file()
  return vim.api.nvim_buf_get_name(buf)
end

local function tinymist(command, args)
  local client = vim.lsp.get_clients({ bufnr = buf, name = "tinymist" })[1]
  if not client then
    return vim.notify("tinymist is not attached to this buffer", vim.log.levels.WARN)
  end
  client:exec_cmd({ title = command, command = command, arguments = args })
end

-- Must match `outputPath` in plugins/lspconfig.lua ("$root/build/$dir/$name")
local function pdf_path()
  local client = vim.lsp.get_clients({ bufnr = buf, name = "tinymist" })[1]
  local root = (client and client.root_dir) or vim.fs.dirname(file())
  local rel = vim.fs.dirname(vim.fs.relpath(root, file()) or "")
  local name = vim.fn.fnamemodify(file(), ":t:r")
  return vim.fs.normalize(vim.fs.joinpath(root, "build", rel, name .. ".pdf"))
end

map("p", "<cmd>TypstPreviewToggle<cr>", "live preview (toggle)")
map("s", "<cmd>TypstPreviewSyncCursor<cr>", "sync cursor in preview")
map("e", function() tinymist("tinymist.exportPdf", { file() }) end, "export PDF")

map("o", function()
  local pdf = pdf_path()
  if vim.uv.fs_stat(pdf) then
    vim.ui.open(pdf, { cmd = { "zathura" } })
  else
    vim.notify("PDF not found: " .. pdf, vim.log.levels.WARN)
  end
end, "open PDF")

map("m", function() tinymist("tinymist.pinMain", { file() }) end, "pin this file as main")
map("M", function() tinymist("tinymist.pinMain", { vim.NIL }) end, "unpin main")
