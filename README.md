# Entorno Hyprland & Nandoroid Shell - Dotfiles (Optimizado para Portátiles Táctiles)

Este repositorio contiene la configuración completa y modular de mi entorno de escritorio en Arch Linux, diseñado específicamente para ordenadores portátiles con soporte para pantallas táctiles. Ofrece una experiencia interactiva híbrida excelente inspirada en la estética moderna de Android 16 y Material 3. 

La interfaz principal es una versión personalizada y optimizada de **Nandoroid Shell**, impulsada por **Quickshell**, que se integra nativamente con gestos multitáctiles en pantalla, control dinámico de rotación física y esquemas de color dinámicos generados con **Matugen**.

---

## Utilidades Incluidas

Este entorno está compuesto por una cuidada selección de herramientas y utilidades para productividad, desarrollo y multimedia, optimizadas para el uso portátil y táctil:

1. **Hyprland**: Compositor Wayland dinámico tipo mosaico (tiling compositor) con animaciones fluidas y soporte completo para gestos multitáctiles en pantalla a través de `hyprgrass`.
2. **Quickshell**: Framework basado en QML que renderiza y gestiona la barra superior, paneles flotantes, menús y widgets con interacción táctil directa y reactiva.
3. **Nandoroid Shell**: Interfaz de usuario modificada basada en Material 3 y Android 16. Está optimizada para pantallas táctiles gracias a sus controles deslizables e interactivos (volumen, brillo, ajustes rápidos) de tipo móvil, junto con una **Isla Dinámica** (notificaciones, multimedia, pomodoro), un Dashboard completo (calendario, traductor, GitHub) y un **Selector de Fondos de Pantalla en formato Carrusel 3D (`SUPER + I`)** con soporte para Live Wallpapers de Steam Wallpaper Engine y filtros por categorías. *Incluye un sistema de transiciones dinámicas para fondos de pantalla y una pantalla de bloqueo avanzada con animaciones ("Kuru Kuru"), extracción de sujetos mediante IA, panel multimedia integrado y soporte para autenticación biométrica por huella dactilar.*
4. **Matugen**: Motor de generación de temas Material Design 3. Extrae automáticamente paletas armónicas de color del wallpaper seleccionado y las aplica en caliente a Hyprland, Kitty, VS Code y la shell.
5. **Kitty**: Emulador de terminal rápido y ligero acelerado por GPU con integración dinámica de colores de Matugen.
6. **Yazi**: Administrador de archivos en terminal extremadamente rápido escrito en Rust.
7. **Tauon Music Box**: Reproductor de música moderno y eficiente para gestionar y reproducir tu biblioteca local de canciones.
8. **NeoVim**: Editor de texto de terminal configurado con el tema Catppuccin Mocha.
9. **MPV**: Reproductor de video optimizado con soporte para escalado en tiempo real mediante Anime4K.
10. **Btop**: Monitor de sistema interactivo en terminal con paleta Catppuccin.
11. **Vorta & BorgBackup**: Interfaz y motor para copias de seguridad de datos locales seguras y cifradas.
12. **Rclone**: Herramienta de sincronización en la nube (utilizada para sincronizar el almacén de notas de Obsidian en Google Drive).
13. **Hypridle**: Gestor de inactividad de pantalla. (La pantalla de bloqueo moderna ahora es gestionada de forma nativa por el entorno QML).
14. **Impala & IWD**: Herramientas eficientes de terminal para conectar y administrar conexiones Wi-Fi de forma nativa.
15. **auto-cpufreq**: Optimizador de energía y regulador de la frecuencia de la CPU para maximizar la batería del portátil de manera automática.
16. **Widget de Rotación de Pantalla**: Utilidad integrada en el panel superior para cambiar la orientación de la pantalla, ideal para ordenadores convertibles o portátiles 2 en 1.
17. **Componentes Clásicos (Fallback)**: Rofi, SwayNC, Wlogout y Waybar están configurados y disponibles como sistemas alternativos de respaldo únicamente en caso de que ocurra algún fallo de carga con Quickshell.

