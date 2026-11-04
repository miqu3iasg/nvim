-- lua/features/window_zoom.lua

-- Zoom of the focused window: temporarily shows it full screen (as the only
-- window of a new tab) while keeping the original layout intact. The toggle
-- state lives in the tabpage-local variable `t:zoomed`, which is also read by
-- the statusline (see lua/features/statusline.lua) to show a `[Z]` indicator.

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
