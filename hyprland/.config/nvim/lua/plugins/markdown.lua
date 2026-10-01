local function toggle_surround_visual(surround_tag)
  -- Obtener las posiciones de la selección visual
  vim.cmd('normal! "xy')
  local text = vim.fn.getreg("x")
  local escaped = surround_tag:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
  local pattern = "^" .. escaped .. "(.-)" .. escaped .. "$"
  local inner = text:match(pattern)

  if inner then
    vim.cmd("normal! gvc" .. inner)
  else
    vim.cmd("normal! gvc" .. surround_tag .. text .. surround_tag)
  end
end

local function toggle_surround_normal(surround_tag)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local line = vim.api.nvim_get_current_line()

  if line == "" then
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("i" .. surround_tag .. surround_tag .. "<Left><Left>", true, false, true),
      "n",
      true
    )
    return
  end

  -- Detectar límites de la palabra bajo el cursor
  local left = col + 1
  while left > 1 and line:sub(left - 1, left - 1):match("[%w_]") do
    left = left - 1
  end
  local right = col + 1
  while right <= #line and line:sub(right, right):match("[%w_]") do
    right = right + 1
  end

  if left >= right then
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("i" .. surround_tag .. surround_tag .. "<Left><Left>", true, false, true),
      "n",
      true
    )
    return
  end

  local s_col = left - 1
  local e_col = right - 1
  local s_len = #surround_tag

  -- Si ya tiene los tags antes y después, quitarlos
  local before_start = s_col - s_len
  local after_end = e_col + s_len
  if before_start >= 0 and after_end <= #line then
    local prefix = line:sub(before_start + 1, s_col)
    local suffix = line:sub(e_col + 1, after_end)
    if prefix == surround_tag and suffix == surround_tag then
      vim.api.nvim_buf_set_text(0, row, e_col, row, after_end, { "" })
      vim.api.nvim_buf_set_text(0, row, before_start, row, s_col, { "" })
      return
    end
  end

  -- Si no los tiene, envolver la palabra
  local word = line:sub(s_col + 1, e_col)
  vim.api.nvim_buf_set_text(0, row, s_col, row, e_col, { surround_tag .. word .. surround_tag })
end

-- Atajos automáticos solo para archivos Markdown
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "rmd", "quarto" },
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true }

    -- Configuración de indentación a 4 espacios para Markdown
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true

    -- Corrector ortográfico en español e inglés
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { "es", "en" }


    -- Ctrl + b: Negrita (Insert, Visual y Normal)
    vim.keymap.set("i", "<C-b>", "****<Left><Left>", vim.tbl_extend("force", opts, { desc = "Insertar negrita" }))
    vim.keymap.set("x", "<C-b>", function()
      toggle_surround_visual("**")
    end, vim.tbl_extend("force", opts, { desc = "Toggle negrita en selección" }))
    vim.keymap.set("n", "<C-b>", function()
      toggle_surround_normal("**")
    end, vim.tbl_extend("force", opts, { desc = "Toggle negrita en palabra" }))

    -- Ctrl + i: Cursiva (Insert, Visual y Normal)
    vim.keymap.set("i", "<C-i>", "**<Left>", vim.tbl_extend("force", opts, { desc = "Insertar cursiva" }))
    vim.keymap.set("x", "<C-i>", function()
      toggle_surround_visual("*")
    end, vim.tbl_extend("force", opts, { desc = "Toggle cursiva en selección" }))
    vim.keymap.set("n", "<C-i>", function()
      toggle_surround_normal("*")
    end, vim.tbl_extend("force", opts, { desc = "Toggle cursiva en palabra" }))

    -- Ctrl + k: Enlace Markdown [texto](url)
    vim.keymap.set("i", "<C-k>", "[]()<Left><Left><Left>", vim.tbl_extend("force", opts, { desc = "Insertar enlace" }))
    vim.keymap.set("x", "<C-k>", function()
      vim.cmd('normal! "xy')
      local text = vim.fn.getreg("x")
      vim.cmd("normal! gvc[" .. text .. "]()")
    end, vim.tbl_extend("force", opts, { desc = "Convertir selección en enlace" }))
  end,
})

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ["markdown_fast"] = {
          meta = {
            description = "Formateador ultrarrápido nativo en Lua para Markdown",
          },
          format = function(self, ctx, lines, callback)
            local out = {}
            local in_code_block = false

            for i, line in ipairs(lines) do
              -- Detectar bloques de código ```
              if line:match("^%s*```") then
                in_code_block = not in_code_block
                table.insert(out, line)
              elseif in_code_block then
                table.insert(out, line)
              else
                -- 1. Regla MD022: Asegurar línea en blanco antes de encabezados (#) si no es la primera línea
                if line:match("^#+%s") and #out > 0 then
                  local prev = out[#out]
                  if prev ~= "" and not prev:match("^%-%-%-%s*$") then
                    table.insert(out, "")
                  end
                end

                -- 2. Regla MD007: Ajustar indentación de sublistas a múltiplos de 4 espacios
                local spaces, marker, rest = line:match("^(%s*)([%-%*%+]%s+)(.*)$")
                if not spaces then
                  spaces, marker, rest = line:match("^(%s*)(%d+%.%s+)(.*)$")
                end

                if spaces and #spaces > 0 then
                  local num_spaces = #spaces
                  local level = math.max(1, math.floor((num_spaces + 2) / 4))
                  local new_indent = string.rep("    ", level)
                  table.insert(out, new_indent .. marker .. rest)
                else
                  table.insert(out, line)
                end
              end
            end

            callback(nil, out)
          end,
        },
      },
      formatters_by_ft = {
        markdown = { "markdown_fast" },
        ["markdown.mdx"] = { "markdown_fast" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local lint = require("lint")
      local config_path = vim.fn.expand("~/.markdownlint.yaml")

      -- Configurar markdownlint-cli2 para que use nuestro archivo de reglas
      local linter = lint.linters["markdownlint-cli2"]
      if linter then
        linter.args = { "--config", config_path, "-" }
      end
    end,
  },
}