---

## Guía de Instalación desde Cero

Sigue estos pasos ordenados para desplegar el entorno completo de forma segura en una instalación limpia de Arch Linux.

### 1. Conexión a Internet (Wi-Fi con IWD e Impala)
Instala las herramientas de red nativas para establecer la conexión Wi-Fi desde la TTY:
```bash
sudo pacman -S iwd impala
```
Edita la configuración de red con `sudo nvim /etc/iwd/main.conf` para activar la autoconfiguración DHCP:
```ini
[General]
EnableNetworkConfiguration=true
```
Habilita y arranca el demonio de red y la resolución DNS del sistema:
```bash
sudo systemctl enable --now systemd-resolved.service
sudo systemctl enable --now iwd.service
```
Por último, abre `impala` en tu terminal para buscar y conectarte a tu red Wi-Fi.

### 2. Entorno Base y Gestor de Paquetes AUR (Yay)
Asegura los paquetes esenciales de compilación y control del sistema base:
```bash
sudo pacman -S --needed git stow base-devel flatpak rclone
```
Clona y compila `yay` (o `paru`) para poder instalar aplicaciones del repositorio comunitario AUR:
```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay
```

### 3. Clonación del Repositorio de Dotfiles
Descarga esta configuración en la raíz de tu usuario para tener todas las utilidades listas:
```bash
git clone https://github.com/nicgil23/dotfiles.git ~/dotfiles
```

### 4. Restauración Automática de Paquetes
Con las listas guardadas en el repositorio, restaura toda la paquetería de forma automática:

* **Paquetes del repositorio de Arch**:
  ```bash
  sudo pacman -S --needed - < ~/dotfiles/lista_pacman.txt
  ```

* **Paquetes de AUR (comunitario)**:
  ```bash
  yay -S --needed - < ~/dotfiles/lista_aur.txt
  ```

* **Fuentes y Tipografías Estéticas**:
  Si no se instalaron en el paso de AUR, asegúrate de añadir las fuentes esenciales y actualizar la caché del sistema:
  ```bash
  yay -S ttf-jetbrains-mono-nerd catppuccin-gtk-theme-mocha ttf-apple-emoji apple-fonts
  sudo pacman -S noto-fonts-cjk
  fc-cache -fv
  ```

* **Aplicaciones Flatpak**:
  Añade el repositorio de Flathub e instala las aplicaciones aisladas de la lista:
  ```bash
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install $(cat ~/dotfiles/lista_flatpak.txt)
  ```

### 5. Despliegue de Configuraciones con Stow
Utiliza GNU Stow para crear enlaces simbólicos limpios desde la carpeta de dotfiles a tu directorio local sin mezclar archivos:
```bash
cd ~/dotfiles
stow hyprland
```
*Esto enlazará automáticamente todos los directorios de configuración bajo `.config` y el archivo de sesión `.zshrc` en el directorio de usuario.*

Para que Hyprland arranque automáticamente al iniciar sesión de terminal en la TTY1, añade esto a tu archivo `~/.bash_profile`:
```bash
[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
	start-hyprland
fi
```

