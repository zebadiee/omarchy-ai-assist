# Hyprland Configuration Guide

## Basic Configuration Structure

Hyprland uses a simple configuration file format located at `~/.config/hypr/hyprland.conf`. The configuration is processed sequentially, so later entries override earlier ones.

## Monitor Configuration

Monitor setup is fundamental to Hyprland:

```bash
# Basic monitor setup
monitor=,preferred,auto,auto
monitor=DP-1,1920x1080@60,0x0,1
monitor=HDMI-A-1,1920x1080@60,19200x0,1

# Multiple monitor with workspace rules
monitor=DP-1,1920x1080@144,0x0,1
monitor=HDMI-A-1,1920x1080@60,1920x0,1
workspace=1,monitor:DP-1
workspace=2,monitor:HDMI-A-1
```

## Input Configuration

Input devices are configured through the input section:

```bash
input {
    kb_layout = us
    kb_variant = altgr-intl
    kb_options = caps:swapescape

    follow_mouse = 1
    mouse_refocus = false

    touchpad {
        natural_scroll = no
        disable_while_typing = true
        tap-to-click = true
        middle_button_emulation = true
    }

    sensitivity = 0
    accel_profile = flat
}
```

## General Settings

Core system behavior settings:

```bash
general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    resize_on_border = false
    no_border_on_floating = false
    extend_border_grab_area = 15
}
```

## Decoration Settings

Window appearance and behavior:

```bash
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
        vibrancy = 0.1696
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
    active_opacity = 1.0
    inactive_opacity = 0.8
    fullscreen_opacity = 1.0
}
```

## Animations

Smooth animations for window operations:

```bash
animations {
    enabled = yes
    bezier = easeOutQuint,0.23,1,0.32,1
    bezier = easeInOutCubic,0.65,0.05,0.36,1
    bezier = linear,0,0,1,1
    bezier = easeInQuad,0.11,0,0.5,0

    animation = windows,1,7,easeOutQuint,slide
    animation = windowsOut,1,7,easeInOutCubic,fade
    animation = border,1,10,linear
    animation = borderangle,1,180,linear,loop
    animation = fade,1,7,easeInQuad
    animation = workspaces,1,6,easeOutQuint,slide
    animation = specialWorkspace,1,6,easeOutQuint,fade
}
```

## Window Rules

Window rules allow you to set properties for specific applications:

```bash
# Floating rules
windowrule=float,^(pavucontrol)$
windowrule=float,^(nm-connection-editor)$
windowrule=float,^(blueman-manager)$
windowrule=float,^(org.gnome.Calculator)$

# Size rules
windowrule=size 50% 50%,^(firefox)$
windowrule=size 80% 80%,^(libreoffice-writer)$

# Position rules
windowrule=center,^(pavucontrol)$
windowrule=move 0 0,^(alacritty)$

# Transparency rules
windowrule=opacity 0.9 0.8,^(kitty)$
windowrule=opacity 0.8 0.7,^(Alacritty)$

# Workspace rules
windowrule=workspace 1,^(firefox)$
windowrule=workspace 2,^(kitty)$
windowrule=workspace 3,^(code-oss)$
```

## Key Bindings

Key bindings are defined using the bind keyword:

```bash
# Mod key
$mainMod = SUPER

# Application launchers
bind = $mainMod, Return, exec, kitty
bind = $mainMod, D, exec, wofi --show drun
bind = $mainMod, E, exec, thunar
bind = $mainMod, B, exec, firefox
bind = $mainMod, C, exec, code

# Window management
bind = $mainMod, Q, killactive
bind = $mainMod, M, exit
bind = $mainMod, F, fullscreen, 0
bind = $mainMod, SPACE, togglefloating
bind = $mainMod, P, pseudo
bind = $mainMod, J, togglesplit

# Workspace navigation
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5

# Move window to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5

# Window navigation
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Window resizing
bind = $mainMod CTRL, left, resizeactive, -20 0
bind = $mainMod CTRL, right, resizeactive, 20 0
bind = $mainMod CTRL, up, resizeactive, 0 -20
bind = $mainMod CTRL, down, resizeactive, 0 20
```

## Startup Applications

Applications to launch when Hyprland starts:

```bash
exec-once = waybar
exec-once = swaybg -i ~/.config/wallpapers/current.jpg
exec-once = swaync
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = hyprpaper
exec-once = copyq --start
```

## Environment Variables

Set environment variables for Hyprland and its applications:

```bash
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt6ct
env = SDL_VIDEODRIVER,wayland
env = _JAVA_AWT_WM_NONREPARENTING,1
env = GDK_SCALE,1
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
```

## Layout Configuration

Different layout algorithms for window arrangement:

```bash
dwindle {
    pseudotile = yes
    preserve_split = yes
    smart_split = no
    smart_resizing = true
}

master {
    new_status = master
    new_on_top = true
    no_gaps_when_only = false
    orientation = left
    inherit_fullscreen = false
    always_center_master = false
    mfact = 0.55
}
```

## Device Configuration

Configure specific input devices:

```bash
device {
    name = epic-mouse-v1
    sensitivity = -0.5
}

device {
    name = my-keyboard
    kb_layout = de
    kb_variant =
    kb_options =
    kb_model =
}
```

## Binds

Additional binding configurations:

```bash
binds {
    allow_workspace_cycles = true
    workspace_back_and_forth = true
    pass_mouse_when_bound = false
    scroll_event_delay = 300
    focus_follows_cursor = no
    special_fallthrough = true
    ignore_group_lock = false
}
```

## Gestures

Touchpad gesture configuration:

```bash
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
    workspace_swipe_invert = false
    workspace_swipe_min_speed_to_force = 5
    workspace_swipe_cancel_ratio = 0.2
    workspace_swipe_create_new = false
}
```

## Group Layouts

Window grouping functionality:

```bash
group {
    groupbar {
        font_size = 16
        col.active = rgba(33ccffee) rgba(00ff99ee) 45deg
        col.inactive = rgba(595959aa)
        col.locked = rgba(7ccaaaff)
        render_titles = true
        text_color = rgb(ffffff)
        col.text = rgb(ffffff)
        col.text_active = rgb(ffffff)
        col.text_locked = rgb(ffffff)
    }
}
```
