-- lua/plugins/lisp.lua

-- Interactive REPL-driven evaluation for Lisp-family languages through Conjure,
-- configured here for Scheme with MIT Scheme as the REPL. Racket and Common Lisp
-- buffers also load Conjure.
--
-- Conjure is loaded lazily. The plugin is declared at the bottom of this file
-- and its scripts are only loaded on the first Scheme, Lisp, Racket or Clojure
-- buffer, right after `configure()` sets the globals that Conjure reads when it
-- starts.
--
-- Conjure must be declared in `pack.lua` and installed through the plugin
-- manager. The Tree-sitter parsers for scheme, commonlisp and racket are
-- installed by the list in `lua/plugins/treesitter.lua`.
--
-- Racket, rlwrap and the Tree-sitter CLI must be installed on the system.
-- `unbuffer`, which keeps the REPL output from being buffered, comes with
-- `expect`. On Arch Linux:
--
-- $ sudo pacman -S tree-sitter-cli racket rlwrap expect
--
-- MIT Scheme is available through the AUR:
--
-- $ yay -S mit-scheme
--
-- Building MIT Scheme 12.1 from the AUR may fail on Arch Linux. The glibc
-- defines `_POSIX_C_SOURCE` with a newer value than the source expects, so the
-- source tries to redefine the macro, and the build fails because warnings are
-- treated as errors (`-Werror`). Debian already provides an official patch.
--
-- One workaround is to edit the `PKGBUILD` in `~/.cache/yay/mit-scheme` and
-- update its `prepare()` function to adjust the macro with `sed`. Then remove
-- the cached build directories and rebuild:
--
-- $ rm -rf ~/.cache/yay/mit-scheme/src ~/.cache/yay/mit-scheme/pkg
-- $ cd ~/.cache/yay/mit-scheme
-- $ makepkg -si
--
-- See: lua/utils/lazy.lua
-- See: lua/plugins/treesitter.lua
-- See: https://github.com/Olical/conjure
-- See: https://web.mit.edu/scheme/current/doc/mit-scheme-user/Introduction.html
-- See: https://www.shido.info/lisp/scheme1_e.html
-- See: https://www.mail-archive.com/debian-bugs-closed@lists.debian.org/msg850823.html
-- See: https://aur.archlinux.org/packages/mit-scheme

local M = {}

---Set the Conjure globals. Called once per session by `utils.lazy`, before
---Conjure is loaded.
function M.configure()
	-- The local leader must be set before Conjure defines its mappings.
	if vim.g.maplocalleader == nil or vim.g.maplocalleader == "" then
		vim.g.maplocalleader = ","
	end

	vim.g["conjure#filetype#scheme"] = "conjure.client.scheme.stdio"
	vim.g["conjure#client#scheme#stdio#command"] = "unbuffer -p mit-scheme"

	-- A docked split on the far right replaces the floating HUD.
	vim.g["conjure#log#hud#enabled"] = false
	vim.g["conjure#log#botright"] = true
	vim.g["conjure#log#split#width"] = 0.5
	vim.opt.splitright = true

	vim.g["conjure#highlight#enabled"] = true

	vim.g["conjure#mapping#eval_current_form"] = "ee"
	vim.g["conjure#mapping#eval_root_form"] = "er"
	vim.g["conjure#mapping#eval_word"] = "ew"
	vim.g["conjure#mapping#eval_file"] = "ef"
	vim.g["conjure#mapping#eval_buf"] = "eb"
	vim.g["conjure#mapping#eval_visual"] = "E"
	vim.g["conjure#mapping#eval_motion"] = "E"
	vim.g["conjure#mapping#eval_marked_form"] = "em"
	vim.g["conjure#mapping#eval_previous"] = "ep"
	vim.g["conjure#mapping#eval_replace_form"] = "e!"

	vim.g["conjure#eval#comment_prefix"] = "; => "
	vim.g["conjure#mapping#eval_comment_current_form"] = "ece"
	vim.g["conjure#mapping#eval_comment_root_form"] = "ecr"
	vim.g["conjure#mapping#eval_comment_word"] = "ecw"

	vim.g["conjure#mapping#log_split"] = "ls"
	vim.g["conjure#mapping#log_vsplit"] = "lv"
	vim.g["conjure#mapping#log_tab"] = "lt"
	vim.g["conjure#mapping#log_buf"] = "le"
	vim.g["conjure#mapping#log_toggle"] = "lg"
	vim.g["conjure#mapping#log_close_visible"] = "lq"
	vim.g["conjure#mapping#log_reset_soft"] = "lr"
	vim.g["conjure#mapping#log_reset_hard"] = "lR"
	vim.g["conjure#mapping#log_jump_to_latest"] = "ll"

	vim.g["conjure#mapping#def_word"] = "gd"
	vim.g["conjure#mapping#doc_word"] = { "K" }

	-- Opens the log split on the first Scheme, Lisp or Racket buffer, on a
	-- best-effort basis. It is registered here so that it only exists while
	-- Conjure is loaded.
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("conjure_auto_log_split", { clear = true }),
		pattern = { "scheme", "lisp", "racket" },
		callback = function()
			if vim.g.conjure_log_split_opened then
				return
			end
			vim.g.conjure_log_split_opened = true
			local origin_win = vim.api.nvim_get_current_win()
			vim.defer_fn(function()
				pcall(vim.cmd, "ConjureLogVsplit")
				if vim.api.nvim_win_is_valid(origin_win) then
					vim.api.nvim_set_current_win(origin_win)
				end
			end, 50)
		end,
	})
end

require("utils.lazy").setup({
	src = "https://github.com/Olical/conjure",
	filetypes = { "scheme", "lisp", "racket", "clojure" },
	configure = M.configure,
})

return M
