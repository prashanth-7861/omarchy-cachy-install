#!/usr/bin/env bash
# install-omarchy-theme.sh
# Install Omarchy-style theming, keybindings, and bar on CachyOS (minimal, no branding)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/omarchy-theme-install-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; exit 1; }
success() { echo -e "${GREEN}[OK]${NC} $*" | tee -a "$LOG_FILE"; }

check_root() {
    [[ $EUID -eq 0 ]] && error "Don't run as root. Run as your user."
}

add_omarchy_repo() {
    log "Adding Omarchy repository for themes/packages..."
    
    # Remove old repo URLs
    sudo sed -i '/packages\.omarchy\.org/d' /etc/pacman.conf
    sudo sed -i '/pkgs\.omarchy\.org/d' /etc/pacman.conf
    sudo sed -i '/^\[omarchy\]/,/^\[/ { /^\[omarchy\]/d; /^Server =/d; /^SigLevel =/d; /^$/d }' /etc/pacman.conf
    
    # Add correct repo
    sudo tee -a /etc/pacman.conf > /dev/null <<'EOF'

[omarchy]
Server = https://pkgs.omarchy.org/stable/$arch
SigLevel = Required DatabaseOptional
EOF

    sudo pacman-key --recv-keys 3C8C1E8F1B5A4F7E 2>/dev/null || true
    sudo pacman-key --lsign-key 3C8C1E8F1B5A4F7E 2>/dev/null || true
    sudo pacman -Sy --noconfirm omarchy-keyring 2>/dev/null || true
    success "Omarchy repo added"
}

install_core_packages() {
    log "Installing core packages (Hyprland, Quickshell, themes)..."
    
    local packages=(
        # Core
        hyprland
        hyprland-guiutils
        xdg-desktop-portal-hyprland
        quickshell
        
        # Omarchy themes & settings (theming only, no branding)
        omarchy-settings
        
        # Terminal
        foot
        
        # Bar dependencies
        mako
        wl-clipboard
        grim
        slurp
        swww
        hyprpaper
        hyprlock
        hypridle
        
        # Fonts
        noto-fonts
        noto-fonts-emoji
        ttf-jetbrains-mono-nerd
        ttf-font-awesome
        
        # Utils
        fuzzel
        starship
        btop
        fastfetch
        pavucontrol
        brightnessctl
        playerctl
        udiskie
    )
    
    sudo pacman -Sy --noconfirm
    sudo pacman -S --noconfirm --needed "${packages[@]}"
    success "Core packages installed"
}

