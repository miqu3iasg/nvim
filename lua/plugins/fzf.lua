-- lua/plugins/fzf.lua

return {
  "ibhagwan/fzf-lua",
  ---@module "fzf-lua"
  ---@type fzf-lua.Config|{}
  ---@diagnostic disable: missing-fields
  opts = {
    file_icons = false,
    git_icons  = false,
    winopts    = {
      cursorline   = true,
      title        = false,
      border       = "none",
      header       = false,
      title_pos    = "center",
      cursorcolumn = false,
      list         = false,
      foldenable   = false,
      foldmethod   = "manual",

      split        = function()
        local height = math.floor(vim.o.lines * 0.25)
        vim.cmd(("belowright %dnew"):format(height))

        vim.wo.number = true
        vim.wo.relativenumber = false
        vim.wo.signcolumn = "no"
        vim.wo.statuscolumn = ""
      end,

      preview      = {
        default = "bat",
        layout = "horizontal",
        horizontal = "right:50%",
        hidden = true,
        border = "none",
        scrollbar = false,
      },
    },
    fzf_opts   = {
      ["--ansi"]           = true,
      ["--info"]           = "inline-right", -- fzf < v0.42 = "inline"
      ["--layout"]         = "reverse",
      ["--highlight-line"] = true,
      ["--no-separator"]   = "",
      ["--no-scrollbar"]   = "",
    },
    -- fzf_colors = {
    --   ["fg"]        = { "fg", "Normal" },
    --   ["bg"]        = { "bg", "Normal" },
    --   ["fg+"]       = { "fg", "Visual" },
    --   ["bg+"]       = { "bg", "CursorLine" },
    --   ["hl"]        = { "fg", "MatchParen" },
    --   ["hl+"]       = { "fg", "MatchParen" },
    --   ["gutter"]    = { "bg", "Normal" },
    --   ["border"]    = { "fg", "FloatBorder" },
    --   ["separator"] = { "fg", "FloatBorder" },
    --   ["scrollbar"] = { "fg", "NonText" },
    --   ["header"]    = { "fg", "NonText" },
    --   ["info"]      = { "fg", "NonText" },
    --   ["pointer"]   = { "fg", "CursorLine" },
    --   ["marker"]    = { "fg", "DiagnosticWarn" },
    --   ["spinner"]   = { "fg", "DiagnosticHint" },
    --   ["prompt"]    = { "fg", "DiagnosticHint" },
    --   ["query"]     = { "fg", "Visual" },
    --   ["header-bg"] = { "bg", "Normal" },
    --   ["input-bg"]  = { "bg", "Normal" },
    --   ["list-bg"]   = { "bg", "Normal" },
    --   ["footer-bg"] = { "bg", "Normal" },
    -- },
    previewers = {
      builtin = {
        treesitter = {
          enabled    = true,
          fzf_colors = { ["hl"] = "-1:reverse", ["hl+"] = "-1:reverse" },
        },
      },
    },
    keymap     = {
      fzf = {
        -- fzf '--bind=' options
        -- true,        -- uncomment to inherit all the below in your custom config
        ["ctrl-z"] = "abort",
        ["ctrl-u"] = "unix-line-discard",
        ["ctrl-a"] = "beginning-of-line",
        ["ctrl-e"] = "end-of-line",
        -- Only valid with fzf previewers (bat/cat/git/etc)
        ["ctrl-/"] = "toggle-preview",
        ["ctrl-q"] = "select-all+accept",
      },
    },
  },

  ---@diagnostic enable: missing-fields
  keys = {
    { "<leader>w",  "<cmd>FzfLua<cr>",                            desc = "Fzf" },
    { "<leader>I",  "<cmd>FzfLua files cwd=%:p:h<cr>",            desc = "Fzf: Files (buffer dir)" },
    { "<leader>u",  "<cmd>FzfLua blines<cr>",                     desc = "Fzf: Lines (current buffer)" },
    { "<leader>U",  "<cmd>FzfLua lines<cr>",                      desc = "Fzf: Lines (all buffers)" },
    { "<leader>M",  "<cmd>FzfLua marks<cr>",                      desc = "Fzf: Marks" },
    { "<leader>gs", "<cmd>FzfLua git_status<cr>",                 desc = "Fzf: Git status" },
    { "<leader>gc", "<cmd>FzfLua git_commits<cr>",                desc = "Fzf: Git commits" },
    { "<leader>gb", "<cmd>FzfLua git_branches<cr>",               desc = "Fzf: Git branches" },
    { "<leader>gf", "<cmd>FzfLua git_files<cr>",                  desc = "Fzf: Git files (tracked)" },
    { "<leader>gS", "<cmd>FzfLua git_stash<cr>",                  desc = "Fzf: Git stash" },
    { "<leader>gv", "<cmd>FzfLua grep_visual<cr>",                mode = "v",                          desc = "Fzf: Grep visual selection" },
    { "<leader>K",  "<cmd>FzfLua keymaps<cr>",                    desc = "Fzf: Keymaps" },
    { "<leader>R",  "<cmd>FzfLua registers<cr>",                  desc = "Fzf: Registers" },
    { "<leader>fb", "<cmd>FzfLua files<cr>",                      desc = "Fzf: File browser" },
    { "<leader>fz", "<cmd>FzfLua zoxide<cr>",                     desc = "Fzf: Zoxide list" },
    { "<leader>fr", "<cmd>FzfLua oldfiles<cr>",                   desc = "Fzf: Recent files" },
    { "<leader>fu", "<cmd>FzfLua buffers<cr>",                    desc = "Fzf: Buffers" },
    { "<leader>jk", "<cmd>FzfLua files<cr>",                      desc = "Fzf: Find files (hidden)" },
    { "<leader>ff", "<cmd>FzfLua files<cr>",                      desc = "Fzf: Find files (hidden)" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>",                  desc = "Fzf: Grep (cwd)" },
    { "<leader>fw", "<cmd>FzfLua grep_cword<cr>",                 desc = "Fzf: Grep word under cursor" },
    { "<leader>fd", "<cmd>FzfLua diagnostics_workspace<cr>",      desc = "Fzf: Diagnostics" },
    { "<leader>ds", "<cmd>FzfLua lsp_document_symbols<cr>",       desc = "Fzf: LSP document symbols" },
    { "<leader>ws", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", desc = "Fzf: LSP workspace symbols" },
    { "<leader>fv", "<cmd>FzfLua helptags<cr>",                   desc = "Fzf: Help tags" },
    { "<leader>fp", "<cmd>FzfLua<cr>",                            desc = "Fzf: Builtin pickers" },
    { "<leader>fa", "<cmd>FzfLua commands<cr>",                   desc = "Fzf: Commands" },
    { "<leader>fl", "<cmd>FzfLua jumps<cr>",                      desc = "Fzf: Jumplist" },
    { "<leader>fh", "<cmd>FzfLua command_history<cr>",            desc = "Fzf: Command history" },
    { "<leader>fk", "<cmd>FzfLua search_history<cr>",             desc = "Fzf: Search history" },
    { "<leader>fc", "<cmd>FzfLua resume<cr>",                     desc = "Fzf: Resume last picker" },
    { "<leader>fn", "<cmd>FzfLua filetypes<cr>",                  desc = "Fzf: Filetypes" },
    { "<leader>fH", "<cmd>FzfLua highlights<cr>",                 desc = "Fzf: Highlight groups" },
    { "<leader>fm", "<cmd>FzfLua man_pages<cr>",                  desc = "Fzf: Man pages" },
    { "<leader>fx", "<cmd>FzfLua autocmds<cr>",                   desc = "Fzf: Autocmds" },
  },
}
