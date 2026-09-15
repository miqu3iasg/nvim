-- lua/plugins/fzf.lua

return {
  "ibhagwan/fzf-lua",
  ---@module "fzf-lua"
  ---@type fzf-lua.Config|{}
  ---@diagnostic disable: missing-fields
  opts = {
    file_icons = false,
    git_icons = false,
    winopts = {
      cursorline = false,
      title = "none",
      border = "none",
      title_pos = "center",

      split = function()
        local height = math.floor(vim.o.lines * 0.25)
        local laststatus = vim.o.laststatus
        vim.cmd(("belowright %dnew"):format(height))

        vim.wo.number = false
        vim.wo.relativenumber = false
        vim.wo.signcolumn = "no"
        vim.wo.statuscolumn = ""

        vim.api.nvim_create_autocmd("BufWinLeave", {
          buffer = 0,
          once = true,
          callback = function()
            vim.o.laststatus = laststatus
          end,
        })
      end,

      preview = {
        default = "bat", -- you need to have `bat` installed. For Arch Linux, use `sudo pacman -S bat`
        layout = "horizontal",
        horizontal = "right:50%",
        hidden = true,
        border = "none",
        scrollbar = false,
      },
    },
    fzf_opts = {
      ["--layout"] = "reverse",
      ["--info"] = "hidden",
      ["--no-separator"] = "",
      ["--no-scrollbar"] = "",
      ["--marker"] = "┃",
    },
    fzf_colors = true,
    keymap = {
      fzf = {
        ["ctrl-/"] = "toggle-preview",
        ["ctrl-q"] = "select-all+accept",
      },
    },
  },

  ---@diagnostic enable: missing-fields
  keys = {
    -- Core entry point and buffer/line search
    { "<leader>w",  "<cmd>FzfLua<cr>",                            desc = "Fzf" },
    { "<leader>I",  "<cmd>FzfLua files cwd=%:p:h<cr>",            desc = "Fzf: Files (buffer dir)" },
    { "<leader>u",  "<cmd>FzfLua blines<cr>",                     desc = "Fzf: Lines (current buffer)" },
    { "<leader>U",  "<cmd>FzfLua lines<cr>",                      desc = "Fzf: Lines (all buffers)" },
    { "<leader>M",  "<cmd>FzfLua marks<cr>",                      desc = "Fzf: Marks" },

    -- Git pickers
    { "<leader>gs", "<cmd>FzfLua git_status<cr>",                 desc = "Fzf: Git status" },
    { "<leader>gc", "<cmd>FzfLua git_commits<cr>",                desc = "Fzf: Git commits" },
    { "<leader>gb", "<cmd>FzfLua git_branches<cr>",               desc = "Fzf: Git branches" },
    { "<leader>gf", "<cmd>FzfLua git_files<cr>",                  desc = "Fzf: Git files (tracked)" },
    { "<leader>gS", "<cmd>FzfLua git_stash<cr>",                  desc = "Fzf: Git stash" },
    { "<leader>gv", "<cmd>FzfLua grep_visual<cr>",                mode = "v",                          desc = "Fzf: Grep visual selection" },

    -- Vim introspection (keymaps, registers)
    { "<leader>K",  "<cmd>FzfLua keymaps<cr>",                    desc = "Fzf: Keymaps" },
    { "<leader>R",  "<cmd>FzfLua registers<cr>",                  desc = "Fzf: Registers" },

    -- File finders
    { "<leader>fb", "<cmd>FzfLua files<cr>",                      desc = "Fzf: File browser" },
    { "<leader>fz", "<cmd>FzfLua zoxide<cr>",                     desc = "Fzf: Zoxide list" },
    { "<leader>fr", "<cmd>FzfLua oldfiles<cr>",                   desc = "Fzf: Recent files" },
    { "<leader>fu", "<cmd>FzfLua buffers<cr>",                    desc = "Fzf: Buffers" },
    { "<leader>jk", "<cmd>FzfLua files<cr>",                      desc = "Fzf: Find files (hidden)" },
    { "<leader>ff", "<cmd>FzfLua files<cr>",                      desc = "Fzf: Find files (hidden)" },

    -- Grep / text search
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>",                  desc = "Fzf: Grep (cwd)" },
    { "<leader>fw", "<cmd>FzfLua grep_cword<cr>",                 desc = "Fzf: Grep word under cursor" },

    -- LSP / diagnostics
    { "<leader>fd", "<cmd>FzfLua diagnostics_workspace<cr>",      desc = "Fzf: Diagnostics" },
    { "<leader>ds", "<cmd>FzfLua lsp_document_symbols<cr>",       desc = "Fzf: LSP document symbols" },
    { "<leader>ws", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", desc = "Fzf: LSP workspace symbols" },

    -- Help / commands / lists
    { "<leader>fv", "<cmd>FzfLua helptags<cr>",                   desc = "Fzf: Help tags" },
    { "<leader>fp", "<cmd>FzfLua<cr>",                            desc = "Fzf: Builtin pickers" },
    { "<leader>fa", "<cmd>FzfLua commands<cr>",                   desc = "Fzf: Commands" },
    { "<leader>fl", "<cmd>FzfLua jumps<cr>",                      desc = "Fzf: Jumplist" },

    -- History / session resume
    { "<leader>fh", "<cmd>FzfLua command_history<cr>",            desc = "Fzf: Command history" },
    { "<leader>fk", "<cmd>FzfLua search_history<cr>",             desc = "Fzf: Search history" },
    { "<leader>fc", "<cmd>FzfLua resume<cr>",                     desc = "Fzf: Resume last picker" },

    -- Editor/OS info pickers
    { "<leader>fn", "<cmd>FzfLua filetypes<cr>",                  desc = "Fzf: Filetypes" },
    { "<leader>fH", "<cmd>FzfLua highlights<cr>",                 desc = "Fzf: Highlight groups" },
    { "<leader>fm", "<cmd>FzfLua man_pages<cr>",                  desc = "Fzf: Man pages" },
    { "<leader>fx", "<cmd>FzfLua autocmds<cr>",                   desc = "Fzf: Autocmds" },
  },
}
