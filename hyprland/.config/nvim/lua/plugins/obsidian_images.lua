local M = {}

-- Ruta de la carpeta de Anexos en tu bóveda de Obsidian
local ANEXOS_PATH = vim.fn.expand("/home/hypr/Documents/Obsidian/Obsidian/Capa 1 - 🗑️ Archivo/Anexos")

---Asegura que el directorio de anexos existe
local function ensure_anexos_dir()
  if vim.fn.isdirectory(ANEXOS_PATH) == 0 then
    vim.fn.mkdir(ANEXOS_PATH, "p")
  end
end

---Genera un nombre de archivo único con el formato de timestamp de Obsidian
---@return string filename, string full_path
local function generate_image_filename()
  ensure_anexos_dir()
  local timestamp = os.date("%Y%m%d%H%M%S")
  local filename = string.format("Pasted image %s.png", timestamp)
  local full_path = ANEXOS_PATH .. "/" .. filename
  return filename, full_path
end

---Inserta el enlace Markdown/Wikilink de Obsidian en la posición actual del cursor
---@param filename string
local function insert_image_link(filename)
  local link = string.format("![[%s|center]]", filename)
  local current_buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local current_line = vim.api.nvim_get_current_line()

  if current_line == "" then
    vim.api.nvim_set_current_line(link)
  else
    vim.api.nvim_buf_set_lines(current_buf, row, row, false, { link })
    pcall(vim.api.nvim_win_set_cursor, 0, { row + 1, #link })
  end

  vim.notify("Imagen guardada e insertada: " .. filename, vim.log.levels.INFO)
end

---Pega la imagen desde el portapapeles (Wayland / wl-paste)
function M.paste_image()
  local filename, full_path = generate_image_filename()

  -- Ejecutar wl-paste para obtener los bytes de la imagen
  local proc = vim.system({ "wl-paste", "--type", "image/png" }, { text = false }):wait()

  if proc.code ~= 0 or not proc.stdout or #proc.stdout == 0 then
    -- Intentar también con JPEG si no es PNG
    proc = vim.system({ "wl-paste", "--type", "image/jpeg" }, { text = false }):wait()
  end

  if proc.code ~= 0 or not proc.stdout or #proc.stdout == 0 then
    vim.notify("No se encontró ninguna imagen en el portapapeles.", vim.log.levels.WARN)
    return
  end

  local file = io.open(full_path, "wb")
  if not file then
    vim.notify("Error al escribir el archivo de imagen en: " .. full_path, vim.log.levels.ERROR)
    return
  end

  file:write(proc.stdout)
  file:close()

  insert_image_link(filename)
end

-- Registrar Comandos de usuario
vim.api.nvim_create_user_command("ObsidianPasteImage", function()
  M.paste_image()
end, { desc = "Pegar imagen del portapapeles en Anexos de Obsidian" })

-- Atajos de teclado
vim.keymap.set("n", "<leader>op", function()
  M.paste_image()
end, { desc = "Obsidian: Pegar imagen del portapapeles" })

-- Exportar módulo
package.loaded["obsidian_images"] = M
_G.ObsidianImages = M

return {}
