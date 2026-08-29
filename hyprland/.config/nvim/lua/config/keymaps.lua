-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Delete word backward (Ctrl+Backspace) in insert and command-line modes
vim.keymap.set("i", "<C-Backspace>", "<C-w>", { noremap = true, silent = true, desc = "Delete word backward" })
vim.keymap.set("i", "<C-BS>", "<C-w>", { noremap = true, silent = true, desc = "Delete word backward" })
vim.keymap.set("c", "<C-Backspace>", "<C-w>", { noremap = true, silent = true, desc = "Delete word backward" })
vim.keymap.set("c", "<C-BS>", "<C-w>", { noremap = true, silent = true, desc = "Delete word backward" })

-- Delete word forward (Ctrl+Delete) in insert and command-line modes
vim.keymap.set("i", "<C-Delete>", "<C-o>dw", { noremap = true, silent = true, desc = "Delete word forward" })
vim.keymap.set("i", "<C-Del>", "<C-o>dw", { noremap = true, silent = true, desc = "Delete word forward" })

local function delete_word_forward_cmd()
    local pos = vim.fn.getcmdpos()
    local cmd = vim.fn.getcmdline()
    local before = string.sub(cmd, 1, pos - 1)
    local after = string.sub(cmd, pos)
    local new_after
    if string.match(after, "^%s+") then
        new_after = string.gsub(after, "^%s*%w*%s*", "", 1)
    elseif string.match(after, "^%w+") then
        new_after = string.gsub(after, "^%w+%s*", "", 1)
    else
        new_after = string.gsub(after, "^%p+%s*", "", 1)
    end
    vim.fn.setcmdline(before .. new_after)
end

vim.keymap.set(
    "c",
    "<C-Delete>",
    delete_word_forward_cmd,
    { noremap = true, silent = true, desc = "Delete word forward" }
)
vim.keymap.set("c", "<C-Del>", delete_word_forward_cmd, { noremap = true, silent = true, desc = "Delete word forward" })

-- Delete without copying (d + Space)
vim.keymap.set("n", "d<Space>", '"_dd', { noremap = true, silent = true, desc = "Delete line without copying" })
vim.keymap.set("v", "d<Space>", '"_d', { noremap = true, silent = true, desc = "Delete selection without copying" })

-- Telescope and Ripgrep global search
vim.keymap.set(
    "n",
    "<leader>fg",
    "<cmd>Telescope live_grep<cr>",
    { noremap = true, silent = true, desc = "Find Text globally (Ripgrep)" }
)
vim.keymap.set(
    "n",
    "<leader>fw",
    "<cmd>Telescope grep_string<cr>",
    { noremap = true, silent = true, desc = "Find Word under cursor globally (Ripgrep)" }
)

-- Buffer navigation with Ctrl+h / Ctrl+l (previous / next buffer)
vim.keymap.set("n", "<C-h>", "<cmd>bprevious<cr>", { noremap = true, silent = true, desc = "Prev Buffer" })
vim.keymap.set("n", "<C-l>", "<cmd>bnext<cr>", { noremap = true, silent = true, desc = "Next Buffer" })

-- Window navigation with Shift+h / Shift+l (left / right split window)
vim.keymap.set("n", "H", "<C-w>h", { noremap = true, silent = true, desc = "Go to Left Window" })
vim.keymap.set("n", "L", "<C-w>l", { noremap = true, silent = true, desc = "Go to Right Window" })