setup_hyprland_config() {
    log "Setting up Hyprland config with Omarchy-style keybindings..."
    
    # Backup existing
    [[ -d ~/.config/hypr ]] && mv ~/.config/hypr ~/.config/hypr.backup.$(date +%s)
    
    mkdir -p ~/.config/hypr
    
    # hyprland.conf - main config
    cat > ~/.config/hypr/hyprland.conf <<'EOF'
# Omarchy-style Hyprland config (minimal, no branding)
source = ~/.config/hypr/keybindings.conf
source = ~/.config/hypr/monitors.conf
source = ~/.config/hypr/input.conf
source = ~/.config/hypr/looknfeel.conf
source = ~/.config/hypr/autostart.conf
source = ~/.config/hypr/windowrules.conf
EOF

    # keybindings.conf - Omarchy-style keybindings
    cat > ~/.config/hypr/keybindings.conf <<'EOF'
# Omarchy-style keybindings (Super = Mod4)
$mainMod = SUPER

# Terminal
bind = $mainMod, Return, exec, foot
bind = $mainMod SHIFT, Return, exec, kitty

# App launcher
bind = $mainMod, Space, exec, fuzzel
bind = $mainMod SHIFT, Space, exec, ~/.config/omarchy/launchers/omarchy-menu.sh

# File manager
bind = $mainMod, E, exec, thunar
bind = $mainMod SHIFT, E, exec, nautilus

# Browser
bind = $mainMod, B, exec, firefox
bind = $mainMod SHIFT, B, exec, firefox --private-window

# Close/kill
bind = $mainMod, Q, killactive,
bind = $mainMod SHIFT, Q, killactive, force

# Fullscreen
bind = $mainMod, F, fullscreen
bind = $mainMod SHIFT, F, fullscreen, 1

# Floating
bind = $mainMod, V, togglefloating
bind = $mainMod SHIFT, V, togglefloating, all

# Pseudo-tile
bind = $mainMod, P, pseudo

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod, h, movefocus, l
bind = $mainMod, j, movefocus, d
bind = $mainMod, k, movefocus, u
bind = $mainMod, l, movefocus, r

# Move windows
bind = $mainMod SHIFT, left, movewindow, l
bind = $mainMod SHIFT, right, movewindow, r
bind = $mainMod SHIFT, up, movewindow, u
bind = $mainMod SHIFT, down, movewindow, d

bind = $mainMod SHIFT, h, movewindow, l
bind = $mainMod SHIFT, j, movewindow, d
bind = $mainMod SHIFT, k, movewindow, u
bind = $mainMod SHIFT, l, movewindow, r

# Resize
bind = $mainMod CTRL, left, resizeactive, -20 0
bind = $mainMod CTRL, right, resizeactive, 20 0
bind = $mainMod CTRL, up, resizeactive, 0 -20
bind = $mainMod CTRL, down, resizeactive, 0 20

bind = $mainMod CTRL, h, resizeactive, -20 0
bind = $mainMod CTRL, l, resizeactive, 20 0
bind = $mainMod CTRL, k, resizeactive, 0 -20
bind = $mainMod CTRL, j, resizeactive, 0 20

# Swap windows
bind = $mainMod ALT, left, swapwindow, l
bind = $mainMod ALT, right, swapwindow, r
bind = $mainMod ALT, up, swapwindow, u
bind = $mainMod ALT, down, swapwindow, d

# Special workspace (scratchpad)
bind = $mainMod, S, togglespecialworkspace, magic
bind = $mainMod SHIFT, S, movetoworkspace, special:magic

# Screenshot
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy
bind = $mainMod, Print, exec, grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png
bind = $mainMod SHIFT, Print, exec, grim ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png

# Lock/Logout
bind = $mainMod, L, exec, hyprlock
bind = $mainMod SHIFT, L, exit
bind = $mainMod CTRL, L, exec, systemctl suspend

# Reload
bind = $mainMod SHIFT, R, reload
bind = $mainMod CTRL, R, exec, omarchy restart shell

# Audio
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Brightness
bind = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Media
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Theme switcher
bind = $mainMod ALT, T, exec, omarchy theme switcher
bind = $mainMod ALT, B, exec, omarchy theme bg-switcher

# Power menu
bind = $mainMod, Escape, exec, ~/.config/omarchy/launchers/power-menu.sh

# Calculator
bind = $mainMod, C, exec, foot -e python3 -c "import sys; print(eval(sys.stdin.read()))"
EOF

    # monitors.conf
    cat > ~/.config/hypr/monitors.conf <<'EOF'
# Monitor config - auto-configure
monitor = ,preferred,auto,auto
monitor = ,highrr,auto,auto

# Laptop lid
switch_xkb_layout_on_lid_close = false
EOF

    # input.conf
    cat > ~/.config/hypr/input.conf <<'EOF'
input {
    kb_layout = us
    kb_variant = 
    kb_model = 
    kb_options = caps:escape
    kb_rules = 
    follow_mouse = 1
    touchpad {
        natural_scroll = true
        tap-to-click = true
        drag_lock = true
        disable_while_typing = true
    }
    sensitivity = 0
    accel_profile = flat
}
EOF

    # looknfeel.conf - Omarchy-style appearance
    cat > ~/.config/hypr/looknfeel.conf <<'EOF'
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(89b4faee) rgba(74c7ecee) 45deg
    col.inactive_border = rgba(313244ee)
    layout = dwindle
    allow_tearing = false
    animate_manual_resizes = true
}

decoration {
    rounding = 8
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
    }
    drop_shadow = true
    shadow_range = 10
    shadow_render_power = 3
    col.shadow = rgba(1a1b26cc)
}

animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_is_master = true
    new_on_top = true
}
EOF

    # autostart.conf
    cat > ~/.config/hypr/autostart.conf <<'EOF'
# Autostart applications
exec-once = hyprpaper
exec-once = swww-daemon
exec-once = mako
exec-once = udiskie
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = systemctl --user start pipewire wireplumber
EOF

    # windowrules.conf
    cat > ~/.config/hypr/windowrules.conf <<'EOF'
