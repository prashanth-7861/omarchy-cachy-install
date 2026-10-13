# Omarchy on CachyOS

Install [Omarchy](https://omarchy.org/) (Hyprland + Quickshell bar + themes) on CachyOS, plus backup/restore and management tools.

## Quick Start

### Fresh CachyOS Install

```bash
git clone https://github.com/prashanth-7861/omarchy-cachy-install
cd omarchy-cachy-install
./install-omarchy-on-cachy.sh
# Reboot and select "Hyprland" at login
```

### Migrate from Existing Omarchy Setup

**On current machine:**
```bash
./capture-omarchy-config.sh
# Copies configs to ~/omarchy-backup-YYYYMMDD-HHMMSS/
```

**On new machine (after fresh install above):**
```bash
# Copy backup folder to new machine
./omarchy-backup-*/restore.sh
```

## Scripts

| Script | Purpose |
|--------|---------|
| `install-omarchy-on-cachy.sh` | Full Omarchy stack install on fresh CachyOS |
| `capture-omarchy-config.sh` | Backup current configs (hypr, omarchy, terminals, apps) |
| `uninstall-omarchy.sh` | Remove Omarchy packages & configs, restore previous DE |
| `health-check.sh` | Verify installation integrity |
| `theme-manager.sh` | Interactive theme/background switcher |
| `bar-customizer.sh` | Interactive Quickshell bar widget manager |

## What Gets Installed

### Core
- `omarchy`, `omarchy-settings`, `omarchy-nvim` - Omarchy meta-packages
- `hyprland`, `hyprland-guiutils` - Wayland compositor
- `quickshell` - Omarchy shell (bar, menus, notifications)
- `linux-omarchy` - Custom kernel (optional, via repo)

### Terminals
- `foot` (default), `kitty`, `alacritty`, `ghostty`

### Applications
- `nautilus` - File manager
- `btop` - System monitor
- `fastfetch` - System info
- `lazygit` - Git TUI
- `starship` - Shell prompt
- `fuzzel` - App launcher
- `mako` - Notifications
- `hyprpaper/hyprlock/hypridle` - Wallpaper/lock/idle

### Themes (20+ included)
tokyo-night, catppuccin, gruvbox, nord, kanagawa, rose-pine, everforest, and more

## Post-Install

```bash
# Pick a theme
omarchy theme switcher

# Customize bar
./bar-customizer.sh

# Manage themes
./theme-manager.sh

# Verify everything works
./health-check.sh

# View keybindings
cat KEYBINDINGS.md
```

## Config Locations

| Config | Location |
|--------|----------|
| Hyprland | `~/.config/hypr/` |
| Omarchy shell | `~/.config/omarchy/shell.json` |
| Themes | `~/.config/omarchy/themes/` (user) / `/usr/share/omarchy/themes/` (system) |
| Foot | `~/.config/foot/foot.ini` |
| Kitty | `~/.config/kitty/kitty.conf` |

## Omarchy Commands Cheatsheet

```bash
# Themes
omarchy theme list              # List themes
omarchy theme set <name>        # Apply theme
omarchy theme switcher          # Visual picker
omarchy theme bg-switcher       # Background picker

# Bar
omarchy bar move <widget>       # Move widget
omarchy bar add <widget>        # Add widget
omarchy restart shell           # Reload bar

# Config
omarchy refresh hyprland        # Reset Hyprland config
omarchy refresh shell           # Reset bar config
omarchy refresh config          # Reset all configs

# System
omarchy update                  # System update
omarchy debug --no-sudo --print # Diagnostics
omarchy version                 # Version info
```

## Uninstall

```bash
./uninstall-omarchy.sh
# Removes packages, backs up configs, restores SDDM
```

## Requirements

- CachyOS (or Arch-based) with base system installed
- Internet connection
- sudo privileges
- Not running as root

## License

MIT - Use freely