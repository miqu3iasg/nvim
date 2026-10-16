-- lua/plugins/fzf.lua

-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/after/autoload/enable/fzf.vim
-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/plugin/fzf.vim

local function search_pending_comments()
  require("fzf-lua").grep({
    search = [[\b(TODO|FIXME|HACK|BUG|XXX)\b]],
    no_esc = true,
    prompt = "TODO/FIXME> ",
    rg_opts = "--column --line-number --no-heading --color=always --smart-case "
        .. "--max-columns=4096 --max-filesize=1M "
        .. "--glob '!**/{.git,node_modules,build,dist,target,vendor,.venv,__pycache__}/**' "
        .. "--glob '!*.{min.js,min.css,map,lock}' "
        .. "-e",
  })
end

return {
  "ibhagwan/fzf-lua",
  opts = function()
    local actions = require("fzf-lua").actions

    return {
      file_icons = false,
      git_icons  = false,

      winopts    = {
        on_create   = function(e)
          if e.winid and vim.api.nvim_win_is_valid(e.winid) then
            vim.api.nvim_win_set_config(e.winid, { title = "" })
          end
        end,

        -- split       = "botright 10new",
        -- border      = "none",
        height      = 0.80,
        width       = 0.70,
        row         = 0.35,
        col         = 0.50,
        border      = "single",
        title       = false,
        title_flags = false,
        title_pos   = "right",
        backdrop    = 100,
        scrollbar   = false,
        preview     = {
          hidden    = true,
          wrap      = true,
          border    = "single",
          scrollbar = false,
          winopts   = {
            number         = false,
            relativenumber = false,
            cursorline     = false,
            foldenable     = false,
          },
        },
      },

      fzf_opts   = {
        ["--ansi"]           = true,
        -- ["--layout"]         = "reverse",
        ["--layout"]         = "default",
        ["--info"]           = false,
        ["--highlight-line"] = false,
        ["--border"]         = "none",
      },

      previewers = {
        builtin = {
          treesitter = { enabled = true },
        },
      },

      actions    = {
        files = {
          ["enter"]  = actions.file_edit_or_qf,
          ["ctrl-t"] = actions.file_tabedit,
          ["ctrl-x"] = actions.file_split,
        },
      },

      keymap     = {
        builtin = {
          ["<C-j>"] = "preview-page-down",
          ["<C-k>"] = "preview-page-up",
        },
        fzf = {
          ["ctrl-g"] = "execute(less -c -i --incsearch --search-options=W -g {})",
          ["ctrl-z"] = "abort",
          ["ctrl-u"] = "unix-line-discard",
          ["ctrl-a"] = "beginning-of-line",
          ["ctrl-e"] = "end-of-line",
          ["ctrl-q"] = "select-all+accept",
        },
      },

      grep       = {
        fzf_opts = {
          ["--delimiter"] = ":",
          ["--with-nth"]  = "1,4..",
        },
      },
    }
  end,

  config = function(_, opts)
    require("fzf-lua").setup(opts)

    local function set_fzf_hl()
      vim.api.nvim_set_hl(0, "FzfLuaBorder", { fg = "#2a2a2a" })
      vim.api.nvim_set_hl(0, "FzfLuaPreviewBorder", { fg = "#2a2a2a" })
    end

    set_fzf_hl()

    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = set_fzf_hl,
    })

    vim.api.nvim_create_user_command("Todo", search_pending_comments, {
      desc = "Fzf: search TODO/FIXME/HACK/BUG/XXX in the current directory",
    })
  end,

  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>",                 desc = "Fzf: find files in cwd (respects .gitignore)" },
    { "<leader>fu", "<cmd>FzfLua files cwd=%:p:h<cr>",       desc = "Fzf: find files in the current buffer's directory" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>",               desc = "Fzf: switch between open buffers" },
    { "<leader>ft", "<cmd>FzfLua tabs<cr>",                  desc = "Fzf: switch between open tabs" },
    { "<leader>fo", "<cmd>FzfLua oldfiles<cr>",              desc = "Fzf: reopen recently edited files" },
    { "<leader>fp", "<cmd>FzfLua zoxide<cr>",                desc = "Fzf: jump to a frequent directory (zoxide)" },
    { "<leader>fm", "<cmd>FzfLua marks<cr>",                 desc = "Fzf: jump to a mark" },

    { "<leader>fg", "<cmd>FzfLua live_grep<cr>",             desc = "Fzf: live grep across all files in cwd" },
    { "<leader>fw", "<cmd>FzfLua grep_cword<cr>",            desc = "Fzf: grep the word under the cursor in cwd" },
    { "<leader>fl", "<cmd>FzfLua blines<cr>",                desc = "Fzf: search lines in the current buffer" },

    { "<leader>fd", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Fzf: list LSP diagnostics for the whole workspace" },
    { "<leader>fa", "<cmd>FzfLua commands<cr>",              desc = "Fzf: run an Ex command" },
    { "<leader>fk", "<cmd>FzfLua keymaps<cr>",               desc = "Fzf: search all keymaps" },
    { "<leader>fn", "<cmd>FzfLua man_pages<cr>",             desc = "Fzf: open a man page" },

    { "<leader>fc", "<cmd>FzfLua resume<cr>",                desc = "Fzf: resume the last picker with its previous query" },
    { "<leader>fz", "<cmd>FzfLua<cr>",                       desc = "Fzf: open the full picker menu" },

    { "<leader>fe", search_pending_comments,                 desc = "Fzf: list TODO/FIXME/HACK/BUG/XXX in current directory" },
  },
}
