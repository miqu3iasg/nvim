-- lua/plugins/completions.lua

-- This configuration requires ripgrep and git to be installed
-- on your machine. Lazy.nvim installs the Neovim plugins automatically.
--
-- Ripgrep is used by blink-ripgrep.nvim to provide project-wide
-- completion suggestions from the contents of your files.
--
-- You can install the required dependencies on Arch Linux via:
--
-- `sudo pacman -S ripgrep`
--
-- blink.cmp uses a Rust-based fuzzy matching implementation.
-- The plugin can use its prebuilt binary or compile it locally
-- when necessary. If local compilation is required, install Rust:
--
-- `sudo pacman -S rust`
--
-- LuaSnip, blink.cmp, and blink-ripgrep.nvim are installed
-- automatically by Lazy.nvim.
--
-- refs:
--     - https://github.com/Saghen/blink.cmp
--     - https://github.com/L3MON4D3/LuaSnip
--     - https://github.com/mikavilpas/blink-ripgrep.nvim
--     - https://github.com/folke/lazydev.nvim

local thin_border = { "▁", "▁", "▁", "🮇", "▔", "▔", "▔", "▎" }

return {
  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        dependencies = {
          "rafamadriz/friendly-snippets",
        },
        config = function()
          local luasnip = require("luasnip")
          local km = vim.keymap.set

          luasnip.setup({
            enable_autosnippets = true,
            store_selection_keys = "<Tab>",
            update_events = "TextChanged,TextChangedI",
            region_check_events = "InsertEnter",
            delete_check_events = "TextChanged",
          })

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

          require("luasnip.loaders.from_vscode").lazy_load({ exclude = { "tex" } })

          load_snippets("tex", "snippets.latex")
          load_snippets("c", "snippets.c")
          load_snippets("python", "snippets.python")
          load_snippets("java", "snippets.java")

          -- Global snippets.
          load_snippets("common", "snippets.common")

          luasnip.filetype_extend("python", { "common" })
          luasnip.filetype_extend("c", { "common" })
          luasnip.filetype_extend("scheme", { "common" })
          luasnip.filetype_extend("cpp", { "common" })
          luasnip.filetype_extend("zig", { "common" })
          luasnip.filetype_extend("lua", { "common" })
          luasnip.filetype_extend("java", { "common" })
          luasnip.filetype_extend("javascript", { "common" })
          luasnip.filetype_extend("typescript", { "common" })
          luasnip.filetype_extend("rust", { "common" })
          luasnip.filetype_extend("go", { "common" })
          luasnip.filetype_extend("sh", { "common" })
          luasnip.filetype_extend("markdown", { "common" })
          luasnip.filetype_extend("tex", { "common" })

          -- Fallback mappings for LuaSnip.
          -- blink.cmp normally handles these mappings.
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
      -- Ripgrep/gitgrep completion source for blink.cmp.
      {
        "mikavilpas/blink-ripgrep.nvim",
        version = "*",
      },
    },

    version = "1.*",

    ---@module "blink.cmp"
    opts = {
      keymap = {
        -- Accept completion with Tab without showing the menu.
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
              ["}"] = true,
              ["$"] = true,
              ["%"] = true,
              ["\\"] = true,
            }

            if tabout_chars[next_char] then
              return false -- Let tabout.nvim handle it.
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

        -- Move to the next/previous item in the completion menu, freeing
        -- <Tab>/<S-Tab> to mean only "expand or jump snippet field".
        ["<C-n>"] = {
          "select_next",
          "fallback",
        },
        ["<C-p>"] = {
          "select_prev",
          "fallback",
        },

        -- Cycle LuaSnip choice nodes when one is active; otherwise hide
        -- the completion menu (its previous, sole behavior).
        ["<C-e>"] = {
          function(cmp)
            local luasnip = require("luasnip")
            if luasnip.choice_active() then
              luasnip.change_choice(1)
              return true
            end
            return false
          end,
          "hide",
          "fallback",
        },

        -- Show the completion menu manually.
        ["<C-y>"] = {
          "show",
          "fallback",
        },

        -- Free <C-k> for the user's own mapping.
        ["gp"] = {
          "show_signature",
          "fallback",
        },
      },

      appearance = {
        nerd_font_variant = "mono",
      },
      signature = {
        enabled = true,
        trigger = {
          enabled = false,
        },
        window = {
          border = thin_border,
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
          window = {
            border = thin_border,
          },
        },

        -- Ghost text previews the top completion candidate as virtual text
        -- after the cursor. Enable it only in LaTeX buffers, where it is useful
        -- inside formulas and commands but distracting in prose/code.
        -- `enabled` accepts a function evaluated per completion, matching the
        -- pattern used by blink.cmp for its top-level `enabled` and
        -- `cmdline.completion.menu.auto_show` options.
        ghost_text = {
          enabled = function()
            return vim.bo.filetype == "tex"
          end,
        },

        menu = {
          border    = thin_border,
          auto_show = false,
          scrollbar = false,

          draw      = {
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
            from_bottom = true, -- Wrap to the first item.
            from_top = true,    -- Wrap to the last item.
          },
        },
      },

      snippets = {
        preset = "luasnip",
      },

      sources = {
        default = {
          "lazydev",
          "lsp",
          "path",
          "snippets",
          "buffer",
          "ripgrep",
        },

        providers = {
          -- LazyDev provides precise Neovim/Lua API completions.
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },

          -- Project-wide ripgrep-powered completions.
          ripgrep = {
            module = "blink-ripgrep",
            name = "Ripgrep",
            ---@module "blink-ripgrep"
            ---@type blink-ripgrep.Options
            opts = {
              prefix_min_len = 3,
            },
          },
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
