-- lua/langs/markdown/keymaps/init.lua

-- Aggregates every topic module in this folder behind a single
-- setup(bufnr), so lua/langs/markdown/init.lua only has to require
-- "langs.markdown.keymaps" instead of each topic individually. Add a
-- new topic file here and register it in the list below.

local topics = {
  "langs.markdown.keymaps.headings",
  "langs.markdown.keymaps.editing",
  "langs.markdown.keymaps.lists",
  "langs.markdown.keymaps.links",
  "langs.markdown.keymaps.inserts",
  "langs.markdown.keymaps.codeblock",
  "langs.markdown.keymaps.movement",
}

local M = {}

function M.setup(bufnr)
  for _, topic in ipairs(topics) do
    require(topic).setup(bufnr)
  end
end

return M
