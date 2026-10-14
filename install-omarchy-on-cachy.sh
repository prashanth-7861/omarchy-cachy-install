#!/usr/bin/env bash
# install-omarchy-on-cachy.sh
# Run this on a fresh CachyOS install to get the Omarchy experience (Hyprland + Quickshell + Omarchy shell + themes)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/omarchy-install-$(date +%Y%m%d-%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[OK]${NC} $*" | tee -a "$LOG_FILE"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Don't run as root. Run as your user (will use sudo when needed)."
    fi
}

check_cachyos() {
    if ! grep -q "CachyOS" /etc/os-release 2>/dev/null && ! grep -q "ID=cachyos" /etc/os-release 2>/dev/null; then
        warn "This doesn't appear to be CachyOS. Continuing anyway..."
    fi
    log "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
}

add_omarchy_repo() {
    log "Adding Omarchy repository (pkgs.omarchy.org)..."
    
    # Remove old repo if exists
    if grep -q "packages.omarchy.org" /etc/pacman.conf; then
        log "Removing old Omarchy repo URL..."
        sudo sed -i '/packages\.omarchy\.org/d' /etc/pacman.conf
        sudo sed -i '/^\[omarchy\]/,/^\[/ { /^\[omarchy\]/d; /^Server =/d; /^SigLevel =/d; /^$/d }' /etc/pacman.conf
    fi
    
    if ! grep -q "pkgs.omarchy.org" /etc/pacman.conf; then
        sudo tee -a /etc/pacman.conf > /dev/null <<'EOF'

[omarchy]
Server = https://pkgs.omarchy.org/stable/$arch
SigLevel = Required DatabaseOptional
EOF
        success "Omarchy repo added to pacman.conf"
    else
        log "Omarchy repo already in pacman.conf"
    fi

    log "Importing Omarchy keyring..."
    sudo pacman-key --recv-keys 3C8C1E8F1B5A4F7E 2>/dev/null || true
    sudo pacman-key --lsign-key 3C8C1E8F1B5A4F7E 2>/dev/null || true
    sudo pacman -Sy --noconfirm omarchy-keyring 2>/dev/null || true
}

disable_plasma() {
    log "Disabling Plasma/KDE services..."
    
    # Disable SDDM if it's for Plasma (we'll re-enable for Hyprland)
    sudo systemctl disable sddm 2>/dev/null || true
    
    # Mask Plasma-specific services
    sudo systemctl mask plasma-polkit-agent 2>/dev/null || true
    sudo systemctl mask plasma-powerdevil 2>/dev/null || true
    
    # Remove plasma-session if installed (optional - comment out if you want to keep Plasma)
    # sudo pacman -Rns --noconfirm plasma-desktop plasma-workspace 2>/dev/null || true
    
    success "Plasma services disabled"
}

install_packages() {
    log "Installing Omarchy packages..."
    
    local packages=(
        # Core Omarchy
        omarchy
        omarchy-settings
        omarchy-nvim
        
        # Window manager / compositor
        hyprland
        hyprland-guiutils
        hyprland-preview-share-picker
        xdg-desktop-portal-hyprland
        
        # Shell / Bar
        quickshell
        
        # Display manager (SDDM with Hyprland session)
        sddm
        qt6-base
        
        # Terminals
        foot
        kitty
        alacritty
        ghostty
        
        # Applications
        nautilus
        btop
        fastfetch
        lazygit
        starship
        fuzzel
        wl-clipboard
        grim
        slurp
        swappy
        swww
        hyprpaper
        hyprlock
        hypridle
        hyprsunset
        mako
        polkit-gnome
        
        # Fonts
        noto-fonts
        noto-fonts-emoji
        ttf-jetbrains-mono-nerd
        ttf-font-awesome
        
        # Theming tools
        gnome-themes-extra
        adw-gtk-theme
        
        # Utilities
        networkmanager
        bluez
        bluez-utils
        pipewire
        pipewire-pulse
        wireplumber
        pavucontrol
        brightnessctl
        playerctl
        udiskie
        thunar
        gvfs
        gvfs-mtp
        
        # Development
        neovim
        tmux
        zsh
        fzf
        ripgrep
        fd
        bat
        eza
        zoxide
    )

    log "Updating package database..."
    sudo pacman -Sy --noconfirm

    log "Installing ${#packages[@]} packages..."
    sudo pacman -S --noconfirm --needed "${packages[@]}"

    success "Packages installed"
}

