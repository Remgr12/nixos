{ config, ... }:

let
  cfg = config.myOptions;
in
{
  xdg.configFile."niri/config.kdl".text = ''
    environment {
        XCURSOR_THEME "Moga-Neon-Sky"
        XCURSOR_SIZE "16"
    }

    spawn-at-startup "gsettings set org.gnome.desktop.interface cursor-theme 'Moga-Neon-Sky'"
    spawn-at-startup "gsettings set org.gnome.desktop.interface cursor-size 16"

    prefer-no-csd

    spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"
    spawn-at-startup "mcontrolcenter"
    spawn-at-startup "gpuishell"

    spawn-at-startup "wl-paste" "--watch" "cliphist" "store"
    spawn-at-startup "wl-paste" "--primary" "--watch" "cliphist" "store"

    input {
        focus-follows-mouse

        keyboard {
            xkb {
                layout "us,de,hu"
                variant ",qwerty,qwerty"
                options "grp:caps_toggle"
            }
        }
        
        touchpad {
            tap
            natural-scroll
        }
    }

    hotkey-overlay {
        skip-at-startup
    }

    layout {
        gaps 7
        center-focused-column "never"

        preset-column-widths {
            proportion 0.5
            proportion 1.0
        }
        
        default-column-width { proportion 0.8; }

        focus-ring {
            width 0
            active-gradient from="#8caaee" to="#babbf1" angle=45
            inactive-color "#303446"
        }

        border { off; }
    }

    output "${cfg.monitor}" {
        mode "1920x1080@120.000"
        scale 1.0
    }

    animations {
        workspace-switch { spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001; }
        window-open { duration-ms 250; curve "ease-out-expo"; }
        window-close { duration-ms 250; curve "ease-out-quad"; }
    }

    window-rule {
        match {}
        geometry-corner-radius 0
        open-maximized true
    }

    window-rule {
        match app-id="gamescope"
        allow-tearing
    }

    window-rule {
        match app-id=".*Minecraft.*"
        allow-tearing
    }

    window-rule {
        match app-id="org.vinegarhq.Sober"
        allow-tearing
    }

    window-rule {
        match app-id="cs2"
        allow-tearing
    }

    window-rule {
        match is-active=false
        opacity 0.95
    }

    window-rule {
        match is-active=true
        opacity 0.95
    }

    window-rule {
        match app-id="kitty"
        open-maximized false
        default-column-width { proportion 0.5; }
    }

    window-rule {
        match app-id="org.gnome.Nautilus"
        open-maximized false
        default-column-width { proportion 0.5; }
    }

    window-rule {
        match app-id="localsend_app"
        open-floating true
    }

    window-rule {
        match app-id="gsr-ui"
        open-floating true
    }

    binds {
        Mod+Q { spawn "kitty"; }
        Mod+Return { spawn "kitty"; }
        Mod+S { spawn "net.waterfox.waterfox"; }
        Mod+Space { spawn "fuzzel"; }
        Mod+E { spawn "nautilus"; }
        Mod+D { spawn "spotify"; }
        Mod+C { spawn "kitty" "nvim"; }

        XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
        XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
        XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }
        
        Mod+X { close-window; }
        Mod+Shift+X { quit; }

        Mod+Left  { focus-column-left; }
        Mod+Down  { focus-workspace-down; }
        Mod+Up    { focus-workspace-up; }
        Mod+Right { focus-column-right; }

        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Down  { move-window-down; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Right { move-column-right; }

        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        Mod+F     { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+Z { toggle-window-floating; }
        Mod+Shift+Z { switch-focus-between-floating-and-tiling; }

        Mod+V { spawn "cliphist-fuzzel-img"; }

        Mod+A { toggle-overview; }
        Mod+Escape { spawn "~/Repositories/scripts/powermenu.sh"; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }

        Print { screenshot; }
        Shift+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }

        Mod+MouseBack    { focus-column-right; }
        Mod+MouseForward { focus-column-left; }

        Mod+WheelScrollUp cooldown-ms=100 { focus-column-left; }
        Mod+WheelScrollDown cooldown-ms=100 { focus-column-right; }

        Mod+B allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
    }
  '';
}
