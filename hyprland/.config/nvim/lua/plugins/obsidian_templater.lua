local M = {}

-- Ruta base de la bóveda y de las plantillas de Obsidian
local VAULT_PATH = vim.fn.expand("~/Documents/Obsidian")
local TEMPLATES_PATH = vim.fn.expand("~/Documents/Obsidian/Obsidian/Capa 99 - 🍌 Meta/Capa 99.1 - 🧱 PLANTILLAS")

---Convierte formatos de fecha de Moment.js (utilizados por Templater) a strftime
---@param fmt string|nil
---@return string
local function moment_to_strftime(fmt)
  if not fmt or fmt == "" then
    return "%Y-%m-%d"
  end
  local s = fmt
  s = s:gsub("YYYY", "%%Y")
  s = s:gsub("YY", "%%y")
  s = s:gsub("MMMM", "%%B")
  s = s:gsub("MMM", "%%b")
  s = s:gsub("MM", "%%m")
  s = s:gsub("DDDD", "%%j")
  s = s:gsub("DD", "%%d")
  s = s:gsub("dddd", "%%A")
  s = s:gsub("ddd", "%%a")
  s = s:gsub("HH", "%%H")
  s = s:gsub("hh", "%%I")
  s = s:gsub("mm", "%%M")
  s = s:gsub("ss", "%%S")
  s = s:gsub("A", "%%p")
  s = s:gsub("a", "%%p")
  return s
end

---Obtiene la fecha formateada con offset opcional en días
---@param fmt string|nil
---@param offset number|string|nil
---@return string
local function get_date(fmt, offset)
  local strftime_fmt = moment_to_strftime(fmt)
  local t = os.time()
  if offset then
    local num = tonumber(offset)
    if num then
      t = t + (num * 86400)
    end
  end
  return os.date(strftime_fmt, t)
end

---Crea el entorno de evaluación de Templater (objeto tp)
---@param ctx table
---@return table
local function create_tp_env(ctx)
  local tp = {
    date = {
      now = function(fmt, offset)
        return get_date(fmt, offset)
      end,
      yesterday = function(fmt)
        return get_date(fmt, -1)
      end,
      tomorrow = function(fmt)
        return get_date(fmt, 1)
      end,
    },
    file = {
      title = ctx.title or "",
      folder = function()
        return ctx.folder or ""
      end,
      path = function()
        return ctx.path or ""
      end,
      creation_date = function(fmt)
        return get_date(fmt)
      end,
      last_modified_date = function(fmt)
        return get_date(fmt)
      end,
      cursor = function()
        return "%%TP_CURSOR%%"
      end,
    },
    system = {
      prompt = function(prompt_text, default_value)
        return default_value or ""
      end,
    },
    obsidian = {
      vault_path = VAULT_PATH,
      templates_path = TEMPLATES_PATH,
    },
  }
  return { tp = tp, string = string, math = math, table = table, os = os }
end

