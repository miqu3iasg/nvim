-- lua/utils/bigfile.lua

-- Detects big buffers, such as large files or minified output, so other parts of
-- the config can switch off features that make them sluggish, like Treesitter,
-- completion and folds. The verdict is cached per buffer in `vim.b.bigfile`.
--
-- See: lua/plugins/completions.lua

local M = {}

-- Cutoff values shared by every feature that checks for big buffers.
local max_size = 1.5 * 1024 * 1024
local max_line_length = 1000
local sample_lines = 200

---Check whether a buffer should be treated as a big file. A buffer is big when
---its file is larger than `max_size` bytes, or when any of its first
---`sample_lines` lines is longer than `max_line_length` characters.
---
---The verdict is cached in `vim.b[bufnr].bigfile` and never recomputed, so a
---file that grows after being opened keeps its original verdict.
---@param bufnr? integer Defaults to the current buffer.
---@return boolean
function M.is_big(bufnr)
	bufnr = bufnr or 0

	if vim.b[bufnr].bigfile ~= nil then
		return vim.b[bufnr].bigfile
	end

	-- The file size is the cheapest signal and catches logs, generated assets and
	-- dumps, which tend to punish parsers and language servers.
	local filename = vim.api.nvim_buf_get_name(bufnr)
	local stat = filename ~= "" and vim.uv.fs_stat(filename) or nil
	if stat and stat.size > max_size then
		vim.b[bufnr].bigfile = true
		return true
	end

	-- Long lines are common in minified output. Only the beginning of the file is
	-- sampled so the check itself stays cheap.
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local line_limit = math.min(line_count, sample_lines)
	local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, line_limit, false)
	if ok then
		for _, line in ipairs(lines) do
			if #line > max_line_length then
				vim.b[bufnr].bigfile = true
				return true
			end
		end
	end

	vim.b[bufnr].bigfile = false
	return false
end

return M
