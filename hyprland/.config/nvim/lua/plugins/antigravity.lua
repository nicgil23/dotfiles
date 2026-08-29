return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = { enabled = true },
    },
    keys = {
      -- Vista Split Lateral a la derecha con <leader>aa o <leader>ai
      {
        "<leader>aa",
        function()
          Snacks.terminal.toggle("agy", {
            win = {
              position = "right",
              width = 0.45,
              title = " Antigravity AI ",
              title_pos = "center",
              wo = {
                winbar = "",
              },
            },
          })
        end,
        mode = { "n", "t" },
        desc = "Toggle Antigravity AI (Side Split)",
      },
      {
        "<leader>ai",
        function()
          Snacks.terminal.toggle("agy", {
            win = {
              position = "right",
              width = 0.45,
              title = " Antigravity AI ",
              title_pos = "center",
              wo = {
                winbar = "",
              },
            },
          })
        end,
        mode = { "n", "t" },
        desc = "Toggle Antigravity AI (Side Split)",
      },
    },
  },
}