### 6. Habilitación de Servicios del Sistema
Activa los demonios necesarios para el hardware, energía y sonido del entorno:
```bash
# Hardware y Redes
sudo systemctl enable --now auto-cpufreq
sudo systemctl enable --now iio-sensor-proxy
sudo systemctl enable --now bluetooth
sudo systemctl enable --now NetworkManager

# Servidor de Audio y Controladores
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

### 7. Configuración de Plugins de Hyprland (`hyprpm`)
Inicializa el gestor de módulos de Hyprland y añade soporte para gestos táctiles en pantalla:
```bash
hyprpm update
hyprpm add https://github.com/horriblename/hyprgrass
hyprpm enable hyprgrass
hyprpm reload
```
*(Si experimentas un error relacionado con `hyprgrass-pulse`, puedes desactivar ese subservicio ejecutando `hyprpm disable hyprgrass-pulse`)*

### 8. Fondos de Pantalla e Integración de Temas Dinámicos
Descarga el pack inicial de fondos de pantalla para que funcionen con la herramienta de selección:
```bash
mkdir -p ~/Pictures/wallpapers/
git clone https://github.com/orangci/walls-catppuccin-mocha.git ~/Pictures/wallpapers
```
*(Nota: El selector de wallpapers del entorno incluye un botón con un icono de corazón para establecer un fondo de pantalla aleatorio de entre tus favoritos).*

### 9. Sincronización en la Nube de Documentos (Rclone & Obsidian)
Configura tu conexión segura a Google Drive para sincronizar tu almacén de Obsidian:
```bash
rclone config
```
* Elige **"New remote"** (`n`), nómbralo `Obsidian` y selecciona `drive` en la lista. Sigue las instrucciones del navegador para dar permisos.
* Realiza la sincronización inicial de la carpeta remota a tu disco local:
  ```bash
  rclone sync "Obsidian:Mi unidad/DriveSyncFiles/La Enciclopedia del Conocimiento Universal" ~/Documents/Obsidian
  ```
* Automatiza o sincroniza en ambas direcciones en el futuro usando `bisync`:
  ```bash
  rclone bisync ~/Documents/Obsidian "Obsidian:Mi unidad/DriveSyncFiles/La Enciclopedia del Conocimiento Universal" --verbose --conflict-resolve newer
  ```

### 10. Optimizaciones de Arranque y Seguridad del Kernel
Para un arranque ultrarrápido y evitar fallos críticos al actualizar el sistema:

* Desactiva los servicios de configuración TPM si no los usas:
  ```bash
  sudo systemctl mask systemd-tpm2-setup-early.service systemd-tpm2-setup.service systemd-pcrproduct.service
  sudo systemctl mask systemd-pcrmachine.service systemd-pcrnvdone.service systemd-pcrphase-sysinit.service systemd-pcrphase.service
  ```

---

## Créditos y Coautores

Este proyecto ha sido desarrollado e integrado por **nicgil23**, y es posible gracias al trabajo extraordinario de los siguientes creadores de la comunidad cuyos proyectos han servido como base o inspiración:

* **na-ive**: Creador de [nandoroid-shell](https://github.com/na-ive/nandoroid-shell), la base sobre la cual se ha modificado y expandido la interfaz de usuario en Quickshell con su icónica Isla Dinámica.
* **Caelestia Shell (caelestia-dots)**: Inspiración fundamental para la integración de la tematización dinámica con Matugen, adoptada tras resolver los problemas de compatibilidad encontrados en la versión base de nandoroid-shell.
* **end-4**: Desarrollador de [dots-hyprland](https://github.com/end-4/dots-hyprland), cuya arquitectura del shell y lógica estética sirvieron de profunda inspiración estructural.
* **vaguesyntax (Vynx)**: Por las valiosas referencias de traducción y uso avanzado de Quickshell disponibles en su repositorio `ii-vynx`.
* **AvengeMedia**: Por la lógica de monitoreo del sistema heredada de `DankMaterialShell` y `dgop`.
* **Axenide**: Por el diseño y referencias espaciales del notch e isla dinámica en el proyecto `Ambxst`.
* **Zaphkiel**: Por la extraordinaria implementación de la pantalla de bloqueo animada ("Kuru Kuru"), la lógica para la pantalla de bloqueo con extracción de sujetos mediante IA, y el sistema avanzado de transiciones para fondos de pantalla, elementos que han sido portados y adaptados para este entorno.
* **ilyamiro**: Creador del diseño original y concepto del selector de fondos de pantalla en formato carrusel 3D ([serpantinum](https://github.com/ilyamiro/serpantinum)).

*Agradecimientos especiales también a los desarrolladores de **Quickshell**, **Hyprland**, **Matugen**, y la comunidad del tema **Catppuccin** por proveer herramientas de personalización de software libre excepcionales.*