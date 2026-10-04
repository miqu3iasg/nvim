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
      cursorline     = true,
      title          = false,
      number         = true,
      relativenumber = false,
      border         = "none",
      header         = false,
      title_pos      = "center",
      cursorcolumn   = false,
      list           = false,
      foldenable     = false,
      foldmethod     = "manual",

      split          = function()
        local height = math.floor(vim.o.lines * 0.25)
        vim.cmd(("belowright %dnew"):format(height))

        vim.wo.number = true
        vim.wo.relativenumber = false
      end,

      preview        = {
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
