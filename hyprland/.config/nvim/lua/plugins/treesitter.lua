return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if not opts.ensure_installed then
        opts.ensure_installed = {}
      end
      -- Ensure the requested programming languages are installed
      vim.list_extend(opts.ensure_installed, {
        "c",
        "cpp",
        "java",
        "python",
        "r",
        "rust",
        "sql",
        "lua",
        "javascript",
      })
      opts.highlight = { enable = true }
      opts.indent = { enable = true }
    end,
  },
}
