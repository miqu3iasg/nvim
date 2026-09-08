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
      split = function()
        local height = math.floor(vim.o.lines * 0.25)
        local laststatus = vim.o.laststatus
        vim.cmd(("belowright %dnew"):format(height))
        vim.wo.number = false
        vim.wo.relativenumber = false
        vim.wo.signcolumn = "no"
        vim.wo.statuscolumn = ""
        vim.o.laststatus = 0
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
      },
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
    { "<leader>w",  "<cmd>FzfLua<cr>",                 desc = "Fzf" },
    { "<leader>i",  "<cmd>FzfLua files<cr>",           desc = "Fzf: Files (cwd)" },
    { "<leader>I",  "<cmd>FzfLua files cwd=%:p:h<cr>", desc = "Fzf: Files (buffer dir)" },
    { "<leader>l",  "<cmd>FzfLua oldfiles<cr>",        desc = "Fzf: Recent files" },
    { "<leader>O",  "<cmd>FzfLua live_grep<cr>",       desc = "Fzf: Grep (cwd)" },
    { "<leader>o",  "<cmd>FzfLua grep_cword<cr>",      desc = "Fzf: Grep word under cursor" },
    { "<leader>u",  "<cmd>FzfLua blines<cr>",          desc = "Fzf: Lines (current buffer)" },
    { "<leader>U",  "<cmd>FzfLua lines<cr>",           desc = "Fzf: Lines (all buffers)" },
    { "<leader>m",  "<cmd>FzfLua marks<cr>",           desc = "Fzf: Marks" },
    { "<leader>gs", "<cmd>FzfLua git_status<cr>",      desc = "Fzf: Git status" },
    { "<leader>gc", "<cmd>FzfLua git_commits<cr>",     desc = "Fzf: Git commits" },
    { "<leader>gb", "<cmd>FzfLua git_branches<cr>",    desc = "Fzf: Git branches" },
    { "<leader>K",  "<cmd>FzfLua keymaps<cr>",         desc = "Fzf: Keymaps" },
    { "<leader>R",  "<cmd>FzfLua registers<cr>",       desc = "Fzf: Registers" },
  },
}
