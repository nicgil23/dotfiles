return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        width = 56,
        sections = {
          {
            section = "terminal",
            cmd = "cat " .. vim.fn.stdpath("config") .. "/anime_header.txt",
            align = "center",
            width = 56,
            height = 13,
            padding = 1,
            ttl = 86400,
            hl = "Normal",
          },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },
}
