-- lua/plugins/fzf.lua

-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/after/autoload/enable/fzf.vim
-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/plugin/fzf.vim

return {
  "ibhagwan/fzf-lua",
  opts = function()
    local actions = require("fzf-lua").actions

    -- Open the selected file(s) using a custom vim command
    local function open_with(vimcmd)
      return function(selected, o)
        return actions.vimcmd_file(vimcmd, selected, o)
      end
    end

    return {
      file_icons = false,
      git_icons  = false,

      winopts    = {
        split   = "botright 10new",
        border  = "none",
        title   = false,
        preview = {
          default    = "builtin",
          layout     = "horizontal",
          horizontal = "left:99%",
          hidden     = true,
          wrap       = true,
          border     = "none",
          scrollbar  = false,
          winopts    = {
            number         = false,
            relativenumber = false,
            cursorline     = false,
            foldenable     = false,
          },
        },
      },

      fzf_opts   = {
        ["--ansi"]           = true,
        ["--layout"]         = "reverse",
        ["--info"]           = false,
        ["--highlight-line"] = false,
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
          ["alt-v"]  = open_with("leftabove vsplit"),
          ["ctrl-v"] = open_with("belowright vsplit"),
          ["alt-q"]  = actions.file_sel_to_qf,
          ["alt-Q"]  = actions.file_sel_to_ll,
        },
      },

      keymap     = {
        builtin = {
          ["<C-j>"] = "preview-page-down",
          ["<C-k>"] = "preview-page-up",
        },
        fzf = {
          ["ctrl-/"] = "toggle-preview",
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

  keys = {
    { "<leader>fm", "<cmd>FzfLua marks<cr>",                 desc = "Fzf: Marks" },
    { "<leader>fk", "<cmd>FzfLua keymaps<cr>",               desc = "Fzf: Keymaps" },
    { "<leader>fp", "<cmd>FzfLua zoxide<cr>",                desc = "Fzf: Zoxide list" },
    { "<leader>fo", "<cmd>FzfLua oldfiles<cr>",              desc = "Fzf: Recent files" },
    { "<leader>fl", "<cmd>FzfLua blines<cr>",                desc = "Fzf: Lines (current buffer)" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>",               desc = "Fzf: Buffers" },
    { "<leader>ff", "<cmd>FzfLua files<cr>",                 desc = "Fzf: Find files (hidden)" },
    { "<leader>fu", "<cmd>FzfLua files cwd=%:p:h<cr>",       desc = "Fzf: Files (buffer dir)" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>",             desc = "Fzf: Grep (cwd)" },
    { "<leader>fw", "<cmd>FzfLua grep_cword<cr>",            desc = "Fzf: Grep word under cursor" },
    { "<leader>fd", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Fzf: Diagnostics" },
    { "<leader>fa", "<cmd>FzfLua commands<cr>",              desc = "Fzf: Commands" },
    { "<leader>fc", "<cmd>FzfLua resume<cr>",                desc = "Fzf: Resume last picker" },
    { "<leader>fn", "<cmd>FzfLua man_pages<cr>",             desc = "Fzf: Man pages" },
    { "<leader>fz", "<cmd>FzfLua<cr>",                       desc = "Fzf" },
  },
}
