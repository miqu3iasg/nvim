return {
  "ibhagwan/fzf-lua",
  ---@module "fzf-lua"
  ---@type fzf-lua.Config|{}
  ---@diagnostic disable: missing-fields
  opts = {
    fzf_colors = true,
    file_icons = false,
    winopts = {
      split = function()
        local height = math.floor(vim.o.lines * 0.25)
        vim.cmd(("belowright %dnew"):format(height))
      end,
      preview = {
        layout = "horizontal",
        horizontal = "right:50%",
        hidden = true,
      },
    },
    keymap = {
      fzf = {
        ["ctrl-/"] = "toggle-preview",
      },
    },
  },
  ---@diagnostic enable: missing-fields
  keys = {
    { "<leader>w", "<cmd>FzfLua<cr>",                 desc = "Fzf" },
    { "<leader>i", "<cmd>FzfLua files<cr>",           desc = "Fzf: Files (cwd)" },
    { "<leader>I", "<cmd>FzfLua files cwd=%:p:h<cr>", desc = "Fzf: Files (buffer dir)" },
    { "<leader>u", "<cmd>FzfLua blines<cr>",          desc = "Fzf: Lines (buffer atual)" },
    { "<leader>N", "<cmd>FzfLua buffers<cr>",         desc = "Fzf: Buffers" },
    { "<leader>O", "<cmd>FzfLua live_grep<cr>",       desc = "Fzf: Grep (cwd)" },
    { "<leader>U", "<cmd>FzfLua lines<cr>",           desc = "Fzf: Lines (todos buffers)" },
  },
}
