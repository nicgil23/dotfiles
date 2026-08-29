local function get_matugen_colors()
    local path = vim.fn.expand("~/.local/state/quickshell/user/generated/colors.json")
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    local ok, parsed = pcall(vim.fn.json_decode, content)
    if not ok then return nil end
    return parsed
end

local function get_overrides()
    local matugen = get_matugen_colors()
    if not matugen then return {} end

    return {
        mocha = {
            base = matugen.background,
            mantle = matugen.surface,
            crust = matugen.surface_dim,
            text = matugen.on_surface,
            subtext1 = matugen.on_surface_variant,
            subtext0 = matugen.on_surface_variant,
            overlay2 = matugen.outline,
            overlay1 = matugen.outline_variant,
            overlay0 = matugen.surface_variant,
            surface2 = matugen.surface_container_highest,
            surface1 = matugen.surface_container_high,
            surface0 = matugen.surface_container,
            blue = matugen.primary,
            lavender = matugen.primary_fixed,
            sapphire = matugen.secondary_fixed,
            sky = matugen.secondary_fixed_dim,
            teal = matugen.tertiary_fixed,
            green = matugen.tertiary,
            yellow = matugen.primary_fixed_dim,
            peach = matugen.secondary,
            maroon = matugen.error_container,
            red = matugen.error,
            mauve = matugen.primary_container,
            pink = matugen.tertiary_container,
            flamingo = matugen.tertiary_fixed_dim,
            rosewater = matugen.on_primary_container,
        }
    }
end

return {
    {
        "nvim-mini/mini.base16",
        lazy = false,
        priority = 1000,
        config = function()
            local path = vim.fn.expand("~/.local/state/quickshell/user/generated/colors.json")
            local f = io.open(path, "r")
            if f then
                local content = f:read("*a")
                f:close()
                local ok, parsed = pcall(vim.fn.json_decode, content)
                if ok and parsed then
                    require("mini.base16").setup({
                        palette = {
                            base00 = parsed.background,
                            base01 = parsed.surface,
                            base02 = parsed.surface_variant,
                            base03 = parsed.outline,
                            base04 = parsed.on_surface_variant,
                            base05 = parsed.on_surface,
                            base06 = parsed.primary_fixed_dim,
                            base07 = parsed.primary,
                            base08 = parsed.error,
                            base09 = parsed.tertiary,
                            base0A = parsed.secondary,
                            base0B = parsed.primary,
                            base0C = parsed.secondary_fixed_dim,
                            base0D = parsed.primary_fixed,
                            base0E = parsed.tertiary_fixed,
                            base0F = parsed.error_container,
                        }
                    })
                    
                    -- Make background transparent
                    local transparent_hls = {
                        "Normal", "NormalNC", "LineNr", "SignColumn", "EndOfBuffer",
                        "NeoTreeNormal", "NeoTreeNormalNC", "TelescopeNormal", "TelescopeBorder"
                    }
                    for _, hl in ipairs(transparent_hls) do
                        vim.api.nvim_set_hl(0, hl, { bg = "NONE", ctermbg = "NONE" })
                    end
                    
                    return
                end
            end
            
            -- Fallback if not found
            require("mini.base16").setup({
                palette = require("mini.base16").mini_palette("#112233", "#ffffff")
            })
        end,
    },

    -- Configure LazyVim to use default colorscheme so our override is applied cleanly
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "default",
        },
    },

    {
        "saghen/blink.cmp",
        opts = {
            keymap = {
                preset = "enter",
                ["<Tab>"] = { "accept", "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "snippet_backward", "fallback" },
            },
        },
    },
}

