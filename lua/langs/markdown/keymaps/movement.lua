-- lua/langs/markdown/keymaps/movement.lua

-- Move by visual line instead of physical line. Matters once 'wrap'
-- is on (settings.lua), since a single logical line can span several
-- screen rows; a count still falls back to physical-line motion.

local utils = require("langs.markdown.utils")

local M = {}

function M.setup(bufnr)
  utils.map(bufnr, "n", "j", "v:count == 0 ? 'gj' : 'j'", "Move down by visual line", { expr = true })
  utils.map(bufnr, "n", "k", "v:count == 0 ? 'gk' : 'k'", "Move up by visual line", { expr = true })
end

return M