# Window rules
windowrulev2 = float, class:^(pavucontrol|blueman-manager|nm-connection-editor)$
windowrulev2 = float, title:^(Calculator|File Operation Progress)$
windowrulev2 = size 800 600, class:^(pavucontrol|blueman-manager)$
windowrulev2 = center, class:^(pavucontrol|blueman-manager)$
windowrulev2 = opacity 0.95 0.95, class:.*
windowrulev2 = nomaximize, class:^(pavucontrol)$
EOF

    success "Hyprland config created"
}

setup_quickshell_bar() {
    log "Setting up Quickshell bar (Omarchy-style)..."
    
    mkdir -p ~/.config/quickshell
    
    # QuickShell config - minimal bar
    cat > ~/.config/quickshell/config.jsonc <<'EOF'
{
  "windows": [
    {
      "name": "bar",
      "layer": "top",
      "anchor": ["left", "right", "top"],
      "exclusivity": "exclusive",
      "monitor": 0,
      "child": {
        "widget": "box",
        "css": "min-height: 36px; padding: 0 12px; background: rgba(26, 27, 38, 0.9);",
        "children": [
          // Left: Workspaces
          {
            "widget": "box",
            "halign": "start",
            "spacing": 4,
            "children": [
              { "widget": "workspaces", "id": "workspaces", "format": "{name}", "onClick": "workspace" }
            ]
          },
          // Center: Window title / clock
          {
            "widget": "box",
            "halign": "center",
            "spacing": 12,
            "children": [
              { "widget": "label", "id": "clock", "text": "00:00", "poll": 1000, "script": "date '+%H:%M'" },
              { "widget": "label", "id": "date", "text": "", "poll": 60000, "script": "date '+%a %d %b'" }
            ]
          },
          // Right: System tray + status
          {
            "widget": "box",
            "halign": "end",
            "spacing": 8,
            "children": [
              { "widget": "systray", "id": "systray", "iconSize": 16 },
              { "widget": "label", "id": "battery", "text": "🔋 100%", "poll": 30000, "script": "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 | xargs -I{} echo '🔋 {}%'" },
              { "widget": "label", "id": "volume", "text": "🔊 100%", "poll": 1000, "script": "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)\"%\"}'" },
              { "widget": "label", "id": "network", "text": "📶", "poll": 10000, "script": "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 | head -1 | xargs -I{} echo '📶 {}' || echo '📶'" }
            ]
          }
        ]
      }
    }
  ]
}
EOF

    success "Quickshell bar config created"
}

setup_omarchy_themes() {
    log "Setting up Omarchy themes..."
    
    # Apply a theme
    omarchy theme set tokyo-night 2>/dev/null || warn "Theme apply failed, run manually later"
    
    # Create theme symlink for quickshell to pick up colors
    mkdir -p ~/.config/quickshell/themes
    ln -sf ~/.local/state/omarchy/current/theme ~/.config/quickshell/themes/current 2>/dev/null || true
    
    success "Themes configured"
}

setup_launchers() {
    log "Setting up launchers and menus..."
    
    mkdir -p ~/.config/omarchy/launchers
    
    # Power menu
    cat > ~/.config/omarchy/launchers/power-menu.sh <<'EOF'
#!/usr/bin/env bash
options="🔒 Lock\n🚪 Logout\n🔄 Reboot\n⏻ Shutdown\n💤 Suspend"
choice=$(echo -e "$options" | fuzzel --dmenu --prompt "Power: " --width 20 --lines 6)
case $choice in
    *Lock*) hyprlock ;;
    *Logout*) hyprctl dispatch exit ;;
    *Reboot*) systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
    *Suspend*) systemctl suspend ;;
esac
EOF
    chmod +x ~/.config/omarchy/launchers/power-menu.sh
    
    # Simple app menu (uses fuzzel)
    cat > ~/.config/omarchy/launchers/omarchy-menu.sh <<'EOF'
#!/usr/bin/env bash
# Simple app launcher with fuzzel
fuzzel --dmenu --prompt "Run: " --width 50 --lines 15
EOF
    chmod +x ~/.config/omarchy/launchers/omarchy-menu.sh
    
    success "Launchers created"
}

