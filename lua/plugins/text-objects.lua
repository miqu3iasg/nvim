-- lua/plugins/text-objects.lua-

return {
  -- Treesitter queries source (@function.outer, @parameter.inner, etc.)
  -- Used only as a .scm provider for mini.ai.
  -- No .setup() or configuration needed: select/move/swap are unused.
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    lazy = true,
  },

  {
    "nvim-mini/mini.ai",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      local ts = ai.gen_spec.treesitter

      return {
        n_lines = 500,

        custom_textobjects = {
          f = ts({ a = "@function.outer", i = "@function.inner" }),
          c = ts({ a = "@class.outer", i = "@class.inner" }),
          a = ts({ a = "@parameter.outer", i = "@parameter.inner" }),
          i = ts({ a = "@conditional.outer", i = "@conditional.inner" }),
          l = ts({ a = "@loop.outer", i = "@loop.inner" }),
          B = ts({ a = "@block.outer", i = "@block.inner" }),
          C = ts({ a = "@comment.outer", i = "@comment.outer" }),
          u = ai.gen_spec.function_call(),
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),

          -- Entire file
          e = function()
            local from = { line = 1, col = 1 }
            local to = {
              line = vim.fn.line("$"),
              col = math.max(vim.fn.getline("$"):len(), 1),
            }
            return { from = from, to = to }
          end,
        },
      }
    end,

    config = function(_, opts)
      require("mini.ai").setup(opts)

      local ok, LazyVim = pcall(require, "lazyvim.util")
      if ok and LazyVim.on_load and LazyVim.mini and LazyVim.mini.ai_whichkey then
        LazyVim.on_load("which-key.nvim", function()
          vim.schedule(function()
            LazyVim.mini.ai_whichkey(opts)
          end)
        end)
      end
    end,

  },
}
