#!/usr/bin/env bash
# theme-manager.sh
# Interactive theme management for Omarchy

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

CURRENT=$(omarchy theme current 2>/dev/null || echo "unknown")

show_menu() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════╗"
    echo -e "║       Omarchy Theme Manager              ║"
    echo -e "╚══════════════════════════════════════════╝${NC}"
    echo -e "Current theme: ${GREEN}$CURRENT${NC}"
    echo ""
    echo "1) List all themes"
    echo "2) Set theme (interactive)"
    echo "3) Open visual theme switcher"
    echo "4) Open background switcher"
    echo "5) Cycle to next background"
    echo "6) Refresh current theme"
    echo "7) Install theme from git repo"
    echo "8) Remove user theme"
    echo "9) Show theme directory"
    echo "q) Quit"
    echo ""
}

while true; do
    show_menu
    read -p "Choice: " choice
    echo ""
    
    case $choice in
        1)
            omarchy theme list
            ;;
        2)
            omarchy theme list
            echo ""
            read -p "Theme name: " theme
            [[ -n $theme ]] && omarchy theme set "$theme"
            ;;
        3)
            omarchy theme switcher
            ;;
        4)
            omarchy theme bg-switcher
            ;;
        5)
            omarchy theme bg next
            ;;
        6)
            omarchy theme refresh
            ;;
        7)
            read -p "Git repo URL: " url
            [[ -n $url ]] && omarchy theme install "$url"
            ;;
        8)
            omarchy theme extras
            echo ""
            read -p "Theme to remove: " theme
            [[ -n $theme ]] && omarchy theme remove "$theme"
            ;;
        9)
            THEME=$(omarchy theme current)
            omarchy theme dir "$THEME"
            ;;
        q|Q)
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    CURRENT=$(omarchy theme current 2>/dev/null || echo "unknown")
done