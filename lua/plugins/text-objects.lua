-- lua/plugins/text-objects.lua

return {
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",

    init = function()
      -- Disable native ftplugin mappings to avoid conflicts
      vim.g.no_plugin_maps = true
    end,

    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,             -- Jump to the next object if the cursor is not on one
          selection_modes = {
            ["@parameter.outer"] = "v", -- Charwise
            ["@function.outer"] = "V",  -- Linewise
            ["@class.outer"] = "V",     -- Linewise
          },
          include_surrounding_whitespace = false,
        },

        move = {
          set_jumps = true,
        },

        swap = {},
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")
      local map = vim.keymap.set

      local function sel(query)
        return function()
          select.select_textobject(query, "textobjects")
        end
      end

      -- Functions
      map({ "x", "o" }, "af", sel("@function.outer"), {
        desc = "around function",
      })

      map({ "x", "o" }, "if", sel("@function.inner"), {
        desc = "inside function",
      })

      -- Classes
      map({ "x", "o" }, "ac", sel("@class.outer"), {
        desc = "around class",
      })

      map({ "x", "o" }, "ic", sel("@class.inner"), {
        desc = "inside class",
      })

      -- Arguments / parameters
      map({ "x", "o" }, "aa", sel("@parameter.outer"), {
        desc = "around argument",
      })

      map({ "x", "o" }, "ia", sel("@parameter.inner"), {
        desc = "inside argument",
      })

      -- Conditionals
      map({ "x", "o" }, "ai", sel("@conditional.outer"), {
        desc = "around conditional",
      })

      map({ "x", "o" }, "ii", sel("@conditional.inner"), {
        desc = "inside conditional",
      })

      -- Loops
      map({ "x", "o" }, "al", sel("@loop.outer"), {
        desc = "around loop",
      })

      map({ "x", "o" }, "il", sel("@loop.inner"), {
        desc = "inside loop",
      })

      -- Generic blocks ({ ... })
      map({ "x", "o" }, "ab", sel("@block.outer"), {
        desc = "around block",
      })

      map({ "x", "o" }, "ib", sel("@block.inner"), {
        desc = "inside block",
      })

      -- Comments
      map({ "x", "o" }, "aC", sel("@comment.outer"), {
        desc = "around comment",
      })

      -- Move
      local move_pairs = {
        ["]f"] = { "@function.outer", "next", "start" },
        ["]F"] = { "@function.outer", "next", "end" },
        ["[f"] = { "@function.outer", "previous", "start" },
        ["[F"] = { "@function.outer", "previous", "end" },

        ["]a"] = { "@parameter.inner", "next", "start" },
        ["[a"] = { "@parameter.inner", "previous", "start" },

        ["]c"] = { "@class.outer", "next", "start" },
        ["[c"] = { "@class.outer", "previous", "start" },
      }

      for key, value in pairs(move_pairs) do
        local query = value[1]
        local dir = value[2]
        local pos = value[3]

        local fname

        if dir == "next" and pos == "start" then
          fname = "goto_next_start"
        elseif dir == "next" and pos == "end" then
          fname = "goto_next_end"
        elseif dir == "previous" and pos == "start" then
          fname = "goto_previous_start"
        else
          fname = "goto_previous_end"
        end

        map({ "n", "x", "o" }, key, function()
          move[fname](query, "textobjects")
        end, {
          desc = key,
        })
      end

      -- Swap
      map("n", "<leader>a", function()
        swap.swap_next("@parameter.inner")
      end, {
        desc = "Swap next argument",
      })

      map("n", "<leader>A", function()
        swap.swap_previous("@parameter.inner")
      end, {
        desc = "Swap previous argument",
      })

      -- Markdown text objects
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
          local query_dir = vim.fn.stdpath("config") .. "/after/queries/markdown"

          vim.fn.mkdir(query_dir, "p")

          local query_file = query_dir .. "/textobjects.scm"

          if vim.fn.filereadable(query_file) == 0 then
            vim.fn.writefile({
              "; extends",
              "(fenced_code_block) @codeblock.outer",
              "(fenced_code_block (code_fence_content) @codeblock.inner)",
            }, query_file)
          end

          -- Use aE / iE
          vim.keymap.set({ "x", "o" }, "aE", sel("@codeblock.outer"), {
            desc = "around code block (markdown)",
            buffer = true,
          })

          vim.keymap.set({ "x", "o" }, "iE", sel("@codeblock.inner"), {
            desc = "inside code block (markdown)",
            buffer = true,
          })
        end,
      })
    end,
  },

  -- nvim-various-textobjs
  {
    "chrisgrieser/nvim-various-textobjs",
    event = "VeryLazy",

    opts = {
      keymaps = {
        useDefaults = true,

        -- Disable indentation objects because they conflict with
        -- the conditionals from Treesitter.
        disabledDefaults = {
          "ai",
          "ii",
          "aI",
        },
      },
    },

    config = function(_, opts)
      require("various-textobjs").setup(opts)

      local map = vim.keymap.set

      -- Whole file
      -- yae = yank
      -- vae = select
      -- dae = delete
      map(
        { "o", "x" },
        "ae",
        '<cmd>lua require("various-textobjs").entireBuffer()<CR>',
        { desc = "around entire file" }
      )

      map(
        { "o", "x" },
        "ie",
        '<cmd>lua require("various-textobjs").entireBuffer()<CR>',
        { desc = "inside entire file" }
      )

      -- Defaults
      -- io / ao -> "any object": inner/outer of (), [] or {} (nearest)
      -- iq / aq -> "any quote": inner/outer of " ' `
      -- iD / aD -> text inside [[ ]]
      -- i, / a, -> argument by comma
    end,
  },

  -- mini.ai: just function calls (au/iu)
  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          u = ai.gen_spec.function_call(),
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
        },
      }
    end,
    config = function(_, opts)
      require("mini.ai").setup(opts)

      -- `LazyVim` is a global provided by the LazyVim distro. Guard against
      -- it being unavailable (plain lazy.nvim setups, or load-order issues)
      -- so this plugin's config never throws.
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
