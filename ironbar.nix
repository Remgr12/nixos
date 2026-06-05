{ config, pkgs, inputs, osConfig, ... }:

let
  cfg = osConfig.myOptions;
  ironbar-flake = inputs.ironbar-flake;
  ironbarPkg = ironbar-flake.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = with pkgs; [
    (writeShellScriptBin "ironbar-swaync-toggle" ''
      ${swaynotificationcenter}/bin/swaync-client -t -sw &
    '')
    (writeShellScriptBin "ironbar-swaync-dnd" ''
      ${swaynotificationcenter}/bin/swaync-client -d &
    '')
    (writeShellScriptBin "ironbar-sys-details" ''
      CPU_TEMP=$(${lm_sensors}/bin/sensors | ${gnugrep}/bin/grep "Package id 0:" | ${gawk}/bin/awk '{print $4}')
      CPU_FREQ=$(${coreutils}/bin/cat /proc/cpuinfo | ${gnugrep}/bin/grep "cpu MHz" | ${coreutils}/bin/head -n1 | ${gawk}/bin/awk '{print $4}')
      echo "CPU Temp: $CPU_TEMP"
      echo "CPU Speed: ''${CPU_FREQ%.*} MHz"
    '')
    (writeShellScriptBin "ironbar-gpu-details" ''
      TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null || echo "N/A")
      LOAD=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "N/A")
      echo "Load: ''${LOAD}%  |  Temp: ''${TEMP}°C"
      echo "--- Apps Using GPU ---"
      nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader 2>/dev/null | ${gawk}/bin/awk -F', ' '{print " • " $2 " (" $3 ")"}'
    '')
    (writeShellScriptBin "ironbar-storage-details" ''
      DISK_INFO=$(${coreutils}/bin/df -h / | ${coreutils}/bin/tail -n 1)
      SIZE=$(echo "$DISK_INFO" | ${gawk}/bin/awk '{print $2}')
      USED=$(echo "$DISK_INFO" | ${gawk}/bin/awk '{print $3}')
      AVAIL=$(echo "$DISK_INFO" | ${gawk}/bin/awk '{print $4}')
      USE_PERC=$(echo "$DISK_INFO" | ${gawk}/bin/awk '{print $5}')
      echo "Root Partition (/):"
      echo "Total: $SIZE | Used: $USED ($USE_PERC) | Free: $AVAIL"
      echo ""
      echo "RAM Status:"
      ${procps}/bin/free -h | ${gnugrep}/bin/grep "Mem:" | ${gawk}/bin/awk '{print "Total: " $2 " | Used: " $3 " | Free: " $4}'
    '')
    (writeShellScriptBin "ironbar-services" ''
      echo "Main Services Status:"
      systemctl --user is-active ironbar awww swaync | ${gawk}/bin/awk 'BEGIN {a[0]="ironbar"; a[1]="swaybg"; a[2]="swaync"} {print a[NR-1] ": " $0}'
      echo ""
      echo "System Load: $(${coreutils}/bin/uptime | ${gawk}/bin/awk -F'load average:' '{ print $2 }')"
    '')
    (writeShellScriptBin "ironbar-music" ''
      STATUS=$(${playerctl}/bin/playerctl status 2>/dev/null)
      if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
          ARTIST=$(${playerctl}/bin/playerctl metadata artist)
          TITLE=$(${playerctl}/bin/playerctl metadata title)
          echo "  󰎆 ''${TITLE} - ''${ARTIST}  "
      else
          echo ""
      fi
    '')
    (writeShellScriptBin "ironbar-audio" ''
      VOL=$(${pulseaudio}/bin/pactl get-sink-volume @DEFAULT_SINK@ | ${gnugrep}/bin/grep -o '[0-9]*%' | ${coreutils}/bin/head -n1)
      MIC=$(${pulseaudio}/bin/pactl get-source-volume @DEFAULT_SOURCE@ | ${gnugrep}/bin/grep -o '[0-9]*%' | ${coreutils}/bin/head -n1)
      echo "  󰕾 ''${VOL}   ''${MIC}  "
    '')
    (writeShellScriptBin "ironbar-bluetooth" ''
      DEV=$(${wireplumber}/bin/wpctl status | ${gnugrep}/bin/grep -i 'bluez' | ${coreutils}/bin/head -n1 | ${gnused}/bin/sed -E 's/.*[0-9]+\.\s*(.*)\s*\[.*/\1/')
      if [ -n "$DEV" ]; then
        echo "󰋋 ''${DEV}"
      else
        echo "󰂯"
      fi
    '')
    (writeShellScriptBin "ironbar-blueman" ''
      ${blueman}/bin/blueman-manager &
    '')
    (writeShellScriptBin "ironbar-bt-status" ''
      BT=${bluez}/bin/bluetoothctl
      if $BT show 2>/dev/null | ${gnugrep}/bin/grep -q "Powered: yes"; then
        OUT="Bluetooth: On\n\n"
      else
        OUT="Bluetooth: Off\n\n"
      fi
      OUT="$OUT""Connected:\n"
      CONN=$($BT devices Connected 2>/dev/null | ${gnused}/bin/sed -E 's/^Device [0-9A-F:]+ /  • /')
      if [ -n "$CONN" ]; then OUT="$OUT$CONN\n"; else OUT="$OUT  (none)\n"; fi
      OUT="$OUT""\nPaired:\n"
      PAIRED=$($BT devices Paired 2>/dev/null | ${gnused}/bin/sed -E 's/^Device [0-9A-F:]+ /  • /')
      if [ -n "$PAIRED" ]; then OUT="$OUT$PAIRED\n"; else OUT="$OUT  (none)\n"; fi
      ${coreutils}/bin/printf '%b' "$OUT" | ${gnused}/bin/sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
    '')
    (writeShellScriptBin "ironbar-bt-toggle" ''
      BT=${bluez}/bin/bluetoothctl
      if $BT show 2>/dev/null | ${gnugrep}/bin/grep -q "Powered: yes"; then
        $BT power off >/dev/null 2>&1
        ${libnotify}/bin/notify-send "Bluetooth" "Powered off"
      else
        $BT power on >/dev/null 2>&1
        ${libnotify}/bin/notify-send "Bluetooth" "Powered on"
      fi
    '')
    (writeShellScriptBin "ironbar-bt-menu" ''
      BT=${bluez}/bin/bluetoothctl
      FUZZEL=${fuzzel}/bin/fuzzel
      NOTIFY=${libnotify}/bin/notify-send
      TMP=$(${coreutils}/bin/mktemp)
      SCAN_LABEL="⟳  Scan for new devices…"

      $BT power on >/dev/null 2>&1

      list_to_file() {
        : > "$TMP"
        $BT devices 2>/dev/null | while read -r _ mac name; do
          [ -z "$mac" ] && continue
          info=$($BT info "$mac" 2>/dev/null)
          if ${coreutils}/bin/printf '%s' "$info" | ${gnugrep}/bin/grep -q "Connected: yes"; then
            ${coreutils}/bin/printf '%s\t✓  %s  (connected)\n' "$mac" "$name" >> "$TMP"
          elif ${coreutils}/bin/printf '%s' "$info" | ${gnugrep}/bin/grep -q "Paired: yes"; then
            ${coreutils}/bin/printf '%s\t•  %s\n' "$mac" "$name" >> "$TMP"
          else
            ${coreutils}/bin/printf '%s\t+  %s  (new)\n' "$mac" "$name" >> "$TMP"
          fi
        done
      }

      show_menu() {
        { ${coreutils}/bin/printf '%s\n' "$SCAN_LABEL"; ${coreutils}/bin/cut -f2- "$TMP"; } \
          | $FUZZEL --dmenu --prompt "Bluetooth  "
      }

      list_to_file
      CHOICE=$(show_menu)
      if [ "$CHOICE" = "$SCAN_LABEL" ]; then
        $NOTIFY "Bluetooth" "Scanning…"
        $BT --timeout 6 scan on >/dev/null 2>&1
        list_to_file
        CHOICE=$(show_menu)
      fi

      if [ -z "$CHOICE" ] || [ "$CHOICE" = "$SCAN_LABEL" ]; then ${coreutils}/bin/rm -f "$TMP"; exit 0; fi
      MAC=$(${gawk}/bin/awk -F'\t' -v c="$CHOICE" '$2==c{print $1; exit}' "$TMP")
      ${coreutils}/bin/rm -f "$TMP"
      [ -z "$MAC" ] && exit 0

      info=$($BT info "$MAC" 2>/dev/null)
      if ${coreutils}/bin/printf '%s' "$info" | ${gnugrep}/bin/grep -q "Connected: yes"; then
        $BT disconnect "$MAC" >/dev/null 2>&1 && $NOTIFY "Bluetooth" "Disconnected"
      elif ${coreutils}/bin/printf '%s' "$info" | ${gnugrep}/bin/grep -q "Paired: yes"; then
        $BT connect "$MAC" >/dev/null 2>&1 && $NOTIFY "Bluetooth" "Connected" || $NOTIFY "Bluetooth" "Connection failed"
      else
        $NOTIFY "Bluetooth" "Pairing…"
        $BT pair "$MAC" >/dev/null 2>&1
        $BT trust "$MAC" >/dev/null 2>&1
        if $BT connect "$MAC" >/dev/null 2>&1; then $NOTIFY "Bluetooth" "Paired & connected"; else $NOTIFY "Bluetooth" "Pairing failed"; fi
      fi
    '')
    (writeShellScriptBin "ironbar-swaync" ''
      COUNT=$(${swaynotificationcenter}/bin/swaync-client -c 2>/dev/null || echo 0)
      DND=$(${swaynotificationcenter}/bin/swaync-client -D 2>/dev/null || echo "false")
      if [ "$COUNT" = "" ]; then COUNT=0; fi
      if [ "$DND" = "true" ]; then
        echo "󰂛 $COUNT"
      elif [ "$COUNT" -gt 0 ]; then
        echo "󱅫 $COUNT"
      else
        echo "󰂚 "
      fi
    '')
    (writeShellScriptBin "ironbar-swaync-icon" ''
      COUNT=$(${swaynotificationcenter}/bin/swaync-client -c 2>/dev/null || echo 0)
      DND=$(${swaynotificationcenter}/bin/swaync-client -D 2>/dev/null || echo "false")
      if [ "$COUNT" = "" ]; then COUNT=0; fi
      if [ "$DND" = "true" ]; then
        echo "󰂛"
      elif [ "$COUNT" -gt 0 ]; then
        echo "󱅫"
      else
        echo "󰂚"
      fi
    '')
    (writeShellScriptBin "ironbar-swaync-count" ''
      COUNT=$(${swaynotificationcenter}/bin/swaync-client -c 2>/dev/null || echo 0)
      if [ "$COUNT" = "" ]; then COUNT=0; fi
      if [ "$COUNT" -gt 0 ]; then
        echo "$COUNT"
      fi
    '')
  ];

  systemd.user.services.ironbar = {
    Unit = {
      Description = "Ironbar Wayland bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "tray.target" ];
    };
    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      ExecStart = "${ironbarPkg}/bin/ironbar";
      Restart = "on-failure";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  programs.ironbar = {
    enable = true;
    systemd = false; 
    package = ironbarPkg;
    
    style = ''
      * {
          font-family: CaskaydiaCove Nerd Font, sans-serif;
          font-size: 13px;
          text-shadow: none;
          border: none;
          border-radius: 0;
          opacity: 1.0;
          min-height: 0;
          padding: 0;
          margin: 0;
      }

      /* Kill default ironbar margins */
      .module { margin: 0; padding: 0; }

      .background { background-color: rgba(46, 52, 64, 0.92); }
      button, label { box-shadow: none; background: none; background-color: rgba(0, 0, 0, 0); color: #d8dee9; padding: 0; margin: 0; }
      button:hover { background-color: rgba(59, 66, 82, 0.9); }
      #bar { background-color: rgba(46, 52, 64, 0.92); background-image: none; box-shadow: 0 1px 0 rgba(76, 86, 106, 0.5); padding: 0 4px; }
      .popup { background-color: rgba(59, 66, 82, 0.97); border: 1px solid rgba(76, 86, 106, 0.9); border-radius: 6px; padding: 4px; }

      scale trough { border-radius: 4px; background-color: #4C566A; min-height: 4px; }
      scale trough highlight { border-radius: 4px; background-color: #88C0D0; }
      scale value { color: #d8dee9; }

      /* Left Side */
      .workspaces .item { margin: 0 2px; padding: 0 8px; }
      .workspaces .item.focused { box-shadow: inset 0 -2px #88C0D0; background-color: rgba(59, 66, 82, 0.9); }
      .workspaces .item:hover { box-shadow: inset 0 -2px #4C566A; }
      .clock-mod { margin-left: 10px; padding: 0 12px; font-weight: bold; color: #D8DEE9; border-radius: 4px; transition: background-color 0.2s; }
      .clock-mod:hover { background-color: rgba(59, 66, 82, 0.9); }
      .bluetooth-mod { margin-left: 12px; font-weight: bold; color: #81A1C1; padding: 0; }
      .bt-btn { color: #81A1C1; padding: 0 8px; border-radius: 4px; transition: background-color 0.2s; }
      .bt-btn:hover { background-color: rgba(59, 66, 82, 0.9); }

      /* Center */
      .music { color: #8FBCBB; font-weight: bold; padding: 0 10px; }
      .popup-music { min-width: 280px; padding: 12px 16px; }
      .popup-music .title { font-size: 14px; font-weight: bold; color: #8FBCBB; padding-bottom: 2px; }
      .popup-music .artist { color: #A3BE8C; font-size: 12px; }
      .popup-music .album { color: #81A1C1; font-size: 11px; padding-bottom: 8px; }
      .popup-music .controls { margin-top: 6px; }
      .popup-music .controls button { padding: 3px 14px; margin: 0 3px; border-radius: 4px; font-size: 14px; }
      .popup-music scale { margin-top: 8px; }

      /* Right Side - Performance Modules with equal spacing */
      .cpu-mod, .ram-mod, .gpu-mod { margin: 0 4px; padding: 0 8px; border-radius: 4px; transition: background-color 0.2s; }
      .cpu-mod:hover, .ram-mod:hover, .gpu-mod:hover { background-color: rgba(59, 66, 82, 0.9); }
      .cpu-text, .cpu-text label { color: #A3BE8C; font-weight: bold; }
      .ram-text, .ram-text label { color: #EBCB8B; font-weight: bold; }
      .gpu-icon { font-weight: bold; color: #CBA6F7; font-size: 15px; }
      .gpu-text { font-weight: bold; color: #CBA6F7; }

      /* Right Side - Vol / tray / notif with individual spacing */
      .vol-mod { margin-left: 14px; padding: 0 10px; font-weight: bold; color: #88C0D0; border-radius: 4px; transition: background-color 0.2s; }
      .vol-mod:hover { background-color: rgba(59, 66, 82, 0.9); }
      .starship-mod { margin-left: 14px; padding: 0 10px; border-radius: 4px; transition: background-color 0.2s; }
      .starship-mod:hover { background-color: rgba(59, 66, 82, 0.9); }
      .starship-icon { font-size: 16px; }
      .notif-mod { margin-left: 14px; padding: 0; border-radius: 4px; }
      .notif-btn { padding: 0 10px; border-radius: 4px; transition: background-color 0.2s; }
      .notif-btn:hover { background-color: rgba(59, 66, 82, 0.9); }
      .notif-icon { font-size: 15px; color: #8FBCBB; font-weight: bold; }
      .notif-count { font-size: 10px; font-weight: bold; color: #EBCB8B; margin-left: 4px; }

      /* Calendar popup (native clock module) */
      .popup-clock { padding: 12px 16px; }
      .popup-clock .calendar-clock { font-size: 22px; font-weight: bold; color: #88C0D0; margin-bottom: 8px; }
      .popup-clock .calendar { background-color: transparent; color: #D8DEE9; font-size: 14px; }
      .popup-clock .calendar > header { color: #8FBCBB; font-weight: bold; }
      .popup-clock .calendar button { color: #D8DEE9; border-radius: 4px; padding: 2px; }
      .popup-clock .calendar button:hover { background-color: rgba(76, 86, 106, 0.6); }
      .popup-clock .calendar label.day-number { padding: 4px; border-radius: 4px; }
      .popup-clock .calendar label.day-number.today { background-color: #88C0D0; color: #2E3440; font-weight: bold; }
      .popup-clock .calendar label.day-number.other-month { color: #4C566A; }

      /* Bluetooth popup */
      .popup-bt { padding: 12px 14px; min-width: 250px; }
      .popup-bt-status { font-family: JetBrainsMono Nerd Font, monospace; font-size: 12px; color: #D8DEE9; padding-bottom: 10px; }
      .bt-action-btn { padding: 6px 10px; margin: 0 3px; border-radius: 4px; color: #81A1C1; transition: background-color 0.2s; }
      .bt-action-btn:hover { background-color: rgba(59, 66, 82, 0.9); }

      /* Popups */
      .popup-text, .popup-text label { font-family: JetBrainsMono Nerd Font, monospace; }
      .tray { padding: 6px 10px; }
      .tray .item { margin: 0 3px; padding: 3px; }

      /* GTK native menus (system tray right-click) */
      menu { background-color: #3B4252; border: 1px solid #4C566A; border-radius: 6px; padding: 4px 0; }
      menu > menuitem { padding: 9px 22px; min-height: 34px; color: #D8DEE9; border-radius: 0; }
      menu > menuitem:hover { background-color: #4C566A; }
      menu > menuitem > label { color: #D8DEE9; font-size: 14px; }
      menu > menuitem > image { margin-right: 8px; }
      menu > separator { background-color: rgba(76, 86, 106, 0.6); min-height: 1px; margin: 3px 0; padding: 0; }
    '';
  };

  xdg.configFile."ironbar/config.json".text = ''
    {
      "monitors": {
        "${cfg.monitor}": {
          "name": "main-bar",
          "popup_autohide": true,
          "anchor_to_edges": true,
          "position": "top",
          "height": 28,
          "start": [
            {
              "type": "workspaces",
              "all_monitors": false,
              "on_scroll_up": "swaymsg workspace prev_on_output",
              "on_scroll_down": "swaymsg workspace next_on_output"
            },
            {
              "type": "clock",
              "class": "clock-mod",
              "format": "%d/%m/%Y %H:%M",
              "format_popup": "%H:%M:%S"
            }
          ],
          "center": [
            {
              "type": "music",
              "player_type": "mpris",
              "format": "{title} - {artist}",
              "on_click_left": "${pkgs.playerctl}/bin/playerctl play-pause",
              "on_click_right": "${ironbarPkg}/bin/ironbar bar main-bar toggle-popup music",
              "on_scroll_up": "${pkgs.playerctl}/bin/playerctl next",
              "on_scroll_down": "${pkgs.playerctl}/bin/playerctl previous"
            }
          ],
          "end": [
            {
              "type": "custom",
              "class": "cpu-mod",
              "bar": [
                {
                  "type": "button",
                  "class": "sysinfo",
                  "on_click": "popup:toggle",
                  "widgets": [
                    {
                      "type": "label",
                      "class": "cpu-text",
                      "label": "  {{2000:top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d. -f1}}%"
                    }
                  ]
                }
              ],
              "popup": [
                {
                  "type": "label",
                  "class": "popup-text",
                  "label": "{{2000:ironbar-sys-details}}"
                }
              ]
            },
            {
              "type": "custom",
              "class": "ram-mod",
              "bar": [
                {
                  "type": "button",
                  "class": "sysinfo",
                  "on_click": "popup:toggle",
                  "widgets": [
                    {
                      "type": "label",
                      "class": "ram-text",
                      "label": "  {{2000:free -m | awk '/Mem:/ { printf(\"%.0f\", $3/$2*100) }'}}%"
                    }
                  ]
                }
              ],
              "popup": [
                {
                  "type": "label",
                  "class": "popup-text",
                  "label": "{{2000:ironbar-storage-details}}"
                }
              ]
            },
            {
              "type": "custom",
              "class": "gpu-mod",
              "bar": [
                {
                  "type": "button",
                  "class": "gpu",
                  "on_click": "popup:toggle",
                  "widgets": [
                    {
                      "type": "box",
                      "orientation": "horizontal",
                      "widgets": [
                        {
                          "type": "label",
                          "class": "gpu-icon",
                          "label": "󰢮  "
                        },
                        {
                          "type": "label",
                          "class": "gpu-text",
                          "label": "{{2000:nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits}}%"
                        }
                      ]
                    }
                  ]
                }
              ],
              "popup": [
                {
                  "type": "label",
                  "class": "popup-text",
                  "label": "{{2000:ironbar-gpu-details}}"
                }
              ]
            },
            {
              "type": "volume",
              "class": "vol-mod",
              "format": "󰕾  {percentage}%",
              "show_sources": false,
              "on_click_right": "pavucontrol"
            },
            {
              "type": "custom",
              "class": "bluetooth-mod",
              "bar": [
                {
                  "type": "button",
                  "class": "bt-btn",
                  "on_click": "popup:toggle",
                  "label": "{{2000:ironbar-bluetooth}}"
                }
              ],
              "popup": [
                {
                  "type": "box",
                  "orientation": "vertical",
                  "class": "popup-bt",
                  "widgets": [
                    {
                      "type": "label",
                      "class": "popup-bt-status",
                      "label": "{{2000:ironbar-bt-status}}"
                    },
                    {
                      "type": "box",
                      "orientation": "horizontal",
                      "class": "bt-actions",
                      "widgets": [
                        {
                          "type": "button",
                          "class": "bt-action-btn",
                          "label": "󰂱  Connect / Pair…",
                          "on_click": "!ironbar-bt-menu"
                        },
                        {
                          "type": "button",
                          "class": "bt-action-btn",
                          "label": "󰐦  Power",
                          "on_click": "!ironbar-bt-toggle"
                        },
                        {
                          "type": "button",
                          "class": "bt-action-btn",
                          "label": "󰂯  Blueman",
                          "on_click": "!ironbar-blueman"
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              "type": "custom",
              "class": "starship-mod",
              "bar": [
                {
                  "type": "button",
                  "class": "starship-icon",
                  "label": "󱓞",
                  "on_click": "popup:toggle"
                }
              ],
              "popup": [
                {
                  "type": "tray"
                }
              ]
            },
            {
              "type": "custom",
              "class": "notif-mod",
              "bar": [
                {
                  "type": "button",
                  "class": "notif-btn",
                  "on_click": "!ironbar-swaync-toggle",
                  "on_right_click": "!ironbar-swaync-dnd",
                  "widgets": [
                    {
                      "type": "box",
                      "orientation": "horizontal",
                      "widgets": [
                        {
                          "type": "label",
                          "class": "notif-icon",
                          "label": "{{2000:ironbar-swaync-icon}}"
                        },
                        {
                          "type": "label",
                          "class": "notif-count",
                          "label": "{{2000:ironbar-swaync-count}}"
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      }
    }
  '';
}
