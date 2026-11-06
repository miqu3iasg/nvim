-- lua/plugins/compile-mode.lua

-- Runs build commands into a `*compilation*` buffer, like Emacs' `M-x compile`.
-- The command runs asynchronously, errors are highlighted and `<cr>` on an
-- error line jumps to the file and line it reports.
--
-- Requires plenary.nvim (see config/pack.lua).
--
-- Commands:
--   :Compile {cmd}      run {cmd} (prompts for one when called without arguments)
--   :Recompile          rerun the last command
--   :NextError          jump to the next error of the compilation buffer
--   :PrevError          jump to the previous error
--
-- Only inside the `*compilation*` buffer:
--   :CompileInterrupt   stop the running command (mapped to <C-c>)
--
-- See: https://github.com/ej-shafran/compile-mode.nvim

local map = vim.keymap.set

---Registers a keymap with a description.
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param desc string
local function cmap(mode, lhs, rhs, desc)
	map(mode, lhs, rhs, { desc = desc })
end

-- The plugin reads this table when a command runs, so it can be set after
-- `vim.pack.add()` has loaded it.
---@module "compile-mode"
---@type CompileModeOpts
vim.g.compile_mode = {
	-- Compilation commands per file-type
	default_command = {
		["*"] = "make -k ",
		python = "python %",
		lua = "lua %",
		c = "cc -o %:r.out % && ./%:r.out",
		cpp = "c++ -std=c++23 -o %:r.out % && ./%:r.out",
		java = "javac % && java %:r",
		go = "go run %",
	},

	-- Control how ANSI escape sequences are handled in compilation output.
	-- :h compile-mode.ansi_color
	ansi_color = {
		kind = "filter",
		-- Baleia options to pass to baleia.setup() when kind is "render".
		-- Use `{}` for baleia's defaults, or a table of baleia options.
		-- :h compile-mode.ansi_color
		baleia_options = {},
	},

	-- Expand commands, like `:!` (e.g. `:Compile echo %`)
	-- :h compile-mode.bang_expansion
	-- NOTE: must be true for `%` and `%:r` to be expanded in the command.
	bang_expansion = true,

	-- Configure additional entering/leaving directory regexes.
	-- :h compile-mode.directory_change_matchers
	directory_change_matchers = {},

	-- Configure additional error regexes.
	-- :h compile-mode-errors
	error_regexp_table = {},

	-- List of filename regexes to ignore errors from.
	-- :h compile-mode.error_ignore_file_list
	error_ignore_file_list = {},

	-- Automatically jump to the first error.
	-- :h compile-mode.auto_jump_to_first_error
	auto_jump_to_first_error = false,

	-- How long to highlight an error's location when jumping to it.
	-- :h compile-mode.error_locus_highlight
	error_locus_highlight = 500,

	-- Use Neovim diagnostics instead of opening the compilation buffer.
	-- :h compile-mode.use_diagnostics
	use_diagnostics = false,

	-- Default to calling `:Compile` for `:Recompile`
	-- when there's no previous command.
	-- :h compile-mode.recompile_no_fail
	recompile_no_fail = false,

	-- Ask to save unsaved buffers before compiling.
	-- :h compile-mode.ask_about_save
	ask_about_save = true,

	-- Ask to interrupt already running commands.
	-- :h compile-mode.ask_to_interrupt
	ask_to_interrupt = true,

	-- The name for the compilation buffer.
	-- :h compile-mode.buffer_name
	buffer_name = "*compilation*",

	-- The format for the time information
	-- at the top of the compilation buffer
	-- :h compile-mode.time_format
	time_format = "%a %b %e %H:%M:%S",

	-- Maximum number of lines allowed in the compilation buffer.
	-- :h compile-mode.max_lines
	max_lines = nil,

	-- List of regexes to hide from the output.
	-- :h compile-mode.hidden_output
	hidden_output = {},

	-- A table of environment variables to pass to commands.
	-- :h compile-mode.environment
	environment = nil,

	-- Clear all environment variables for each command.
	-- :h compile-mode.clear_environment
	clear_environment = false,

	-- Fix compilation for plugins like `nvim-cmp`.
	-- :h compile-mode.input_word_completion
	input_word_completion = false,

	-- Hide the compliation buffer.
	-- :h compile-mode.hidden_buffer
	hidden_buffer = false,

	-- Automatically focus the compilation buffer.
	-- :h compile-mode.focus_compilation_buffer
	focus_compilation_buffer = false,

	-- Automatically move the cursor to the end of the compilation buffer.
	-- :h compile-mode.auto_scroll
	auto_scroll = true,

	-- Jump back past the end/beginning of the errors
	-- with `:NextError`/`:PrevError`
	-- :h compile-mode.use_circular_error_navigation
	use_circular_error_navigation = false,

	-- Print debug information.
	-- :h compile-mode.debug
	debug = true,

	-- Use a pseudo terminal for command execution.
	-- :h compile-mode.use_pseudo_terminal
	use_pseudo_terminal = false,

	-- Control how OSC sequences are handled (hyperlinks, titles, etc.)
	-- The default `handlers` is empty; when `kind` is `"render"`, built-in
	-- handlers for OSC 0/1/2/8/9 are injected automatically.
	-- :h compile-mode.ansi_osc
	ansi_osc = {
		kind = "render",
		handlers = {},
	},
}

-- `:Compile` without arguments opens the plugin's prompt, already filled in
-- with the `default_command` for the current filetype.
cmap("n", "<leader>cc", "<cmd>Compile<cr>", "Compile (prompt with default)")
cmap("n", "<leader>cr", "<cmd>Recompile<cr>", "Recompile (last command)")

cmap("n", "<leader>ck", function()
	require("compile-mode").interrupt()
end, "Compile: interrupt")

cmap("n", "]e", "<cmd>NextError<cr>", "Next compilation error")
cmap("n", "[e", "<cmd>PrevError<cr>", "Prev compilation error")
