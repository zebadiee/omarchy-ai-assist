# Omarchy Go Development Guide

## Philosophy

Minimal, keyboard-driven, AI-assisted Go tools for Omarchy OS

### Key Points

- Single binary deployment
- Static linking
- Wayland compatibility

## Development Patterns

Follow Omarchy conventions for seamless desktop integration

### Key Points

- ~/.config/omarchy/ for configs
- ~/.local/bin/ for tools
- systemd user services

## Integration Points

Connect with Hyprland, Waybar, Wofi, and AI systems

### Key Points

- Waybar status modules
- Wofi menu integration
- Hyprland keybinds

## Build Process

Optimized for minimal, portable Go applications

### Key Points

- CGO_ENABLED=0
- Static linking
- Cross-compilation

