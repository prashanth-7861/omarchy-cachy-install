#!/usr/bin/env bash
# health-check.sh
# Verify Omarchy installation is working correctly

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check() {
    local name="$1"
    local cmd="$2"
    local fix="$3"
    
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $name"
        [[ -n $fix ]] && echo -e "  ${YELLOW}Fix:${NC} $fix"
        ((FAIL++))
    fi
}

warn_check() {
    local name="$1"
    local cmd="$2"
    local msg="$3"
    
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASS++))
    else
        echo -e "${YELLOW}⚠${NC} $name - $msg"
        ((WARN++))
    fi
}

echo -e "${BLUE}╔══════════════════════════════════════════╗"
echo -e "║     Omarchy Health Check                 ║"
echo -e "╚══════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}── Core Packages ──${NC}"
check "omarchy installed" "pacman -Q omarchy" "Run install script"
check "omarchy-settings installed" "pacman -Q omarchy-settings" "sudo pacman -S omarchy-settings"
check "hyprland installed" "pacman -Q hyprland" "sudo pacman -S hyprland"
check "quickshell installed" "pacman -Q quickshell" "sudo pacman -S quickshell"
check "omarchy-keyring installed" "pacman -Q omarchy-keyring" "sudo pacman -S omarchy-keyring"

echo ""
echo -e "${BLUE}── Omarchy Repo ──${NC}"
check "omarchy repo in pacman.conf" "grep -q '\[omarchy\]' /etc/pacman.conf" "Add repo to /etc/pacman.conf"
check "omarchy packages accessible" "pacman -Sl omarchy | head -1" "sudo pacman -Sy"

echo ""
echo -e "${BLUE}── Config Files ──${NC}"
check "Hyprland config exists" "[[ -d ~/.config/hypr ]]" "Run: omarchy refresh hyprland"
check "Omarchy shell config exists" "[[ -f ~/.config/omarchy/shell.json ]]" "Run: omarchy refresh shell"
check "Current theme set" "omarchy theme current | grep -q ." "Run: omarchy theme set tokyo-night"

echo ""
echo -e "${BLUE}── Running Services ──${NC}"
if [[ $XDG_SESSION_TYPE == "wayland" ]] && [[ $XDG_CURRENT_DESKTOP == "Hyprland" ]]; then
    check "Running on Hyprland" "true"
else
    warn_check "Running on Hyprland" "false" "Log into Hyprland session to verify fully"
fi

check "Quickshell running" "pgrep -x quickshell >/dev/null" "Run: omarchy restart shell"
check "Hyprland responding" "hyprctl version >/dev/null" "Restart Hyprland"

echo ""
echo -e "${BLUE}── Theme System ──${NC}"
check "Theme directory accessible" "[[ -d /usr/share/omarchy/themes ]]" "Reinstall omarchy-settings"
check "User themes dir exists" "[[ -d ~/.config/omarchy/themes ]]" "mkdir -p ~/.config/omarchy/themes"
check "Backgrounds dir exists" "[[ -d ~/.config/omarchy/backgrounds ]]" "mkdir -p ~/.config/omarchy/backgrounds"

CURRENT_THEME=$(omarchy theme current 2>/dev/null || echo "")
if [[ -n $CURRENT_THEME ]]; then
    check "Theme applied: $CURRENT_THEME" "[[ -d ~/.local/state/omarchy/current/theme ]]"
else
    warn_check "No theme applied" "false" "Run: omarchy theme set tokyo-night"
fi

echo ""
echo -e "${BLUE}── Terminal Emulators ──${NC}"
for term in foot kitty alacritty ghostty; do
    if pacman -Q "$term" >/dev/null 2>&1; then
        check "$term installed" "true"
        if [[ -f ~/.config/$term/${term}.conf || -f ~/.config/$term/${term}.toml || -f ~/.config/$term/${term}.ini ]]; then
            check "$term config exists" "true"
        else
            warn_check "$term config missing" "false" "Run: omarchy refresh config"
        fi
    fi
done

echo ""
echo -e "${BLUE}── Display Manager ──${NC}"
if systemctl is-enabled greetd >/dev/null 2>&1; then
    check "greetd enabled" "true"
elif systemctl is-enabled sddm >/dev/null 2>&1; then
    check "SDDM enabled" "true"
else
    warn_check "No display manager enabled" "false" "sudo systemctl enable sddm"
fi

echo ""
echo -e "${BLUE}── System Services ──${NC}"
check "NetworkManager active" "systemctl is-active NetworkManager" "sudo systemctl enable --now NetworkManager"
check "Bluetooth active" "systemctl is-active bluetooth" "sudo systemctl enable --now bluetooth"
check "Pipewire (user) active" "systemctl --user is-active pipewire" "systemctl --user enable --now pipewire pipewire-pulse wireplumber"

echo ""
echo -e "${BLUE}── Summary ──${NC}"
echo -e "  ${GREEN}Passed:${NC} $PASS"
echo -e "  ${YELLOW}Warnings:${NC} $WARN"
echo -e "  ${RED}Failed:${NC} $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo -e "${RED}Run the install script or fix the failed checks above.${NC}"
    exit 1
elif [[ $WARN -gt 0 ]]; then
    echo -e "${YELLOW}Installation mostly working. Address warnings for full experience.${NC}"
    exit 0
else
    echo -e "${GREEN}All checks passed! Omarchy is fully configured.${NC}"
    exit 0
fi