setup_shell() {
    log "Setting up shell (starship, zsh)..."
    
    # Starship config (minimal, Tokyo Night style)
    cat > ~/.config/starship.toml <<'EOF'
format = """$username$hostname$directory$git_branch$git_status$character"""

[username]
style_user = "bold #89b4fa"
style_root = "bold #f38ba8"
format = "[$user]($style) "
show_always = true

[hostname]
ssh_only = false
format = " @ [$hostname](bold #fab387) "
trim_at = ".local"

[directory]
style = "bold #cba6f7"
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = " "
style = "bold #f9e2af"
format = "[$symbol$branch](bold #f9e2af) "

[git_status]
style = "bold #f38ba8"
conflicted = "="
ahead = "↑"
behind = "↓"
staged = "+"
modified = "!"
untracked = "?"
stashed = "$"

[character]
success_symbol = "[❯](bold #a6e3a1)"
error_symbol = "[❯](bold #f38ba8)"
vicmd_symbol = "[❮](bold #fab387)"
EOF

    # .zshrc additions
    if [[ -f ~/.zshrc ]]; then
        grep -q "omarchy" ~/.zshrc || cat >> ~/.zshrc <<'EOF'

# Omarchy-style aliases
alias ls='eza --icons'
alias ll='eza -la --icons'
alias lt='eza --tree --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias top='btop'

# Starship
eval "$(starship init zsh)"

# Zoxide
eval "$(zoxide init zsh)"

# FZF
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
EOF
    fi
    
    # .bashrc additions
    if [[ -f ~/.bashrc ]]; then
        grep -q "omarchy" ~/.bashrc || cat >> ~/.bashrc <<'EOF'

# Omarchy-style aliases
alias ls='eza --icons'
alias ll='eza -la --icons'
alias lt='eza --tree --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias top='btop'

# Starship
eval "$(starship init bash)"

# Zoxide
eval "$(zoxide init bash)"
EOF
    fi
    
    success "Shell configured"
}

enable_user_services() {
    log "Enabling user services..."
    
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
    systemctl --user enable --now hypridle 2>/dev/null || true
    
    success "User services enabled"
}

print_summary() {
    cat <<EOF

${GREEN}╔══════════════════════════════════════════════════════════════╗
║  Omarchy-style theme/keybindings/bar installed!              ║
╚══════════════════════════════════════════════════════════════╝${NC}

${BLUE}What was installed:${NC}
  • Hyprland with Omarchy-style keybindings
  • Quickshell bar (top, minimal)
  • Omarchy themes (tokyo-night, catppuccin, gruvbox, etc.)
  • Foot terminal, fuzzel launcher, mako notifications
  • Starship prompt, zsh/bash aliases

${BLUE}Keybindings (Super = Win key):${NC}
  Super+Return     Terminal (foot)
  Super+Space      App launcher (fuzzel)
  Super+E          File manager (thunar)
  Super+B          Browser (firefox)
  Super+Q          Close window
  Super+F          Fullscreen
  Super+V          Toggle float
  Super+1-9        Workspace 1-9
  Super+Shift+1-9  Move to workspace
  Super+H/J/K/L    Focus windows
  Super+Shift+H/J/K/L  Move windows
  Super+Ctrl+H/J/K/L   Resize windows
  Super+L          Lock (hyprlock)
  Super+Shift+L    Logout
  Super+Print      Screenshot region
  Super+Alt+T      Theme switcher
  Super+Alt+B      Background switcher
  Super+Escape     Power menu

${BLUE}Theme commands:${NC}
  omarchy theme list              # List themes
  omarchy theme set <name>        # Apply theme
  omarchy theme switcher          # Visual picker
  omarchy theme bg-switcher       # Background picker

${BLUE}Config locations:${NC}
  ~/.config/hypr/                 # Hyprland (keybindings, looknfeel, etc.)
  ~/.config/quickshell/           # Bar config
  ~/.config/omarchy/launchers/    # Power menu, app menu
  ~/.config/starship.toml         # Prompt

${YELLOW}Next:${NC} Log out and select "Hyprland" at SDDM, or run: Hyprland

${BLUE}Log:${NC} $LOG_FILE
EOF
}

main() {
    log "Installing Omarchy-style theme/keybindings/bar on CachyOS..."
    log "Log: $LOG_FILE"
    
    check_root
    add_omarchy_repo
    install_core_packages
    setup_hyprland_config
    setup_quickshell_bar
    setup_omarchy_themes
    setup_launchers
    setup_shell
    enable_user_services
    print_summary
}

main "$@"