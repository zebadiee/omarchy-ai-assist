# Hyprland Workspaces and Window Management

## Workspace Basics

Workspaces in Hyprland are virtual desktops that help organize your windows. Each workspace can contain multiple windows arranged according to your layout rules.

### Workspace Naming and Rules

```bash
# Basic workspace rules
workspace = 1, monitor:DP-1
workspace = 2, monitor:DP-1
workspace = 3, monitor:HDMI-A-1

# Named workspaces
workspace = name:web, 1
workspace = name:code, 2
workspace = name:term, 3

# Workspace-specific rules
workspace = 1, gapsout:40, border:true
workspace = 2, rounding:false
```

### Dynamic Workspace Creation

Hyprland automatically creates workspaces when needed:

```bash
# Create workspace on specific monitor
workspace = 10, monitor:DP-1

# Persistent workspaces (created even if empty)
workspace = 1, persistent:true
workspace = 2, persistent:true
```

## Window Management in Workspaces

### Moving Windows Between Workspaces

```bash
# Move to specific workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2

# Move to adjacent workspace
bind = $mainMod CTRL, left, movetoworkspace, -1
bind = $mainMod CTRL, right, movetoworkspace, +1

# Move with follow
bind = $mainMod ALT, 1, movetoworkspacesilent, 1
bind = $mainMod ALT SHIFT, 1, movetoworkspace, 1
```

### Workspace Navigation

```bash
# Switch to workspace
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2

# Switch to adjacent workspace
bind = $mainMod, bracketleft, workspace, -1
bind = $mainMod, bracketright, workspace, +1

# Cycle through workspaces
bind = $mainMod, TAB, cyclenext
bind = $mainMod SHIFT, TAB, cyclenext, prev

# Workspace overview
bind = $mainMod, grave, overview:toggle
```

## Special Workspaces

Special workspaces are for floating windows that should stay visible:

```bash
# Create special workspace
bind = $mainMod, S, togglespecialworkspace
bind = $mainMod SHIFT, S, movetoworkspace, special

# Window rules for special workspace
windowrule = float, ^(pavucontrol)$
windowrule = workspace special, ^(pavucontrol)$
windowrule = workspace special silent, ^(blueman-manager)$
```

## Layout Rules per Workspace

Different layouts for different workspaces:

```bash
# Master layout for coding workspace
workspace = 2, layoutopt:orientation:right
workspace = 2, layoutopt:master_ratio:0.7

# Dwindle layout for browsing
workspace = 1, layoutopt:preserve_split:true

# Specific layout for design workspace
workspace = 4, layout:master
```

## Window Rules and Workspace Assignment

Automatically assign applications to specific workspaces:

```bash
# Browser workspace
windowrule = workspace 1, ^(firefox)$
windowrule = workspace 1, ^(chromium)$
windowrule = workspace 1, ^(librewolf)$

# Development workspace
windowrule = workspace 2, ^(code-oss)$
windowrule = workspace 2, ^(kitty)$
windowrule = workspace 2, ^(alacritty)$

# Communication workspace
windowrule = workspace 3, ^(discord)$
windowrule = workspace 3, ^(teams-for-linux)$
windowrule = workspace 3, ^(TelegramDesktop)$

# Media workspace
windowrule = workspace 4, ^(obs)$
windowrule = workspace 4, ^(vlc)$
windowrule = workspace 4, ^(mpv)$
```

## Workspace-Specific Settings

Configure different settings per workspace:

```bash
# Workspace 1 - Browsing (larger gaps)
workspace = 1, gapsout:30
workspace = 1, border_size:3

# Workspace 2 - Development (tight layout)
workspace = 2, gapsout:10
workspace = 2, border_size:1

# Workspace 3 - Communication (floating-friendly)
workspace = 3, layoutopt:special_persist:true
```

## Monitor and Workspace Integration

Multi-monitor workspace management:

```bash
# Monitor-specific workspace rules
monitor = DP-1, addreserved, 0, 0, 0, 40
monitor = HDMI-A-1, addreserved, 0, 0, 0, 40

# Workspace per monitor
workspace = 1, monitor:DP-1
workspace = 2, monitor:DP-1
workspace = 3, monitor:HDMI-A-1
workspace = 4, monitor:HDMI-A-1

# Move workspaces between monitors
bind = $mainMod, period, movecurrentworkspacetomonitor, +1
bind = $mainMod, comma, movecurrentworkspacetomonitor, -1
```

## Advanced Workspace Features

### Workspace Rules with Conditions

```bash
# Conditional workspace rules
workspace = 1, if-active:fullscreen, gapsout:0
workspace = 2, if-active:floating, layoutopt:special_persist:true

# Workspace cycling with conditions
bind = $mainMod, mouse_down, workspace, +1
bind = $mainMod, mouse_up, workspace, -1
```

### Workspace Back and Forth

```bash
# Enable workspace back-and-forth
binds {
    workspace_back_and_forth = true
}

# Back and forth navigation
bind = $mainMod, TAB, workspace, previous
bind = $mainMod SHIFT, TAB, workspace, previous
```

## Workspace Animation and Transitions

Smooth workspace transitions:

```bash
animations {
    animation = workspaces,1,6,easeOutQuint,slide
    animation = specialWorkspace,1,6,easeOutQuint,fade
}

# Disable animations for specific workspaces
workspace = 1, animation:disabled
```

## Troubleshooting Workspaces

### Common Issues

1. **Workspaces not persisting**: Ensure workspace rules are set before any window rules
2. **Windows jumping workspaces**: Check for conflicting window rules
3. **Layout not applying**: Verify layout rules are set correctly

### Debugging Workspace Rules

```bash
# Test workspace rule
hyprctl keyword workspace 1,monitor:DP-1

# Check current workspace
hyprctl activeworkspace

# List all workspaces
hyprctl workspaces

# Check workspace rules
hyprctl getrules workspace
```

## Best Practices

1. **Organize by function**: Group similar applications in the same workspace
2. **Use consistent numbering**: Maintain a logical workspace numbering scheme
3. **Leverage window rules**: Automatically assign applications to appropriate workspaces
4. **Consider workflow**: Arrange workspaces based on your typical workflow
5. **Test thoroughly**: Verify workspace rules work as expected after configuration changes

## Example Complete Workspace Configuration

```bash
# Workspace assignments
workspace = 1, monitor:DP-1, gapsout:25
workspace = 2, monitor:DP-1, gapsout:15
workspace = 3, monitor:HDMI-A-1, gapsout:20
workspace = 4, monitor:HDMI-A-1, gapsout:10

# Window rules for workspace assignment
windowrule = workspace 1, ^(firefox)$
windowrule = workspace 2, ^(code-oss)$
windowrule = workspace 3, ^(discord)$
windowrule = workspace 4, ^(obs)$

# Workspace navigation
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4

# Move windows between workspaces
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4

# Workspace cycling
bind = $mainMod, bracketleft, workspace, -1
bind = $mainMod, bracketright, workspace, +1
```
