#!/usr/bin/env bash
# uninstall-omarchy.sh
# Remove Omarchy packages and configs from CachyOS, restore Plasma/KDE

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }

confirm() {
    read -p "$1 [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

main() {
    log "Omarchy Uninstaller for CachyOS"
    echo ""
    
    if ! confirm "This will remove Omarchy packages and configs. Continue?"; then
        log "Aborted."
        exit 0
    fi
    
    # Remove packages
    log "Removing Omarchy packages..."
    OMARCHY_PACKAGES=(
        omarchy omarchy-settings omarchy-nvim omarchy-keyring
        quickshell
        hyprland hyprland-guiutils hyprland-preview-share-picker
        xdg-desktop-portal-hyprland
        hyprpaper hyprlock hypridle hyprsunset
        waybar mako fuzzel wl-clipboard grim slurp swappy swww
        sddm qt6-base  # installed by our script
    )
    
    INSTALLED=()
    for pkg in "${OMARCHY_PACKAGES[@]}"; do
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            INSTALLED+=("$pkg")
        fi
    done
    
    if [[ ${#INSTALLED[@]} -gt 0 ]]; then
        sudo pacman -Rns --noconfirm "${INSTALLED[@]}"
        success "Removed ${#INSTALLED[@]} packages"
    else
        log "No Omarchy packages found"
    fi
    
    # Remove Omarchy repo from pacman.conf (both old and new URLs)
    if grep -q "omarchy" /etc/pacman.conf; then
        if confirm "Remove Omarchy repo from /etc/pacman.conf?"; then
            sudo sed -i '/pkgs\.omarchy\.org/d' /etc/pacman.conf
            sudo sed -i '/packages\.omarchy\.org/d' /etc/pacman.conf
            sudo sed -i '/^\[omarchy\]/,/^\[/ { /^\[omarchy\]/d; /^Server =/d; /^SigLevel =/d; /^$/d }' /etc/pacman.conf
            sudo pacman -Sy
            success "Omarchy repo removed"
        fi
    fi
    
    # Remove Hyprland session
    if [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
        if confirm "Remove Hyprland session from SDDM?"; then
            sudo rm -f /usr/share/wayland-sessions/hyprland.desktop
            rm -f ~/.local/share/wayland-sessions/hyprland.desktop
            success "Hyprland session removed"
        fi
    fi
    
    # Remove SDDM config
    if [[ -f /etc/sddm.conf.d/hyprland.conf ]]; then
        if confirm "Remove SDDM Hyprland config?"; then
            sudo rm -f /etc/sddm.conf.d/hyprland.conf
            success "SDDM config removed"
        fi
    fi
    
    # Remove configs
    CONFIGS=(
        ~/.config/hypr
        ~/.config/omarchy
        ~/.config/foot
        ~/.config/kitty
        ~/.config/alacritty
        ~/.config/ghostty
        ~/.config/waybar
        ~/.config/mako
        ~/.config/fuzzel
        ~/.config/btop
        ~/.config/fastfetch
        ~/.config/lazygit
        ~/.config/starship.toml
        ~/.local/state/omarchy
        ~/.cache/omarchy
        ~/.local/share/wayland-sessions/hyprland.desktop
        ~/.config/environment.d/qt-wayland.conf
    )
    
    echo ""
    log "The following config directories will be backed up to ~/.omarchy-backup-$(date +%Y%m%d) before removal:"
    for c in "${CONFIGS[@]}"; do
        [[ -e $c ]] && echo "  $c"
    done
    
    if confirm "Backup and remove these configs?"; then
        BACKUP_DIR="$HOME/.omarchy-backup-$(date +%Y%m%d)"
        mkdir -p "$BACKUP_DIR"
        for c in "${CONFIGS[@]}"; do
            if [[ -e $c ]]; then
                cp -r "$c" "$BACKUP_DIR/" 2>/dev/null || true
                rm -rf "$c"
            fi
        done
        success "Configs backed up to $BACKUP_DIR and removed"
    fi
    
    # Restore Plasma/KDE if user wants
    if confirm "Reinstall Plasma/KDE desktop (recommended for CachyOS)?"; then
        log "Installing Plasma desktop..."
        sudo pacman -S --noconfirm --needed plasma-meta konsole dolphin kate firefox
        sudo systemctl enable --now sddm
        success "Plasma installed and SDDM enabled"
    else
        # Just ensure SDDM is enabled for any remaining DE
        if confirm "Enable SDDM for existing desktop?"; then
            sudo systemctl enable --now sddm 2>/dev/null || warn "SDDM not installed"
            success "SDDM enabled"
        fi
    fi
    
    # Unmask Plasma services
    sudo systemctl unmask plasma-polkit-agent 2>/dev/null || true
    sudo systemctl unmask plasma-powerdevil 2>/dev/null || true
    
    # Restore bash as default shell if zsh was set
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [[ "$current_shell" == *"zsh" ]]; then
        if confirm "Restore bash as default shell?"; then
            sudo chsh -s /bin/bash "$USER"
            success "Default shell restored to bash"
        fi
    fi
    
    # Clean orphan packages
    if confirm "Remove orphan packages?"; then
        ORPHANS=$(pacman -Qtdq 2>/dev/null || true)
        if [[ -n $ORPHANS ]]; then
            sudo pacman -Rns --noconfirm $ORPHANS
            success "Orphans removed"
        else
            log "No orphans found"
        fi
    fi
    
    echo ""
    success "Omarchy uninstall complete!"
    echo ""
    echo "To fully revert:"
    echo "  1. Reboot"
    echo "  2. Select Plasma/KDE at login screen"
    echo ""
    echo "Configs backed up at: $BACKUP_DIR"
}

main "$@"