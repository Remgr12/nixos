{ pkgs, inputs, ... }:

let
  ironbar-flake = inputs.ironbar-flake;
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
      ExecStart = "${ironbar-flake.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/ironbar";
      Restart = "on-failure";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  programs.ironbar = {
    enable = true;
    systemd = false; 
    package = ironbar-flake.packages.${pkgs.stdenv.hostPlatform.system}.default;
    
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
      
      .background { background-color: rgba(46, 52, 64, 0.9); }
      button, label { box-shadow: none; background: none; background-color: rgba(0, 0, 0, 0); color: #d8dee9; padding: 0; margin: 0; }
      button:hover { background-color: rgba(59, 66, 82, 0.9); }
      #bar { background-color: rgba(46, 52, 64, 0.9); background-image: none; box-shadow: none; padding: 0; }
      .popup { background-color: rgba(59, 66, 82, 0.9); border: 1px solid rgba(76, 86, 106, 0.9); border-radius: 4px; padding: 0; }

      scale trough { border-radius: 4px; background-color: #4C566A; min-height: 4px; }
      scale trough highlight { border-radius: 4px; background-color: #88C0D0; }
      scale value { color: #d8dee9; }

      /* Left Side */
      .workspaces .item { margin: 0 2px; padding: 0 6px; }
      .workspaces .item.focused { box-shadow: inset 0 -2px #88C0D0; background-color: rgba(59, 66, 82, 0.9); }
      .workspaces .item:hover { box-shadow: inset 0 -2px #4C566A; }
      .clock-mod { padding: 0 10px; margin-left: 10px; font-weight: bold; color: #D8DEE9; }
      .bluetooth-mod { margin-left: 12px; font-weight: bold; color: #81A1C1; padding: 0 6px; }

      /* Center */
      .music { color: #8FBCBB; font-weight: bold; }

      /* Right Side - Performance Modules tightly grouped */
      .cpu-mod, .ram-mod, .gpu-mod { padding: 0 6px; border-radius: 4px; transition: background-color 0.2s; }
      .cpu-mod:hover, .ram-mod:hover, .gpu-mod:hover { background-color: rgba(59, 66, 82, 0.9); }
      .cpu-text, .cpu-text label { color: #A3BE8C; font-weight: bold; }
      .ram-text, .ram-text label { color: #EBCB8B; font-weight: bold; }
      .gpu-icon { font-weight: bold; color: #CBA6F7; font-size: 15px; }
      .gpu-text { font-weight: bold; color: #CBA6F7; }

      /* Right Side - Distanced elements */
      .vol-mod { margin-left: 10px; padding: 0 6px; font-weight: bold; color: #88C0D0; border-radius: 4px; }
      .starship-mod { margin-left: 10px; padding: 0 6px; border-radius: 4px; transition: background-color 0.2s; }
      .starship-icon { font-size: 16px; }
      .notif-mod { margin-left: 10px; padding: 0 10px; font-size: 14px; }

      /* Popups */
      .popup-text, .popup-text label { font-family: JetBrainsMono Nerd Font, monospace; }
      .tray { padding: 8px 12px; }
      .tray .item { margin: 0 4px; padding: 4px; }
      .tray menuitem { padding: 4px 8px; margin: 2px 0; }
      .popup-clock .calendar-clock { color: #d8dee9; font-size: 2em; padding-bottom: 4px; }
      .popup-clock .calendar .header { padding-top: 8px; border-top: 1px solid rgba(76, 86, 106, 0.9); font-size: 1.2em; }
      .popup-clock .calendar:selected { background-color: rgba(136, 192, 208, 0.9); color: #2E3440; }
    '';
  };

  xdg.configFile."ironbar/config.json".text = ''
    {
      "monitors": {
        "HDMI-A-2": {
          "name": "main-bar",
          "popup_autohide": true,
          "anchor_to_edges": true,
          "position": "top",
          "height": 25,
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
              "format": "%d/%m/%Y %H:%M"
            },
            {
              "type": "custom",
              "class": "bluetooth-mod",
              "bar": [
                {
                  "type": "label",
                  "label": "{{2000:ironbar-bluetooth}}"
                }
              ]
            }
          ],
          "center": [
            {
              "type": "music",
              "player_type": "mpris",
              "format": "{title} - {artist}",
              "on_click_left": "playerctl play-pause",
              "on_scroll_up": "playerctl next",
              "on_scroll_down": "playerctl previous"                  
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
                  "label": "{{2000:ironbar-swaync}}",
                  "on_click": "!ironbar-swaync-toggle",
                  "on_right_click": "!ironbar-swaync-dnd"
                }
              ]
            }
          ]
        }
      }
    }
  '';
}
