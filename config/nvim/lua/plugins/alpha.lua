return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = false },
      picker = {
        sources = {
          projects = {
            dev = { "~/develop" },
          },
        },
      },
    },
  },
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      dashboard.section.header.val = {
        [[                                                 ]],
        [[       ███████████           █████      ██ ]],
        [[      ███████████             █████  ]],
        [[      ████████████████ ███████████ ███   ███████ ]],
        [[     ████████████████ ████████████ █████ ██████████████ ]],
        [[    █████████████████████████████ █████ █████ ████ █████ ]],
        [[  ██████████████████████████████████ █████ █████ ████ █████ ]],
        [[ ██████  ███ █████████████████ ████ █████ █████ ████ ██████ ]],
        [[ ██████   ██  ███████████████   ██ █████████████████ ]],
        [[ ██████   ██  ███████████████   ██ █████████████████ ]],
      }

      dashboard.section.buttons.val = {
        dashboard.button("e", "  > New File", ":ene<BAR> startinsert<CR>"),
        dashboard.button("f", "  > Find file", "<cmd> lua LazyVim.pick()() <cr>"),
        dashboard.button("p", "  > Projects", "<cmd> lua Snacks.picker.projects() <cr>"),
        dashboard.button("r", "  > Recent files", "<cmd> lua LazyVim.pick('oldfiles')() <cr>"),
        dashboard.button("g", "  > Find text", "<cmd> lua LazyVim.pick('live_grep')() <cr>"),
        dashboard.button("s", "  > Restore Session", [[<cmd> lua require("persistence").load() <cr>]]),
        dashboard.button("q", "  > Quit NVIM", ":qa<CR>"),
      }

      for _, button in ipairs(dashboard.section.buttons.val) do
        button.opts.hl = "AlphaButtons"
        button.opts.hl_shortcut = "AlphaShortcut"
      end

      dashboard.section.header.opts.hl = "AlphaHeader"
      dashboard.section.buttons.opts.hl = "AlphaButtons"
      dashboard.section.footer.opts.hl = "AlphaFooter"

      dashboard.opts.layout = {
        {
          type = "group",
          val = {
            dashboard.section.header,
            { type = "padding", val = 2 },
            dashboard.section.buttons,
          },
          opts = { position = "v_center" },
        },
        dashboard.section.footer,
      }

      alpha.setup(dashboard.opts)

      vim.api.nvim_create_autocmd("User", {
        once = true,
        pattern = "LazyVimStarted",
        callback = function()
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          dashboard.section.footer.val = "  Neovim loaded "
            .. stats.loaded
            .. "/"
            .. stats.count
            .. " plugins in "
            .. ms
            .. "ms"
          pcall(vim.cmd.AlphaRedraw)
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "alpha",
        callback = function()
          vim.opt_local.foldenable = false
        end,
      })
    end,
  },
}
