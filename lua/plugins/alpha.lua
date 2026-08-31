return {
  "goolord/alpha-nvim",
  enabled = true,
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- Set header
    dashboard.section.header.val = {
      [[                                                                     ]],
      [[       ███████████           █████      ██                     ]],
      [[      ███████████             █████                             ]],
      [[      ████████████████ ███████████ ███   ███████     ]],
      [[     ████████████████ ████████████ █████ ██████████████   ]],
      [[    █████████████████████████████ █████ █████ ████ █████   ]],
      [[  ██████████████████████████████████ █████ █████ ████ █████  ]],
      [[ ██████  ███ █████████████████ ████ █████ █████ ████ ██████ ]],
      [[ ██████   ██  ███████████████   ██ █████████████████ ]],
      [[ ██████   ██  ███████████████   ██ █████████████████ ]],
      [[                                                                       ]],
      [[                                                                       ]],
      [[                                                                       ]],
    }

    -- Set menu
    dashboard.section.buttons.val = {
      dashboard.button("e", "λ  > New file", ":ene<CR>"),
      dashboard.button("b", "λ  > Browse files", ":Yazi<CR>"),
      dashboard.button("z", "λ  > Browse Directories", ":Telescope zoxide list<CR>"),
      dashboard.button("f", "λ  > Find file", ":Telescope find_files<CR>"),
      dashboard.button("r", "λ  > Recent", ":Telescope oldfiles<CR>"),
      dashboard.button("q", "λ  > Quit NVIM", ":qa<CR>"),
    }

    -- Send config to alpha
    alpha.setup(dashboard.opts)

    -- Disable folding on alpha buffer
    vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
  end,
}
