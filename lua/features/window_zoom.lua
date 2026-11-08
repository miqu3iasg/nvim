-- lua/features/window_zoom.lua

-- Zooms the focused window by showing it as the only window of a new tab, while
-- the original layout stays intact in its own tab. Toggling again closes the
-- zoom tab and brings the layout back.
--
-- The state lives in the tabpage-local variable `t:zoomed`, which the
-- statusline reads. Since the zoom is a tab, closing it by other means, such as
-- `:tabclose` or `:tabonly`, also ends it.
--
-- See: lua/features/statusline.lua

local M = {}

---@return boolean
function M.is_zoomed()
	return vim.t.zoomed == true
end

---Close the zoom tab when zoomed. Otherwise open one, unless the current window
---is already alone, since a single window in a single tab is already full
---screen.
function M.toggle()
	if vim.fn.tabpagenr("$") > 1 and M.is_zoomed() then
		vim.cmd("tabclose")
	elseif vim.fn.winnr("$") > 1 then
		vim.cmd("tab split")
		vim.t.zoomed = true
	end
end

return M
