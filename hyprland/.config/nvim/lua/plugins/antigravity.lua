local function toggle_agy()
    local term = Snacks.terminal.get("agy", { create = false })
    if term and term:win_valid() and vim.api.nvim_get_current_win() == term.win then
        -- Si el cursor está dentro de la ventana de la IA, no cerrar el sidebar
        return
    end
    Snacks.terminal.toggle("agy", {
        win = {
            position = "right",
            width = 0.45,
            title = " Antigravity AI ",
            title_pos = "center",
            wo = {
                winbar = "",
                wrap = false,
                number = false,
                relativenumber = false,
                signcolumn = "no",
            },
        },
    })
end

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
                toggle_agy,
                mode = "n",
                desc = "Toggle Antigravity AI (Side Split)",
            },
        },
    },
}
