#!/usr/bin/env bash
# bar-customizer.sh
# Interactive Omarchy bar (Quickshell) widget management

set -euo pipefail

SHELL_JSON="$HOME/.config/omarchy/shell.json"

show_bar_layout() {
    echo -e "${BLUE}Current bar layout:${NC}"
    jq -r '.bar.layout | to_entries[] | "\(.key): \(.value | map(.id) | join(", "))"' "$SHELL_JSON" 2>/dev/null || echo "Error reading shell.json"
}

list_widgets() {
    echo -e "${BLUE}Available widgets:${NC}"
    omarchy plugin list 2>/dev/null | grep -E '^\s+-' | sed 's/^ *- //' || echo "Run: omarchy plugin list"
}

main() {
    while true; do
        clear
        echo -e "${BLUE}╔══════════════════════════════════════════╗"
        echo -e "║       Omarchy Bar Customizer             ║"
        echo -e "╚══════════════════════════════════════════╝${NC}"
        show_bar_layout
        echo ""
        echo "1) Move widget to different section"
        echo "2) Add widget to section"
        echo "3) Remove widget from section"
        echo "4) Toggle bar position (top/bottom)"
        echo "5) Toggle bar transparency"
        echo "6) List available widgets"
        echo "7) Clone widget for customization"
        echo "8) Restart shell to apply changes"
        echo "9) Reset bar to defaults"
        echo "q) Quit"
        echo ""
        read -p "Choice: " choice
        echo ""
        
        case $choice in
            1)
                read -p "Widget ID (e.g., omarchy.clock): " widget
                read -p "Section (left/center/right): " section
                read -p "Position index (0=first): " pos
                omarchy bar move "$widget" --section "$section" --position "$pos"
                ;;
            2)
                read -p "Widget ID: " widget
                read -p "Section (left/center/right): " section
                read -p "Position index: " pos
                omarchy bar add "$widget" --section "$section" --position "$pos"
                ;;
            3)
                read -p "Widget ID: " widget
                omarchy bar remove "$widget"
                ;;
            4)
                CURRENT=$(jq -r '.bar.position' "$SHELL_JSON")
                NEW=$([[ $CURRENT == "top" ]] && echo "bottom" || echo "top")
                jq ".bar.position = \"$NEW\"" "$SHELL_JSON" > "$SHELL_JSON.tmp" && mv "$SHELL_JSON.tmp" "$SHELL_JSON"
                echo "Bar position changed to $NEW"
                ;;
            5)
                CURRENT=$(jq -r '.bar.transparent' "$SHELL_JSON")
                NEW=$([[ $CURRENT == "true" ]] && echo "false" || echo "true")
                jq ".bar.transparent = $NEW" "$SHELL_JSON" > "$SHELL_JSON.tmp" && mv "$SHELL_JSON.tmp" "$SHELL_JSON"
                echo "Bar transparency: $NEW"
                ;;
            6)
                list_widgets
                ;;
            7)
                read -p "Widget to clone (e.g., omarchy.clock): " widget
                omarchy plugin clone "$widget"
                ;;
            8)
                omarchy restart shell
                ;;
            9)
                omarchy refresh shell
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
    done
}

main "$@"