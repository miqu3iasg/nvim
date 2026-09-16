-- lua/langs/markdown/settings.lua

local M = {}

-- Underlines markdown links by default; both the classic syntax
-- groups (in case treesitter highlighting is off for some reason)
-- and the markdown_inline treesitter captures. Re-applied on every
-- ColorScheme change, same pattern as render-markdown.lua's
-- set_colors().
local function underline_links()
  local groups = {
    "markdownLinkText", "markdownUrl", "mkdLink",
    "@markup.link.label.markdown_inline", "@markup.link.url.markdown_inline",
    "@text.uri", -- older treesitter capture name, kept for compatibility
  }

  for _, group in ipairs(groups) do
    local ok, current = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok then
      vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", current, { underline = true }))
    end
  end
end

function M.setup()
  -- Visual wrapping, respecting word boundaries. Display only, so it
  -- doesn't conflict with textwidth below
  vim.opt_local.wrap = true
  vim.opt_local.linebreak = true
  vim.opt_local.breakindent = true
  vim.opt_local.showbreak = "  "

  -- Spell check
  vim.opt_local.spell = true
  vim.opt_local.spelllang = { "pt_br", "en_us" }

  -- Prose formatting width, used by gq and exporters
  vim.opt_local.textwidth = 78

  -- No line numbers or sign column
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = "no"

  -- Fits list/nesting indentation better than the global default
  vim.opt_local.shiftwidth = 2

  underline_links()
  vim.api.nvim_create_augroup("MarkdownLinkUnderline", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = "MarkdownLinkUnderline",
    callback = underline_links,
  })
end

return M