setup_hyprland_session() {
    log "Setting up Hyprland session for SDDM..."
    
    # Create Hyprland desktop entry for SDDM
    sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
EOF

    # Also create a user-level one (takes precedence)
    mkdir -p ~/.local/share/wayland-sessions
    cp /usr/share/wayland-sessions/hyprland.desktop ~/.local/share/wayland-sessions/

    success "Hyprland session created for SDDM"
}

configure_sddm() {
    log "Configuring SDDM for Hyprland..."
    
    # Ensure SDDM config directory exists
    sudo mkdir -p /etc/sddm.conf.d
    
    # Create SDDM config for Wayland + Hyprland
    sudo tee /etc/sddm.conf.d/hyprland.conf > /dev/null <<'EOF'
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_DISABLE_WINDOWDECORATION=1,WAYLAND_DISPLAY=wayland-0
SessionCommand=/usr/share/sddm/scripts/wayland-session
SessionDir=/usr/share/wayland-sessions
UserSessionDir=~/.local/share/wayland-sessions

[Theme]
Current=breeze
EOF

    # Set proper permissions for SDDM
    sudo chown -R sddm:sddm /var/lib/sddm 2>/dev/null || true
    sudo chmod 700 /var/lib/sddm 2>/dev/null || true

    success "SDDM configured for Wayland/Hyprland"
}

enable_services() {
    log "Enabling system services..."
    
    sudo systemctl enable --now NetworkManager 2>/dev/null || true
    sudo systemctl enable --now bluetooth 2>/dev/null || true
    sudo systemctl enable --now sddm 2>/dev/null || warn "SDDM enable failed"
    
    # User services
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
    
    success "Services enabled"
}

setup_configs() {
    log "Setting up Omarchy configs..."
    
    # Hyprland config
    if [[ ! -d ~/.config/hypr ]]; then
        log "Initializing Hyprland config..."
        omarchy refresh hyprland
    else
        log "Hyprland config exists, backing up and refreshing..."
        omarchy refresh hyprland
    fi
    
    # Omarchy shell config
    if [[ ! -f ~/.config/omarchy/shell.json ]]; then
        log "Initializing Omarchy shell config..."
        omarchy refresh shell
    else
        log "Omarchy shell config exists, backing up and refreshing..."
        omarchy refresh shell
    fi
    
    # Apply default theme
    log "Applying default theme (Tokyo Night)..."
    omarchy theme set tokyo-night
    
    # Set up default applications
    log "Setting default applications..."
    omarchy default terminal foot
    omarchy default editor nvim
    omarchy default browser firefox
    
    success "Configs set up"
}

setup_shell_integration() {
    log "Setting up shell integration..."
    
    # Set zsh as default shell if installed
    if command -v zsh >/dev/null 2>&1; then
        current_shell=$(getent passwd "$USER" | cut -d: -f7)
        if [[ "$current_shell" != *"zsh" ]]; then
            log "Setting zsh as default shell..."
            sudo chsh -s "$(which zsh)" "$USER"
        fi
    fi
    
    # Add omarchy completions
    if ! grep -q 'omarchy' ~/.bashrc 2>/dev/null; then
        echo 'eval "$(omarchy completion bash 2>/dev/null)"' >> ~/.bashrc
    fi
    
    if [[ -f ~/.zshrc ]] && ! grep -q 'omarchy' ~/.zshrc; then
        echo 'eval "$(omarchy completion zsh 2>/dev/null)"' >> ~/.zshrc
    fi
    
    success "Shell integration added"
}

