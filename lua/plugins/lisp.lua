-- lua/plugins/lisp.lua

-- For this configuration to work, you need Tree-sitter, the Scheme
-- interpreter MIT Scheme, Racket, and rlwrap installed on your machine.
-- Conjure and nvim-paredit are installed automatically by Lazy.nvim.
-- You can install it in Arch Linux via:
--
-- `sudo pacman -S tree-sitter-cli mit-scheme racket rlwrap`
--
-- or using yay for MIT Scheme:
--
-- `yay -S mit-scheme`
--
-- When installing MIT Scheme via AUR packages, a known bug in MIT Scheme 12.1 may arise.
-- Arch's glibc is already too recent and defines `_POSIX_C_SOURCE` with a newer value;
-- the MIT Scheme source code attempts to redefine this same macro with an older value,
-- and since the build treats warnings as errors (`-Werror`), the build fails. Debian
-- already has an official patch for this. Search for "mit-scheme AUR chacha12.c_POSIX_C_SOURCE
-- redefined error Arch Linux" to find some fixes. In short, you need to edit the `PKGBUILD`
-- in ~/.cache/yay/mit-scheme and update the `prepare()` function to insert the correct
-- values using `sed`. Then, remove the cache folder using `rm -rf src pkg` and run
-- `makepkg -si` to rebuild.
--
-- refs:
--     - https://web.mit.edu/scheme/current/doc/mit-scheme-user/Introduction.html
--     - https://www.shido.info/lisp/scheme1_e.html
--     - https://www.mail-archive.com/debian-bugs-closed@lists.debian.org/msg850823.html
--     - https://aur.archlinux.org/packages/mit-scheme

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "scheme", "commonlisp", "racket" })
    end,
  },

  {
    "Olical/conjure",
    ft = { "scheme", "lisp", "racket" },
    lazy = true,
    init = function()
      -- client
      vim.g["conjure#filetype#scheme"] = "conjure.client.scheme.stdio"
      vim.g["conjure#client#scheme#stdio#command"] = "unbuffer -p mit-scheme"

      -- disable floating HUD, use a docked log split instead
      vim.g["conjure#log#hud#enabled"] = false
      vim.g["conjure#log#botright"] = true -- log always docks on the far right, full height
      vim.g["conjure#log#split#width"] = 0.5
      vim.opt.splitright = true

      -- highlights the evaluated shape for an instant
      vim.g["conjure#highlight#enabled"] = true

      -- auto-open the log split on first scheme/lisp/racket buffer
      -- best-effort; if it doesn't trigger, <localleader>lv opens it manually
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

      if vim.g.maplocalleader == nil or vim.g.maplocalleader == "" then
        vim.g.maplocalleader = ","
      end

      -- eval
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

      -- eval + insert result as comment
      vim.g["conjure#mapping#eval_comment_current_form"] = "ece"
      vim.g["conjure#mapping#eval_comment_root_form"] = "ecr"
      vim.g["conjure#mapping#eval_comment_word"] = "ecw"

      -- log / repl
      vim.g["conjure#mapping#log_split"] = "ls"
      vim.g["conjure#mapping#log_vsplit"] = "lv"
      vim.g["conjure#mapping#log_tab"] = "lt"
      vim.g["conjure#mapping#log_buf"] = "le"
      vim.g["conjure#mapping#log_toggle"] = "lg"
      vim.g["conjure#mapping#log_close_visible"] = "lq"
      vim.g["conjure#mapping#log_reset_soft"] = "lr"
      vim.g["conjure#mapping#log_reset_hard"] = "lR"
      vim.g["conjure#mapping#log_jump_to_latest"] = "ll"

      -- navigation / docs
      vim.g["conjure#mapping#def_word"] = "gd"
      vim.g["conjure#mapping#doc_word"] = { "K" }
    end,
  },

  {
    "julienvincent/nvim-paredit",
    ft = { "scheme", "lisp", "racket" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-paredit").setup()
    end,
  },
}
