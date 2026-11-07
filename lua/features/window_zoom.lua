-- lua/features/window_zoom.lua

-- Zoom of the focused window: temporarily shows it full screen, as the only
-- window of a new tab, while the original layout stays intact in its own tab.
-- Toggling again closes the zoom tab and brings the layout back.
--
-- The state lives in the tabpage-local variable `t:zoomed`, which the
-- statusline reads to show the `[Z]` indicator. Since zoom is implemented as a
-- tab, closing it by other means (`:tabclose`, `:tabonly`) also ends it.
--
-- Usage:
--   require("features.window_zoom").toggle()
--
-- See: lua/features/statusline.lua

local M = {}

---Whether the focused tabpage currently shows a zoomed window.
---@return boolean
function M.is_zoomed()
	return vim.t.zoomed == true
end

---Toggle the zoom on the focused window.
---
--- * Zoomed: closes the zoom tab, which restores the original layout.
--- * Not zoomed: creates the zoom tab with `:tab split`, but only when the
---   current window is not already alone (a single window in a single tab is
---   already "full screen").
function M.toggle()
	if vim.fn.tabpagenr("$") > 1 and M.is_zoomed() then
		vim.cmd("tabclose")
	elseif vim.fn.winnr("$") > 1 then
		vim.cmd("tab split")
		vim.t.zoomed = true
	end
end

return M