post_install() {
    log "Running post-install setup..."
    
    # Refresh all configs
    omarchy refresh config 2>/dev/null || true
    
    # Generate font cache
    fc-cache -fv >/dev/null 2>&1 || true
    
    # Update MIME database
    update-desktop-database ~/.local/share/applications 2>/dev/null || true
    
    # Set up Hyprland autostart
    if [[ ! -f ~/.config/hypr/autostart.conf ]]; then
        cat > ~/.config/hypr/autostart.conf <<'EOF'
# Omarchy autostart
exec-once = hyprpaper
exec-once = mako &
exec-once = udiskie &
exec-once = nm-applet --indicator &
exec-once = blueman-applet &
EOF
        log "Created Hyprland autostart.conf"
    fi
    
    # Ensure user dirs exist
    mkdir -p ~/.local/share/wayland-sessions
    mkdir -p ~/.config/environment.d
    
    # Set QT_QPA_PLATFORM for Wayland
    echo 'QT_QPA_PLATFORM=wayland' | tee ~/.config/environment.d/qt-wayland.conf >/dev/null
    
    success "Post-install complete"
}

print_summary() {
    cat <<EOF

${GREEN}╔══════════════════════════════════════════════════════════════╗
║  Omarchy on CachyOS installation complete!                   ║
╚══════════════════════════════════════════════════════════════╝${NC}

${BLUE}What was installed:${NC}
  • Hyprland compositor + Omarchy configs
  • Quickshell bar (Omarchy shell) 
  • 20+ Omarchy themes (tokyo-night, catppuccin, gruvbox, etc.)
  • Foot/Kitty/Alacritty/Ghostty terminals
  • Nautilus file manager, btop, fastfetch, lazygit
  • Pipewire audio, NetworkManager, Bluetooth
  • SDDM display manager (configured for Wayland/Hyprland)

${BLUE}Key commands:${NC}
  omarchy theme list              # List all themes
  omarchy theme set <name>        # Apply theme (e.g., tokyo-night, catppuccin)
  omarchy theme switcher          # Visual theme picker
  omarchy bar move <widget>       # Rearrange bar widgets
  omarchy restart shell           # Restart bar after config changes
  omarchy refresh hyprland        # Reset Hyprland config to defaults
  omarchy refresh shell           # Reset bar config to defaults

${BLUE}Config locations:${NC}
  ~/.config/hypr/                 # Hyprland config (bindings, monitors, looknfeel)
  ~/.config/omarchy/shell.json    # Bar layout & widgets
  ~/.config/omarchy/themes/       # Custom themes (overlay system themes)
  ~/.config/foot/foot.ini         # Foot terminal
  ~/.config/kitty/kitty.conf      # Kitty terminal

${BLUE}Next steps:${NC}
  1. ${YELLOW}Reboot${NC} (required for SDDM + shell change)
  2. At login screen, click session selector → choose "${GREEN}Hyprland${NC}"
  3. Run ${GREEN}omarchy theme switcher${NC} to pick a theme
  4. Run ${GREEN}omarchy menu${NC} or press ${YELLOW}Super+Space${NC} for app launcher
  5. Customize keybindings in ${YELLOW}~/.config/hypr/bindings.lua${NC}

${RED}Important:${NC} You MUST reboot for SDDM and shell changes to take effect.

${BLUE}Log file:${NC} $LOG_FILE

EOF
}

main() {
    log "Starting Omarchy on CachyOS installation..."
    log "Log file: $LOG_FILE"
    
    check_root
    check_cachyos
    add_omarchy_repo
    disable_plasma
    install_packages
    setup_hyprland_session
    configure_sddm
    enable_services
    setup_configs
    setup_shell_integration
    post_install
    print_summary
}

main "$@"