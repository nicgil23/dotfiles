-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Dynamically reload colorscheme when receiving SIGUSR1 from Matugen
vim.api.nvim_create_autocmd("Signal", {
    pattern = "SIGUSR1",
    callback = function()
        -- Reload catppuccin config with new matugen colors
        local catppuccin = require("catppuccin")
        
        -- Try to reload module to re-evaluate the json
        package.loaded["plugins.custom"] = nil
        
        -- Force re-compile
        vim.cmd("CatppuccinCompile")
        vim.cmd("colorscheme catppuccin")
        
        -- Notify the user
        vim.notify("Colorscheme reloaded from Matugen!", vim.log.levels.INFO)
    end,
})