---Evalúa el contenido de una plantilla de Templater y devuelve las líneas renderizadas y la posición del cursor
---@param content string
---@param ctx table
---@return string[], table|nil
function M.eval_template(content, ctx)
  local env = create_tp_env(ctx)

  -- Evaluar todas las etiquetas Templater: <% ... %>, <%_ ... _%>, <%- ... -%>
  local rendered = content:gsub("<%%[%_%-%*]?%s*(.-)%s*[%_%-%*]?%%>", function(code)
    -- Limpiar posibles caracteres sobrantes
    local clean_code = code:gsub("^%s*return%s+", ""):gsub(";%s*$", "")
    local chunk, err = load("return " .. clean_code, "=templater", "t", env)
    if chunk then
      local ok, res = pcall(chunk)
      if ok and res ~= nil then
        return tostring(res)
      end
    end
    return ""
  end)

  local lines = vim.split(rendered, "\n", { plain = true })
  local cursor_pos = nil

  -- Buscar posición óptima de cursor
  for i, line in ipairs(lines) do
    local s, e = line:find("%%%%TP_CURSOR%%%%")
    if s then
      lines[i] = line:sub(1, s - 1) .. line:sub(e + 1)
      cursor_pos = { i, s - 1 }
      break
    end
  end

  -- Si no había etiqueta de cursor explícita, colocarlo en el primer encabezado (# o ##)
  if not cursor_pos then
    for i, line in ipairs(lines) do
      if line:match("^#+%s*$") then
        cursor_pos = { i, #line }
        break
      end
    end
  end

  return lines, cursor_pos
end

---Escanea recursivamente la carpeta de plantillas
---@return table[]
function M.get_templates()
  local templates = {}
  local scan_dir
  scan_dir = function(dir, prefix)
    local handle = vim.uv.fs_scandir(dir)
    if not handle then
      return
    end
    while true do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then
        break
      end
      local full_path = dir .. "/" .. name
      if type == "directory" then
        local next_prefix = (prefix == "" and name or (prefix .. " / " .. name))
        scan_dir(full_path, next_prefix)
      elseif type == "file" and name:match("%.md$") then
        local clean_name = name:gsub("%.md$", "")
        local display_name = (prefix == "" and clean_name or (prefix .. " / " .. clean_name))
        -- Limpiar nombres repetitivos como 'Plantilla Idiomas / Plantilla Inglés'
        display_name = display_name:gsub("^Plantilla%s*", "")
        table.insert(templates, {
          path = full_path,
          name = name,
          display_name = display_name,
        })
      end
    end
  end

  scan_dir(TEMPLATES_PATH, "")

  -- Ordenar alfabéticamente
  table.sort(templates, function(a, b)
    return a.display_name < b.display_name
  end)

  return templates
end

---Inserta una plantilla en el buffer actual
---@param template_path string
function M.apply_template_to_current_buffer(template_path)
  local file = io.open(template_path, "r")
  if not file then
    vim.notify("No se pudo abrir la plantilla: " .. template_path, vim.log.levels.ERROR)
    return
  end
  local content = file:read("*a")
  file:close()

  local current_buf = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(current_buf)
  local title = vim.fn.fnamemodify(current_file, ":t:r")
  if title == "" then
    title = "Sin Título"
  end

  local ctx = {
    title = title,
    folder = vim.fn.fnamemodify(current_file, ":p:h:t"),
    path = current_file,
  }

  local lines, cursor_pos = M.eval_template(content, ctx)

  -- Comprobar si el buffer está vacío
  local buf_lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
  local is_empty = (#buf_lines == 0) or (#buf_lines == 1 and buf_lines[1] == "")

  if is_empty then
    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, lines)
    if cursor_pos then
      pcall(vim.api.nvim_win_set_cursor, 0, { cursor_pos[1], cursor_pos[2] })
      vim.cmd("startinsert!")
    end
  else
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(current_buf, row, row, false, lines)
    if cursor_pos then
      pcall(vim.api.nvim_win_set_cursor, 0, { row + cursor_pos[1] - 1, cursor_pos[2] })
      vim.cmd("startinsert!")
    end
  end

  vim.notify("Plantilla aplicada con éxito", vim.log.levels.INFO)
end

---Abre el selector interactivo de plantillas (usa Snacks.picker si está disponible, o vim.ui.select)
---@param on_select function
function M.select_template(on_select)
  local templates = M.get_templates()
  if #templates == 0 then
    vim.notify("No se encontraron plantillas en: " .. TEMPLATES_PATH, vim.log.levels.WARN)
    return
  end

  local ok_snacks, snacks = pcall(require, "snacks")
  if ok_snacks and snacks.picker then
    local items = {}
    for _, t in ipairs(templates) do
      table.insert(items, {
        text = t.display_name,
        file = t.path,
        template = t,
      })
    end

    snacks.picker.pick({
      source = "obsidian_templates",
      items = items,
      format = "text",
      preview = "file",
      confirm = function(picker, item)
        picker:close()
        if item and item.template then
          on_select(item.template.path)
        end
      end,
    })
  else
    local items = {}
    for i, t in ipairs(templates) do
      items[i] = t.display_name
    end
    vim.ui.select(items, { prompt = "Seleccionar Plantilla Obsidian:" }, function(_, idx)
      if idx and templates[idx] then
        on_select(templates[idx].path)
      end
    end)
  end
end

---Comando para insertar plantilla en el archivo abierto
function M.insert_template()
  M.select_template(function(template_path)
    M.apply_template_to_current_buffer(template_path)
  end)
end

---Comando para crear una nueva nota en Obsidian a partir de una plantilla
function M.new_note()
  vim.ui.input({ prompt = "Nombre de la nueva nota (Obsidian): " }, function(input)
    if not input or vim.trim(input) == "" then
      return
    end
    local title = vim.trim(input)
    local filename = title:match("%.md$") and title or (title .. ".md")

    -- Determinar directorio: si el buffer actual está en el vault de Obsidian, usar esa carpeta; si no, usar el vault root
    local cur_dir = vim.fn.expand("%:p:h")
    local target_dir = VAULT_PATH
    if cur_dir:find(VAULT_PATH, 1, true) then
      target_dir = cur_dir
    end

    local full_path = target_dir .. "/" .. filename

    M.select_template(function(template_path)
      vim.cmd.edit(vim.fn.fnameescape(full_path))
      M.apply_template_to_current_buffer(template_path)
      vim.cmd("write")
    end)
  end)
end

-- Registrar comandos de usuario
vim.api.nvim_create_user_command("ObsidianTemplate", function()
  M.insert_template()
end, { desc = "Insertar plantilla de Obsidian" })

vim.api.nvim_create_user_command("ObsidianNew", function()
  M.new_note()
end, { desc = "Crear nueva nota de Obsidian con plantilla" })

-- Atajos de teclado
vim.keymap.set("n", "<leader>oi", function()
  M.insert_template()
end, { desc = "Obsidian: Insertar plantilla (Templater)" })

vim.keymap.set("n", "<leader>on", function()
  M.new_note()
end, { desc = "Obsidian: Nueva nota con plantilla" })

-- Exportar módulo para require
package.loaded["obsidian_templater"] = M
_G.ObsidianTemplater = M

return {}
