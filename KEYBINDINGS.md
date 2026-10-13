# Omarchy on CachyOS - Keybindings Reference

## Default Hyprland Keybindings (Super = Mod4/Windows key)

### Window Management
| Key | Action |
|-----|--------|
| `Super + Q` | Close window |
| `Super + F` | Toggle fullscreen |
| `Super + V` | Toggle floating |
| `Super + Space` | Toggle pseudo-tile |
| `Super + Shift + Space` | Toggle split |
| `Super + Mouse` | Move/resize window |
| `Super + Shift + Q` | Kill window |
| `Super + M` | Toggle minimize |

### Workspaces
| Key | Action |
|-----|--------|
| `Super + 1-9` | Switch to workspace 1-9 |
| `Super + Shift + 1-9` | Move window to workspace 1-9 |
| `Super + Tab` | Previous workspace |
| `Super + Shift + Tab` | Move window to previous workspace |
| `Super + Ctrl + Left/Right` | Move workspace left/right |
| `Super + Scroll` | Next/previous workspace |

### Layout
| Key | Action |
|-----|--------|
| `Super + H/J/K/L` | Focus left/down/up/right |
| `Super + Shift + H/J/K/L` | Move window left/down/up/right |
| `Super + Ctrl + H/J/K/L` | Resize window |
| `Super + , / .` | Resize main window |
| `Super + Shift + , / .` | Move window to master |
| `Super + \` | Toggle split orientation |

### Applications
| Key | Action |
|-----|--------|
| `Super + Enter` | Terminal (foot) |
| `Super + Shift + Enter` | Terminal (kitty) |
| `Super + D` | App launcher (fuzzel) |
| `Super + E` | File manager (nautilus) |
| `Super + B` | Browser |
| `Super + Shift + B` | Browser (private) |
| `Super + C` | Calculator |
| `Super + Shift + C` | Color picker |
| `Super + P` | Power menu |
| `Super + Shift + P` | Screenshot region |
| `Super + Print` | Screenshot full |
| `Super + Shift + Print` | Screenshot window |

### System
| Key | Action |
|-----|--------|
| `Super + L` | Lock screen |
| `Super + Shift + L` | Logout |
| `Super + Ctrl + L` | Suspend |
| `Super + R` | Reload Hyprland |
| `Super + Shift + R` | Restart Waybar |
| `Super + Escape` | Kill XWayland apps |

### Audio/Brightness
| Key | Action |
|-----|--------|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute toggle |
| `XF86MonBrightnessUp` | Brightness up |
| `XF86MonBrightnessDown` | Brightness down |
| `XF86AudioPlay` | Play/pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |

### Omarchy-Specific
| Key | Action |
|-----|--------|
| `Super + Shift + Space` | Omarchy menu |
| `Super + Alt + T` | Theme switcher |
| `Super + Alt + B` | Background switcher |
| `Super + Alt + K` | Keybindings cheatsheet |
| `Super + Alt + R` | Reload Omarchy shell |

---

## Customizing Keybindings

Edit `~/.config/hypr/bindings.lua`:

```lua
-- Add custom binding
bind("SUPER", "KEY", "command", "description")

-- Example: Super+T for todo app
bind("SUPER", "T", "exec", "obsidian")

-- Remove binding
unbind("SUPER", "KEY")
```

Apply changes:
```bash
hyprctl reload
# or
omarchy restart hyprctl
```

---

## Useful Commands

```bash
# Show all bindings
hyprctl binds

# Show current workspace windows
hyprctl clients

# Reload config
hyprctl reload

# Toggle gaps
hyprctl keyword general:gaps_out 10

# Toggle animations
hyprctl keyword animations:enabled 0
```