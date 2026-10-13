#!/usr/bin/env bash
# capture-omarchy-config.sh
# Run this on your CURRENT working Omarchy setup to capture all configs
# Then run restore-omarchy-config.sh on a fresh install

set -euo pipefail

BACKUP_DIR="${HOME}/omarchy-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

log() { echo -e "\033[0;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[0;32m[OK]\033[0m $*"; }

log "Capturing Omarchy config to $BACKUP_DIR"

# Hyprland configs
log "Backing up Hyprland config..."
cp -r ~/.config/hypr "$BACKUP_DIR/hypr"

# Omarchy configs
log "Backing up Omarchy config..."
cp -r ~/.config/omarchy "$BACKUP_DIR/omarchy"

# Terminal configs
for term in foot kitty alacritty ghostty; do
    if [[ -d ~/.config/$term ]]; then
        log "Backing up $term config..."
        cp -r ~/.config/$term "$BACKUP_DIR/$term"
    fi
done

# Shell configs
for shell in bash zsh fish; do
    if [[ -f ~/.$shell ]]; then
        cp ~/.$shell "$BACKUP_DIR/.$shell" 2>/dev/null || true
    fi
    if [[ -f ~/.$shell"rc" ]]; then
        cp ~/.$shell"rc" "$BACKUP_DIR/.$shell"rc 2>/dev/null || true
    fi
done

# Starship, btop, fastfetch, lazygit
for app in starship btop fastfetch lazygit; do
    if [[ -d ~/.config/$app ]]; then
        cp -r ~/.config/$app "$BACKUP_DIR/$app"
    elif [[ -f ~/.config/$app.* ]]; then
        mkdir -p "$BACKUP_DIR/$app"
        cp ~/.config/$app.* "$BACKUP_DIR/$app/"
    fi
done

# GTK/Qt themes
if [[ -d ~/.config/gtk-3.0 ]]; then cp -r ~/.config/gtk-3.0 "$BACKUP_DIR/"; fi
if [[ -d ~/.config/gtk-4.0 ]]; then cp -r ~/.config/gtk-4.0 "$BACKUP_DIR/"; fi

# Current theme info
omarchy theme current > "$BACKUP_DIR/current-theme.txt" 2>/dev/null || true
omarchy theme list > "$BACKUP_DIR/available-themes.txt" 2>/dev/null || true

# Installed packages
pacman -Qqe > "$BACKUP_DIR/explicit-packages.txt"
pacman -Qq | grep -E 'omarchy|hyprland|quickshell|waybar|foot|kitty|alacritty' > "$BACKUP_DIR/omarchy-packages.txt" 2>/dev/null || true

# Create restore script
cat > "$BACKUP_DIR/restore.sh" <<'RESTORE_EOF'
#!/usr/bin/env bash
# restore-omarchy-config.sh
# Run this on a fresh install AFTER running install-omarchy-on-cachy.sh

set -euo pipefail

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo -e "\033[0;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[0;32m[OK]\033[0m $*"; }

log "Restoring Omarchy config from $BACKUP_DIR"

# Restore Hyprland
if [[ -d "$BACKUP_DIR/hypr" ]]; then
    log "Restoring Hyprland config..."
    rm -rf ~/.config/hypr
    cp -r "$BACKUP_DIR/hypr" ~/.config/
fi

# Restore Omarchy
if [[ -d "$BACKUP_DIR/omarchy" ]]; then
    log "Restoring Omarchy config..."
    rm -rf ~/.config/omarchy
    cp -r "$BACKUP_DIR/omarchy" ~/.config/
fi

# Restore terminals
for term in foot kitty alacritty ghostty; do
    if [[ -d "$BACKUP_DIR/$term" ]]; then
        log "Restoring $term config..."
        rm -rf ~/.config/$term
        cp -r "$BACKUP_DIR/$term" ~/.config/
    fi
done

# Restore other apps
for app in starship btop fastfetch lazygit; do
    if [[ -d "$BACKUP_DIR/$app" ]]; then
        log "Restoring $app config..."
        rm -rf ~/.config/$app
        cp -r "$BACKUP_DIR/$app" ~/.config/
    fi
done

# Restore GTK
for gtk in gtk-3.0 gtk-4.0; do
    if [[ -d "$BACKUP_DIR/$gtk" ]]; then
        log "Restoring $gtk config..."
        rm -rf ~/.config/$gtk
        cp -r "$BACKUP_DIR/$gtk" ~/.config/
    fi
done

# Restore shell configs
for file in .bashrc .zshrc .config/fish/config.fish; do
    if [[ -f "$BACKUP_DIR/$file" ]]; then
        log "Restoring $file..."
        cp "$BACKUP_DIR/$file" ~/
    fi
done

# Apply saved theme
if [[ -f "$BACKUP_DIR/current-theme.txt" ]]; then
    THEME=$(cat "$BACKUP_DIR/current-theme.txt")
    log "Applying theme: $THEME"
    omarchy theme set "$THEME" 2>/dev/null || warn "Theme apply failed, run manually: omarchy theme set $THEME"
fi

# Reload Hyprland
log "Reloading Hyprland..."
hyprctl reload 2>/dev/null || true

# Restart shell
log "Restarting Omarchy shell..."
omarchy restart shell 2>/dev/null || true

success "Config restored! Re-login to apply all changes."
RESTORE_EOF

chmod +x "$BACKUP_DIR/restore.sh"

# Create a summary
cat > "$BACKUP_DIR/README.md" <<EOF
# Omarchy Config Backup
Created: $(date)
Host: $(hostname)
User: $USER

## Contents
- \`hypr/\` - Hyprland window manager config
- \`omarchy/\` - Omarchy shell (bar, themes, plugins)
- \`foot/\`, \`kitty/\`, etc. - Terminal configs
- \`starship/\`, \`btop/\`, etc. - App configs
- \`current-theme.txt\` - Active theme name
- \`omarchy-packages.txt\` - Key packages installed

## Restore on fresh install
1. Run \`install-omarchy-on-cachy.sh\` first (installs packages)
2. Run \`./restore.sh\` from this directory
3. Re-login
EOF

success "Backup complete at $BACKUP_DIR"
echo ""
echo "To restore on a fresh install:"
echo "  1. Run install-omarchy-on-cachy.sh"
echo "  2. Copy this backup folder to the new machine"
echo "  3. Run $BACKUP_DIR/restore.sh"