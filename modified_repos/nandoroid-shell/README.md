# NAnDoroid-shell-moded

A high-performance, Quickshell-based desktop shell for Hyprland, adopting Android 16 design elements and Material 3 aesthetics.

> **Note**: This shell and its dependencies are designed strictly for **Arch Linux based distributions** (Arch, CachyOS, EndeavourOS, etc.).

**Version:** v1.0
**License:** AGPL-3.0

---

## Architecture & Design Philosophy

NAnDoroid-shell is built on a modular, service-oriented architecture using **Quickshell** (C++ engine) and **QML** (UI declaration). It follows a strict separation between UI panels, backend services, and core system utilities.

### Core Directory Structure

- **`shell.qml`**: The entry point. Root of the shell environment, managing global shortcuts, IPC handlers, and component lifecycle.
- **`core/`**: The backbone of the shell.
    - `Config.qml`: Centralized JSON-backed configuration system.
    - `GlobalStates.qml`: Shared reactive state for panel visibility and UI interactions.
    - `Appearance.qml`: The Material 3 design system, handling scaling, colors, and animations.
    - `Directories.qml`: Path management for shell assets and configs.
- **`services/`**: The "Brain" of the shell. Independent singletons handling system logic (Network, Audio, Bluetooth, VPN, Power, etc.).
- **`panels/`**: Large UI components (Quick Settings, Status Bar, Launcher, etc.).
- **`widgets/`**: Reusable micro-components (Buttons, Sliders, Text elements) that ensure a consistent look and feel.
- **`scripts/`**: Helper scripts for complex system operations (Color generation, System restarts, Music recognition).

---

## Key Features

### Universal Dynamic Island
A centralized "Notch" system that intelligently adapts to your workflow:
- **Media Playback**: Rich album art, playback controls, and progress indicators.
- **Workspace Switching**: Visual feedback for Hyprland workspace transitions.
- **System Indicators**: Real-time status for Recording, Pomodoro, and VPN.
- **Unified Notifications**: Android-style popups that elegantly slide out from the notch.

### Interactive Quick Settings Center
A fully customizable, authenticated control center:
- **Edit Mode**: Long-press or click the edit icon to resize (square icon or expanded tile) and reorder toggles.
- **Service Integration**: Instant access to Wi-Fi, Bluetooth, VPN (WARP & UCM), EasyEffects, and Battery Conservation.
- **Advanced Controls**: Integrated sliders for brightness (DDC/Internal), volume, and microphone levels.
- **Self-Repair**: Includes a "Restart Shell" toggle for development and troubleshooting.

### Spotlight & Search Ecosystem
An intelligent, integrated search bar powered by a robust search registry:
- **App Launcher**: Instant application fuzzy search with usage tracking.
- **Advanced Providers**: Clipboard History (`cliphist`), Emoji Picker, and File Search (`fd`).
- **Web & Tools**: Quick prefixes for web searches (`!`), tools (`.`), and commands (`>`).

### Material 3 Design System
- **Dynamic Theming**: Entire shell colors are generated from your wallpaper using `matugen`.
- **Intelligent Accessibility**: Status bar and lockscreen text colors automatically adapt to wallpaper lightness (Native `magick` processing).
- **Responsive Scaling**: UI elements scale proportionally based on your monitor resolution and `effectiveScale` logic.

---

## Service Layer (The Backend)

NAnDoroid-shell abstracts system complexity into easy-to-use QML singletons:

| Service | Driver / Utility | Description |
| :--- | :--- | :--- |
| **Network** | `nmcli` / `warp-cli` | Manages Wi-Fi, Ethernet, and Cloudflare WARP status. |
| **VPN UCM** | `openconnect` | Specialized GlobalProtect integration with real-time process tracking. |
| **Audio** | `wpctl` | High-level control for volume, muting, and device switching. |
| **PowerProfile** | `auto-cpufreq` | Enforces hardware-aware performance profiles (Daily, Balanced, Performance). |
| **Conservation** | Native `/sys/` | Manages Battery Conservation mode for Lenovo hardware. |
| **EasyEffects** | `easyeffects` | System-wide audio enhancement toggle. |
| **Wallpaper** | `matugen` / `swww` | Coordinates wallpaper changes and theme reapplications. |
| **SongRec** | `songrec` | Background music recognition service using monitor/mic input. |
| **SystemData** | Native `/proc/` | Lightweight CPU/RAM monitoring without external overhead. |

---

## Requirements & Dependencies

<details>
<summary>Click to view full dependency list</summary>

### Core System
- `hyprland`: The compositor host.
- `quickshell`: The shell engine (0.5.0+).
- `matugen`: Material 3 theme generation.
- `python3`, `jq`: Core scripting and configuration.

### Functional Utilities
- **Audio/Media**: `pipewire`, `wireplumber`, `playerctl`, `easyeffects`, `songrec`, `cava`.
- **System**: `brightnessctl`, `ddcutil`, `auto-cpufreq`, `systemd`.
- **Networking**: `networkmanager`, `bluez`, `warp-cli`, `openconnect`, `gp-saml-gui`.
- **Search**: `fd`, `cliphist`, `zbar`, `tesseract`.
- **Visuals**: `imagemagick`, `hyprpicker`, `hyprsunset`, `hyprlock`.
- **Capture**: `grim`, `slurp`, `wf-recorder`.

### Recommended Fonts
- `Material Symbols Rounded`: Iconography.
- `JetBrains Mono Nerd Font`: Monospace elements.

</details>

---

## Credits & Acknowledgements

- **[Quickshell](https://github.com/outfoxxed)**: The foundational framework.
- **[end-4](https://github.com/end-4)**: Architecture inspiration from [dots-hyprland](https://github.com/end-4/dots-hyprland).
- **[Axenide](https://github.com/Axenide)**: Notch and Dynamic Island concepts from [Ambxst](https://github.com/Axenide/Ambxst).
- **[AvengeMedia](https://github.com/AvengeMedia)**: System monitoring logic.
- **[na-ive](https://github.com/na-ive)**: Special thanks for the original creator of this shell. I only modified it for my personal use.