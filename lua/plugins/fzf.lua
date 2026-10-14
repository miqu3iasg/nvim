-- lua/plugins/fzf.lua

-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/after/autoload/enable/fzf.vim
-- See: https://github.com/bruhtus/dotfiles/blob/master/.vim/plugin/fzf.vim

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
  end,

  keys = {
    { "<leader>fm", "<cmd>FzfLua marks<cr>",                 desc = "Fzf: Marks" },
    { "<leader>fk", "<cmd>FzfLua keymaps<cr>",               desc = "Fzf: Keymaps" },
    { "<leader>fp", "<cmd>FzfLua zoxide<cr>",                desc = "Fzf: Zoxide list" },
    { "<leader>fo", "<cmd>FzfLua oldfiles<cr>",              desc = "Fzf: Recent files" },
    { "<leader>fl", "<cmd>FzfLua blines<cr>",                desc = "Fzf: Lines (current buffer)" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>",               desc = "Fzf: Buffers" },
    { "<leader>ff", "<cmd>FzfLua files<cr>",                 desc = "Fzf: Find files (hidden)" },
    { "<leader>ft", "<cmd>FzfLua tabs<cr>",                  desc = "Fzf: Find tabs" },
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
