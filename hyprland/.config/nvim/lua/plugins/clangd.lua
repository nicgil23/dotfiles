return {
  -- Configuración de clangd (LSP) para C y C++
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never, ColumnLimit: 100, BreakBeforeBraces: Custom, BraceWrapping: {BeforeElse: true}}",
          },
        },
      },
    },
  },

  -- Configuración de conform.nvim para formateo con clang-format a 4 espacios por defecto
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
      },
      formatters = {
        ["clang-format"] = {
          prepend_args = {
            "--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never, ColumnLimit: 100, BreakBeforeBraces: Custom, BraceWrapping: {BeforeElse: true}}",
          },
        },
      },
    },
  },
}
