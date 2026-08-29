return {
  {
    "folke/noice.nvim",
    opts = {
      -- Use the classic bottom cmdline instead of noice's popup UI.
      cmdline = { enabled = false },
      popupmenu = { enabled = false },
      presets = {
        bottom_search = false,
        command_palette = false,
      },
    },
  },
}
