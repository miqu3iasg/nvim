-- lua/plugins/lisp.lua

-- This configuration requires Tree-sitter, MIT Scheme, Racket and rlwrap.
-- Conjure and nvim-paredit are installed automatically through vim.pack.
--
-- On Arch Linux, install the available dependencies with pacman:
--
-- $ sudo pacman -S tree-sitter-cli racket rlwrap
--
-- MIT Scheme is available through the AUR:
--
-- $ yay -S mit-scheme
--
-- A known build issue may occur when installing MIT Scheme 12.1 from the AUR.
-- Arch Linux's glibc defines `_POSIX_C_SOURCE` with a newer value than the
-- MIT Scheme source expects. The source then attempts to redefine the macro,
-- and the build fails because warnings are treated as errors (`-Werror`).
-- Debian already provides an official patch for this issue.
--
-- To find possible fixes, search for:
--
-- "mit-scheme AUR chacha12.c _POSIX_C_SOURCE redefined error Arch Linux"
--
-- One workaround is to edit the `PKGBUILD` in `~/.cache/yay/mit-scheme`
-- and update its `prepare()` function to insert the appropriate values
-- using `sed`. Then remove the cached build directories and rebuild:
--
-- $ rm -rf ~/.cache/yay/mit-scheme/src ~/.cache/yay/mit-scheme/pkg
-- $ cd ~/.cache/yay/mit-scheme
-- $ makepkg -si
--
-- See: https://web.mit.edu/scheme/current/doc/mit-scheme-user/Introduction.html
-- See: https://www.shido.info/lisp/scheme1_e.html
-- See: https://www.mail-archive.com/debian-bugs-closed@lists.debian.org/msg850823.html
-- See: https://aur.archlinux.org/packages/mit-scheme

-- Treesitter is configured in lua/plugins/treesitter.lua, which must be loaded
-- before this file. Parsers are installed directly because treesitter.lua uses
-- ts.install() and does not consume the lazy-style opts.ensure_installed
-- configuration
require("nvim-treesitter").install({
	"scheme",
	"commonlisp",
	"racket",
})

-- Conjure reads these globals when it starts for a Lisp, Scheme or Racket
-- buffer, after init.lua has finished
vim.g["conjure#filetype#scheme"] = "conjure.client.scheme.stdio"
vim.g["conjure#client#scheme#stdio#command"] = "unbuffer -p mit-scheme"

-- Disable the floating HUD and use a docked split instead
vim.g["conjure#log#hud#enabled"] = false
vim.g["conjure#log#botright"] = true -- Dock on the far right, full height
vim.g["conjure#log#split#width"] = 0.5
vim.opt.splitright = true

-- Highlight the evaluated form briefly
vim.g["conjure#highlight#enabled"] = true

-- Automatically open the log split on the first Scheme, Lisp or Racket buffer.
-- This is best-effort; if it fails, <localleader>lv opens the log manually
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

-- Set the local leader before defining Conjure's key mappings
if vim.g.maplocalleader == nil or vim.g.maplocalleader == "" then
	vim.g.maplocalleader = ","
end

-- Evaluation
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

-- Evaluation with the result inserted as a comment
vim.g["conjure#eval#comment_prefix"] = "; => "
vim.g["conjure#mapping#eval_comment_current_form"] = "ece"
vim.g["conjure#mapping#eval_comment_root_form"] = "ecr"
vim.g["conjure#mapping#eval_comment_word"] = "ecw"

-- Log and REPL
vim.g["conjure#mapping#log_split"] = "ls"
vim.g["conjure#mapping#log_vsplit"] = "lv"
vim.g["conjure#mapping#log_tab"] = "lt"
vim.g["conjure#mapping#log_buf"] = "le"
vim.g["conjure#mapping#log_toggle"] = "lg"
vim.g["conjure#mapping#log_close_visible"] = "lq"
vim.g["conjure#mapping#log_reset_soft"] = "lr"
vim.g["conjure#mapping#log_reset_hard"] = "lR"
vim.g["conjure#mapping#log_jump_to_latest"] = "ll"

-- Navigation and documentation
vim.g["conjure#mapping#def_word"] = "gd"
vim.g["conjure#mapping#doc_word"] = { "K" }

-- nvim-paredit
require("nvim-paredit").setup()
