# Guía de Instalación de Entorno Hyprland

## 1. Preparación del entorno base y gestores de paquetes

El primer paso es asegurar que el sistema está actualizado y dispone de las herramientas fundamentales para compilar y gestionar repositorios.
Se deben instalar las utilidades básicas como `git` para el control de versiones, `stow` para la gestión de los enlaces simbólicos de los archivos de configuración, y utilidades adicionales de red y empaquetado. Además, se requiere el grupo `base-devel` para poder compilar paquetes del AUR.

```bash
sudo pacman -Syu
sudo pacman -S --needed git stow base-devel flatpak rclone
```

Tras esto, es necesario compilar un **gestor de paquetes AUR**, como `yay` o `paru`. En este flujo de ejecución utilizaremos `yay` como referencia.

```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay
```

## 2. Restauración de la paquetería

Con los gestores listos, se procede a la instalación masiva de los programas utilizando las listas previamente guardadas. Es crucial tener los archivos de texto con las listas en el directorio actual, por lo que primero vamos a bajarnos la carpeta de dotfiles:

```bash
git clone https://github.com/nicgil23/dotfiles.git ~/
```

Para los **repositorios oficiales**, se lee el archivo correspondiente y se instalan los paquetes ignorando los que ya estén presentes en el sistema base.

```bash
sudo pacman -S --needed - < lista_pacman.txt
```

Para los **paquetes del AUR**, se repite el proceso utilizando el gestor compilado en el paso anterior.

```bash
yay -S --needed - < lista_aur.txt
```

Es necesario asegurarse de que las dependencias estéticas centrales formaban parte de esa lista. Si no estaban anotadas, se deben instalar manualmente especificando sus nombres exactos en el AUR para asegurar la tipografía y el estilo de las aplicaciones.

```bash
yay -S ttf-jetbrains-mono-nerd catppuccin-gtk-theme-mocha
```

Finalmente, se restauran las **aplicaciones aisladas** en formato flatpak. Se requiere añadir el repositorio Flathub si no se configuró previamente en el sistema base.

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install $(cat lista_flatpak.txt)
```

## 3. Despliegue de los Dotfiles con Stow

La configuración del entorno gráfico, el tema Catppuccin, las fuentes y las aplicaciones de terminal reside en el repositorio de GitHub. Al usar `stow`, se crean enlaces simbólicos limpios desde el directorio clonado hacia las rutas correspondientes del sistema operativo.
Se clona el repositorio en una carpeta dedicada, habitualmente en la raíz del usuario.

```bash
cd ~/dotfiles
```

Se ejecuta `stow` indicando el nombre de los directorios internos que coinciden con la estructura requerida por `.config` o el directorio del usuario. Por ejemplo, si hay carpetas llamadas `hypr`, `waybar` o `kitty`, el comando las enlazará automáticamente.

```bash
stow hyprland # Contiene todas las subcarpetas de configuración de las aplicaciones individuales
```

## 4. Configuración de plugins de Hyprland

Para incorporar la interacción gestual en Hyprland de manera nativa, se debe inicializar el gestor de plugins oficial, `hyprpm`, y compilar el módulo correspondiente.
Primero se actualizan las cabeceras de Hyprland para asegurar la **compatibilidad estricta de los plugins con la versión exacta** del compositor que se acaba de instalar.

```bash
hyprpm update
```

A continuación, se añade el repositorio de código, se habilita y se recarga el entorno.

```bash
hyprpm add https://github.com/horriblename/hyprgrass
hyprpm enable hyprgrass
hyprpm reload
```

## 5. Restauración de recursos estéticos

Los fondos de pantalla seleccionados se deben clonar directamente desde su repositorio de origen hacia el directorio local donde el gestor de fondos `swww` los vaya a buscar.

```bash
mkdir -p ~/Pictures/wallpapers/
git clone https://github.com/orangci/walls-catppuccin-mocha.git ~/Pictures/wallpapers/catppuccin-mocha
```

## 6. Recuperación de documentos locales con Vorta

Para restaurar la información personal documentada se va a usar Vorta, que ya se ha instalado mediante las listas de paquetes previas.
Se debe ejecutar `vorta` desde el menú de aplicaciones o la terminal. En la interfaz principal, dentro de la pestaña de configuración del repositorio, se selecciona la opción de **Añadir repositorio existente**. Tras apuntar a la ruta del disco de copia e introducir la contraseña de cifrado de Borg, se accede a la pestaña de "Archivos" (Archives) para montar el último respaldo y extraer directamente los documentos necesarios de vuelta en el disco duro.

## 7. Sincronización en la nube con Rclone

El último paso garantiza el enlace con la aplicación remota y los archivos críticos alojados en Google Drive.
Se ejecuta la configuración interactiva de la herramienta para registrar las credenciales de la cuenta de Google.

```bash
rclone config
```

Se debe seleccionar **"New remote"** (pulsando `n`), asignarle un nombre identificativo (por ejemplo, `gdrive_app`), seleccionar el tipo de almacenamiento `drive` en la lista que aparecerá, y seguir las instrucciones que se abrirán en el navegador web para otorgar los permisos.
Una vez autenticado, se puede sincronizar la carpeta remota hacia el almacenamiento local.

```bash
rclone sync "gdrive:Mi unidad/DriveSyncFiles/La Enciclopedia del Conocimiento Universal" ~/Documents/Obsidian
```

Las próximas veces se mantendrá la sincronización con el comando:

```bash
rclone bisync ~/Documents/Obsidian "gdrive:Mi unidad/DriveSyncFiles/La Enciclopedia del Conocimiento Universal" --verbose --conflict-resolve newer
```

## 8. Optimización de arranque

Vamos a desactivar configuraciones que vienen por defecto para desencriptar discos que nosotros no vamos a usar:
```bash
sudo systemctl mask systemd-tpm2-setup-early.service systemd-tpm2-setup.service systemd-pcrproduct.service
sudo systemctl mask systemd-pcrmachine.service systemd-pcrnvdone.service systemd-pcrphase-sysinit.service systemd-pcrphase.service
```