{ config, pkgs, inputs, osConfig, ... }:

let
  cfg = osConfig.myOptions;
  ironbar-flake = inputs.ironbar-flake;
  ironbarPkg = ironbar-flake.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
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
