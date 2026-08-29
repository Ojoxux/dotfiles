return {
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
    opts = {
      window = { width = 90 },
      plugins = {
        options = { laststatus = 0 },
        tmux = { enabled = false },
      },
    },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      heading = { width = "block", left_pad = 1, right_pad = 2 },
      code = { width = "block", left_pad = 1, right_pad = 2 },
    },
  },
}
