#!/usr/bin/env bash
# uninstall-omarchy.sh
# Remove Omarchy packages and configs from CachyOS

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
    
    # Remove Omarchy repo from pacman.conf
    if grep -q "\[omarchy\]" /etc/pacman.conf; then
        if confirm "Remove Omarchy repo from /etc/pacman.conf?"; then
            sudo sed -i '/^\[omarchy\]/,/^\[/ { /^\[omarchy\]/d; /^Server =/d; /^SigLevel =/d; /^$/d }' /etc/pacman.conf
            sudo pacman -Sy
            success "Omarchy repo removed"
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
    
    # Remove greetd if installed
    if systemctl is-enabled greetd >/dev/null 2>&1; then
        if confirm "Disable greetd and re-enable SDDM?"; then
            sudo systemctl disable --now greetd
            sudo systemctl enable --now sddm 2>/dev/null || warn "SDDM not installed"
            success "Display manager switched back to SDDM"
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
    echo "  2. Select your previous desktop (KDE/Plasma/GNOME) at login"
    echo ""
    echo "Configs backed up at: $BACKUP_DIR"
}

main "$@"