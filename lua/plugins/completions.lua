return {
  {
    "kdheepak/cmp-latex-symbols",
  },

  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        config = function()
          local luasnip = require("luasnip")
          local km = vim.keymap.set

          local function load_snippets(filetype, module)
            local ok, snippets = pcall(require, module)

            if not ok then
              vim.notify(
                string.format(
                  "Failed to load snippets '%s' for filetype '%s': %s",
                  module,
                  filetype,
                  snippets
                ),
                vim.log.levels.ERROR
              )
              return
            end

            luasnip.add_snippets(filetype, snippets)
          end

          load_snippets("markdown", "snippets.all")
          load_snippets("text", "snippets.all")
          load_snippets("tex", "snippets.latex")
          load_snippets("zig", "snippets.zig")
          load_snippets("c", "snippets.c")
          load_snippets("cpp", "snippets.cpp")
          load_snippets("cpp", "snippets.c")
          load_snippets("python", "snippets.python")
          load_snippets("java", "snippets.java")

          -- Global snippets
          load_snippets("all", "snippets.all")

          luasnip.filetype_extend("python", { "all" })
          luasnip.filetype_extend("c", { "all" })
          luasnip.filetype_extend("cpp", { "all" })
          luasnip.filetype_extend("zig", { "all" })
          luasnip.filetype_extend("lua", { "all" })
          luasnip.filetype_extend("javascript", { "all" })
          luasnip.filetype_extend("typescript", { "all" })
          luasnip.filetype_extend("rust", { "all" })
          luasnip.filetype_extend("go", { "all" })
          luasnip.filetype_extend("sh", { "all" })
          luasnip.filetype_extend("markdown", { "all" })
          luasnip.filetype_extend("tex", { "all" })

          -- Fallback mappings for LuaSnip.
          -- blink.cmp normally handles these mappings itself.
          km("i", "<Tab>", function()
            if luasnip.choice_active() then
              luasnip.change_choice(1)
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              return "<Tab>"
            end
          end, {
            expr = true,
            silent = true,
            desc = "Expand or jump to next snippet field",
          })

          km("s", "<Tab>", function()
            if luasnip.choice_active() then
              luasnip.change_choice(1)
            elseif luasnip.jumpable(1) then
              luasnip.jump(1)
            end
          end, {
            silent = true,
            desc = "Jump to next snippet field",
          })

          km({ "i", "s" }, "<S-Tab>", function()
            if luasnip.choice_active() then
              luasnip.change_choice(-1)
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            end
          end, {
            silent = true,
            desc = "Jump to previous snippet field",
          })
        end,
      },
    },

    version = "1.*",

    ---@module 'blink.cmp'
    opts = {
      keymap = {
        -- Accept completion with Tab without showing the menu,
        -- unless the cursor is right before a closing char that
        -- tabout.nvim handles (), ], ', ", ` — in that case, defer
        -- to tabout.nvim via "fallback" instead of forcing an accept.
        ["<Tab>"] = {
          function(cmp)
            if cmp.snippet_active() then
              return cmp.snippet_forward()
            end

            local col = vim.api.nvim_win_get_cursor(0)[2]
            local line = vim.api.nvim_get_current_line()
            local next_char = line:sub(col + 1, col + 1)
            local tabout_chars = {
              ["'"] = true,
              ['"'] = true,
              ["`"] = true,
              [")"] = true,
              ["]"] = true,
            }

            if tabout_chars[next_char] then
              return false -- defer to "fallback" -> tabout.nvim
            end

            return cmp.select_and_accept({
              force = true,
            })
          end,
          "fallback",
        },

        -- Move backward through snippet fields.
        ["<S-Tab>"] = {
          "snippet_backward",
          "fallback",
        },

        -- Accept the selected completion.
        ["<CR>"] = {
          "select_and_accept",
          "fallback",
        },

        -- Hide the completion menu.
        ["<C-e>"] = {
          "hide",
          "fallback",
        },

        -- Show the completion menu manually.
        ["<C-space>"] = {
          "show",
          "fallback",
        },

        -- Some terminals send <C-space> as <C-@>.
        ["<C-@>"] = {
          "show",
          "fallback",
        },

        -- -- Backup manual trigger.
        -- ["<C-j>"] = {
        --   "show",
        --   "fallback",
        -- },

        -- Free <C-k> for the user's own mapping.
        ["gp"] = {
          "show_signature",
          "fallback",
        },

        -- Cycle through completion candidates by inserting them directly
        -- into the buffer, without opening the popup menu (IntelliJ-style).
        ["<C-n>"] = {
          "insert_next",
          "fallback",
        },

        ["<C-p>"] = {
          "insert_prev",
          "fallback",
        },
      },

      appearance = {
        nerd_font_variant = "mono",
      },

      signature = {
        enabled = true,
        auto_show = false,
        window = {
          show_documentation = false,
        },
      },

      completion = {
        trigger = {
          show_on_insert_on_trigger_character = false,
          show_on_accept_on_trigger_character = false,

          show_on_blocked_trigger_characters = {
            "{",
            "(",
            "}",
            ")",
          },
        },

        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },

        menu = {
          auto_show = false,
          scrollbar = false,

          draw = {
            columns = {
              { "kind_icon" },
              { "label",             "label_description", gap = 1 },
              { "kind",              gap = 1 },
              { "label_description", gap = 1 },
              { "source_name",       gap = 1 },
            },

            components = {
              kind_icon = {
                ellipsis = false,
                width = { fill = true },

                text = function(ctx)
                  local kind_icons = {
                    Function = "λ",
                    Method = "∂",
                    Field = "󰀫",
                    Variable = "󰀫",
                    Property = "󰀫",
                    Keyword = "k",
                    Struct = "Π",
                    Enum = "τ",
                    EnumMember = "τ",
                    Snippet = "⊂",
                    Text = "τ",
                    Module = "⌠",
                    Constructor = "∑",
                  }

                  local icon = kind_icons[ctx.kind]

                  if icon == nil then
                    icon = ctx.kind_icon
                  end

                  return icon
                end,
              },
            },
          },
        },

        -- Keep the first completion available for Tab.
        list = {
          selection = {
            preselect = true,
            auto_insert = false,
          },
          cycle = {
            from_bottom = true, -- wrap to the first item after the last
            from_top = true,    -- wrap to the last item after the first
          },
        },
      },

      snippets = {
        preset = "luasnip",
      },

      sources = {
        default = {
          "lsp",
          "path",
          "snippets",
          "buffer",
        },
      },

      fuzzy = {
        implementation = "prefer_rust_with_warning",
      },
    },

    opts_extend = {
      "sources.default",
    },
  },
}
