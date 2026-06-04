{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.myOptions;
  home-manager-src = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };
  
  spicetify-nix = inputs.spicetify-nix;
  niri-flake    = inputs.niri-flake;
  ironbar-flake = inputs.ironbar-flake;
  antigravity-nix = inputs.antigravity-nix;
  llm-agents      = inputs.llm-agents;
in
{
  imports = [ 
    ./hardware-configuration.nix 
   #<home-manager/nixos>  
  ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
    # Automatic Garbage Collection Setup
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Replace sudo with doas
  security.sudo.enable = false;
  security.doas.enable = true;
  security.doas.extraRules = [{
    users = [ "${cfg.username}" ];
    keepEnv = true;
    persist = true;
  }];

  boot.kernelParams = [ 
    "nvidia-drm.modeset=1" 
    "drm.edid_firmware=${cfg.monitor}:edid/edid.bin"
    "video=${cfg.monitor}:1920x1080@120"
    "quiet"
    "splash"
    "intel_pstate=passive"
  ];

  systemd.services.nvidia-undervolt = {
    description = "Lock NVIDIA GPU Clock to 1635MHz";
    after = [ "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -lgc 1635,1635";
      RemainAfterExit = true;
    };
  };

  boot.initrd.extraFiles = {
    "lib/firmware/edid/edid.bin".source = ./edid.bin;
  };
  
  programs.steam.enable = true;
  
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "msi-ec" ];

  programs.coolercontrol.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      nvidia-vaapi-driver
    ];
  };

  # BTRFS Optimization
  fileSystems."/".options = [ "compress=zstd" "noatime" "discard=async" ];

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly"; 
    fileSystems = [ "/" ];
  };

  systemd.tmpfiles.rules = [
    "d /home/.snapshots 0750 root root -"
  ];

  services.snapper = {
    configs = {
      home = {
        SUBVOLUME = "/home";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        HOURLY = "5";
        DAILY = "3";
        WEEKLY = "0";
        MONTHLY = "0";
        YEARLY = "0";
      };
    };
  };

  boot.kernelModules = [ "msi-ec" "ec_sys" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.msi-ec ];
  boot.extraModprobeConfig = ''
    options ec_sys write_support=1
  '';

  hardware.firmware = [
    (pkgs.runCommand "custom-edid" {} ''
      mkdir -p $out/lib/firmware/edid
      cp ${./edid.bin} $out/lib/firmware/edid/edid.bin
    '')
  ];
  
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  boot.plymouth.enable = true;

  programs.dconf.enable = true;
  services.dbus.packages = [ pkgs.gsettings-desktop-schemas pkgs.mcontrolcenter ];
  
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  boot.supportedFilesystems = [ "ntfs" ];

  services.upower.enable = true;

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak"; 
    users."${cfg.username}" = { pkgs, inputs, ... }: {
      
      _module.args = { inherit inputs; };

      imports = [
        spicetify-nix.homeManagerModules.default
        ironbar-flake.homeManagerModules.default
        ./neovim.nix
        ./ironbar.nix
        ./niri.nix
        ./zsh.nix
        ./antigravity.nix
        ./aurora-mpris.nix
      ];

      systemd.user.services.swww = {
        Unit = {
          Description = "Efficient animated wallpaper daemon for Wayland";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 1";
          ExecStart = "${pkgs.awww}/bin/awww-daemon";
          ExecStop = "${pkgs.awww}/bin/awww kill";
          Restart = "on-failure";
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

      systemd.user.services.i2p = {
        Unit = {
          Description = "Java I2P Router";
          After = [ "network.target" ];
        };
        Service = {
          ExecStart = "${pkgs.i2p}/bin/i2prouter";
          Restart = "on-failure";
        };
        Install = { WantedBy = [ "default.target" ]; };
      };

      systemd.user.services.swaync.Service.ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";

      services.swaync = {
        enable = true;
        settings = {
          positionX = "right";
          positionY = "top";
          layer = "overlay";
          control-center-layer = "overlay";
          control-center-margin-top = 10;
          control-center-margin-bottom = 10;
          control-center-margin-right = 10;
          control-center-margin-left = 10;
          timeout-low = 3;
          timeout = 3;
          timeout-critical = 3;
          notification-window-width = 500;
          keyboard-shortcuts = true;
          image-visibility = "when-available";
          transition-time = 200;
          hide-on-clear = false;
          hide-on-action = true;
        };
        style = ''
          * { font-family: JetBrainsMono Nerd Font, sans-serif; }
          .control-center { background: #2E3440; color: #D8DEE9; border: 2px solid #4C566A; border-radius: 8px; }
          .notification { background: #3B4252; border: 1px solid #4C566A; border-radius: 4px; padding: 4px; margin: 2px 4px; box-shadow: none; }
          .notification-content { padding: 4px; }
          .summary { font-size: 13px; font-weight: bold; color: #D8DEE9; margin-bottom: 2px; }
          .body { font-size: 12px; color: #E5E9F0; }
          .close-button { background: #BF616A; color: #2E3440; border-radius: 4px; padding: 2px; margin: 2px; }
          .close-button:hover { background: #D08770; }
          .widget-title { color: #88C0D0; font-size: 14px; font-weight: bold; padding: 8px; margin: 4px; }
          button { background: #4C566A; color: #D8DEE9; border-radius: 4px; padding: 4px; margin: 4px; border: none; }
          button:hover { background: #88C0D0; color: #2E3440; }
        '';
      };        

      programs.git = {
        enable = true;
        settings.user = { 
          name = cfg.fullName; 
          email = cfg.email; 
        };
        signing = {
            key = cfg.gitSigningKey;
            signByDefault = true;
        };
      };

      programs.kitty = {
          enable = true;
          
          settings = {
            # Core Settings
            hide_window_decorations = "yes";
            window_padding_width = 4;
            shell = "zsh";
            confirm_os_window_close = 0;
      
            # Theme: Nord
            foreground = "#D8DEE9";
            background = "#2E3440";
            selection_foreground = "#000000";
            selection_background = "#FFFACD";
            url_color = "#0087BD";
            cursor = "#81A1C1";
      
            # black
            color0 = "#3B4252";
            color8 = "#4C566A";
      
            # red
            color1 = "#BF616A";
            color9 = "#BF616A";
      
            # green
            color2 = "#A3BE8C";
            color10 = "#A3BE8C";
      
            # yellow
            color3 = "#EBCB8B";
            color11 = "#EBCB8B";
      
            # blue
            color4 = "#81A1C1";
            color12 = "#81A1C1";
      
            # magenta
            color5 = "#B48EAD";
            color13 = "#B48EAD";
      
            # cyan
            color6 = "#88C0D0";
            color14 = "#8FBCBB";
      
            # white
            color7 = "#E5E9F0";
            color15 = "#ECEFF4";
          };
        };

      programs.spicetify = 
        let
          spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
        in
        {
          enable = true;
          theme = spicePkgs.themes.catppuccin;
          colorScheme = "frappe";
          enabledCustomApps = with spicePkgs.apps; [
            marketplace
          ];            
        };

      gtk = {
        enable = true;
        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome-themes-extra;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
          gtk-error-bell = 0;
        };
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
          gtk-error-bell = 0;
        };
      };
      
      qt = {
        enable = true;
        platformTheme.name = "adwaita";
        style.name = "adwaita-dark";
      };
      
      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

      home.packages = with pkgs; [
        thunderbird strawberry goofcord kitty micro 
        prismlauncher weylus mullvad-vpn gh chromium 
        localsend libreoffice-fresh firefox swaynotificationcenter
        rustup gcc gnumake ruby odin ols nodejs_26 wireplumber
        (python3.withPackages (ps: [ ps.pip ]))
        btop gemini-cli spicetify-cli protonplus
        zotero onlyoffice-desktopeditors vlc appflowy blanket
        khal vdirsyncer
        stirling-pdf davinci-resolve networkmanagerapplet
        awww waypaper gale fzf teams-for-linux
        i2p mullvad-browser avahi wayvr xdg-desktop-portal-gnome 

        (pkgs.writeShellScriptBin "ironbar-swaync-toggle" ''
          ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw &
        '')
        (pkgs.writeShellScriptBin "ironbar-swaync-dnd" ''
          ${pkgs.swaynotificationcenter}/bin/swaync-client -d &
        '')

        (pkgs.writeShellScriptBin "ironbar-sys-details" ''
          CPU_TEMP=$(${pkgs.lm_sensors}/bin/sensors | ${pkgs.gnugrep}/bin/grep "Package id 0:" | ${pkgs.gawk}/bin/awk '{print $4}')
          CPU_FREQ=$(${pkgs.coreutils}/bin/cat /proc/cpuinfo | ${pkgs.gnugrep}/bin/grep "cpu MHz" | ${pkgs.coreutils}/bin/head -n1 | ${pkgs.gawk}/bin/awk '{print $4}')
          
          echo "CPU Temp: $CPU_TEMP"
          echo "CPU Speed: ''${CPU_FREQ%.*} MHz"
        '')
        (pkgs.writeShellScriptBin "ironbar-gpu-details" ''
          TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null || echo "N/A")
          LOAD=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "N/A")
          echo "Load: ''${LOAD}%  |  Temp: ''${TEMP}°C"
          echo "--- Apps Using GPU ---"
          nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader 2>/dev/null | ${pkgs.gawk}/bin/awk -F', ' '{print " • " $2 " (" $3 ")"}'
        '')
        (pkgs.writeShellScriptBin "ironbar-storage-details" ''
          DISK_INFO=$(${pkgs.coreutils}/bin/df -h / | ${pkgs.coreutils}/bin/tail -n 1)
          SIZE=$(echo "$DISK_INFO" | ${pkgs.gawk}/bin/awk '{print $2}')
          USED=$(echo "$DISK_INFO" | ${pkgs.gawk}/bin/awk '{print $3}')
          AVAIL=$(echo "$DISK_INFO" | ${pkgs.gawk}/bin/awk '{print $4}')
          USE_PERC=$(echo "$DISK_INFO" | ${pkgs.gawk}/bin/awk '{print $5}')
          echo "Root Partition (/):"
          echo "Total: $SIZE | Used: $USED ($USE_PERC) | Free: $AVAIL"
          echo ""
          echo "RAM Status:"
          ${pkgs.procps}/bin/free -h | ${pkgs.gnugrep}/bin/grep "Mem:" | ${pkgs.gawk}/bin/awk '{print "Total: " $2 " | Used: " $3 " | Free: " $4}'
        '')
        (pkgs.writeShellScriptBin "ironbar-services" ''
          echo "Main Services Status:"
          systemctl --user is-active ironbar awww swaync | ${pkgs.gawk}/bin/awk 'BEGIN {a[0]="ironbar"; a[1]="swaybg"; a[2]="swaync"} {print a[NR-1] ": " $0}'
          echo ""
          echo "System Load: $(${pkgs.coreutils}/bin/uptime | ${pkgs.gawk}/bin/awk -F'load average:' '{ print $2 }')"
        '')
        (pkgs.writeShellScriptBin "ironbar-music" ''
          STATUS=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null)
          if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
              ARTIST=$(${pkgs.playerctl}/bin/playerctl metadata artist)
              TITLE=$(${pkgs.playerctl}/bin/playerctl metadata title)
              echo "  󰎆 ''${TITLE} - ''${ARTIST}  "
          else
              echo ""
          fi
        '')
        (pkgs.writeShellScriptBin "ironbar-audio" ''
          VOL=$(${pkgs.pulseaudio}/bin/pactl get-sink-volume @DEFAULT_SINK@ | ${pkgs.gnugrep}/bin/grep -o '[0-9]*%' | ${pkgs.coreutils}/bin/head -n1)
          MIC=$(${pkgs.pulseaudio}/bin/pactl get-source-volume @DEFAULT_SOURCE@ | ${pkgs.gnugrep}/bin/grep -o '[0-9]*%' | ${pkgs.coreutils}/bin/head -n1)
          echo "  󰕾 ''${VOL}   ''${MIC}  "
        '')
        (pkgs.writeShellScriptBin "ironbar-bluetooth" ''
          DEV=$(${pkgs.wireplumber}/bin/wpctl status | ${pkgs.gnugrep}/bin/grep -i 'bluez' | ${pkgs.coreutils}/bin/head -n1 | ${pkgs.gnused}/bin/sed -E 's/.*[0-9]+\.\s*(.*)\s*\[.*/\1/')
          if [ -n "$DEV" ]; then
            echo "󰋋 ''${DEV}"
          else
            echo "󰂯"
          fi
        '')
        (pkgs.writeShellScriptBin "ironbar-blueman" ''
          ${pkgs.blueman}/bin/blueman-manager &
        '')
        # Connection status shown inside the bluetooth popup.
        (pkgs.writeShellScriptBin "ironbar-bt-status" ''
          BT=${pkgs.bluez}/bin/bluetoothctl
          if $BT show 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "Powered: yes"; then
            OUT="Bluetooth: On\n\n"
          else
            OUT="Bluetooth: Off\n\n"
          fi
          OUT="$OUT""Connected:\n"
          CONN=$($BT devices Connected 2>/dev/null | ${pkgs.gnused}/bin/sed -E 's/^Device [0-9A-F:]+ /  • /')
          if [ -n "$CONN" ]; then OUT="$OUT$CONN\n"; else OUT="$OUT  (none)\n"; fi
          OUT="$OUT""\nPaired:\n"
          PAIRED=$($BT devices Paired 2>/dev/null | ${pkgs.gnused}/bin/sed -E 's/^Device [0-9A-F:]+ /  • /')
          if [ -n "$PAIRED" ]; then OUT="$OUT$PAIRED\n"; else OUT="$OUT  (none)\n"; fi
          ${pkgs.coreutils}/bin/printf '%b' "$OUT" | ${pkgs.gnused}/bin/sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
        '')
        # Toggle the adapter power on/off.
        (pkgs.writeShellScriptBin "ironbar-bt-toggle" ''
          BT=${pkgs.bluez}/bin/bluetoothctl
          if $BT show 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "Powered: yes"; then
            $BT power off >/dev/null 2>&1
            ${pkgs.libnotify}/bin/notify-send "Bluetooth" "Powered off"
          else
            $BT power on >/dev/null 2>&1
            ${pkgs.libnotify}/bin/notify-send "Bluetooth" "Powered on"
          fi
        '')
        # Fuzzel chooser: lists known devices for quick connect/disconnect, with
        # an option to scan for new devices to pair. Selecting a device toggles
        # its connection; an unpaired device is paired + trusted + connected.
        (pkgs.writeShellScriptBin "ironbar-bt-menu" ''
          BT=${pkgs.bluez}/bin/bluetoothctl
          FUZZEL=${pkgs.fuzzel}/bin/fuzzel
          NOTIFY=${pkgs.libnotify}/bin/notify-send
          TMP=$(${pkgs.coreutils}/bin/mktemp)
          SCAN_LABEL="⟳  Scan for new devices…"

          $BT power on >/dev/null 2>&1

          list_to_file() {
            : > "$TMP"
            $BT devices 2>/dev/null | while read -r _ mac name; do
              [ -z "$mac" ] && continue
              info=$($BT info "$mac" 2>/dev/null)
              if ${pkgs.coreutils}/bin/printf '%s' "$info" | ${pkgs.gnugrep}/bin/grep -q "Connected: yes"; then
                ${pkgs.coreutils}/bin/printf '%s\t✓  %s  (connected)\n' "$mac" "$name" >> "$TMP"
              elif ${pkgs.coreutils}/bin/printf '%s' "$info" | ${pkgs.gnugrep}/bin/grep -q "Paired: yes"; then
                ${pkgs.coreutils}/bin/printf '%s\t•  %s\n' "$mac" "$name" >> "$TMP"
              else
                ${pkgs.coreutils}/bin/printf '%s\t+  %s  (new)\n' "$mac" "$name" >> "$TMP"
              fi
            done
          }

          show_menu() {
            { ${pkgs.coreutils}/bin/printf '%s\n' "$SCAN_LABEL"; ${pkgs.coreutils}/bin/cut -f2- "$TMP"; } \
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

          if [ -z "$CHOICE" ] || [ "$CHOICE" = "$SCAN_LABEL" ]; then ${pkgs.coreutils}/bin/rm -f "$TMP"; exit 0; fi
          MAC=$(${pkgs.gawk}/bin/awk -F'\t' -v c="$CHOICE" '$2==c{print $1; exit}' "$TMP")
          ${pkgs.coreutils}/bin/rm -f "$TMP"
          [ -z "$MAC" ] && exit 0

          info=$($BT info "$MAC" 2>/dev/null)
          if ${pkgs.coreutils}/bin/printf '%s' "$info" | ${pkgs.gnugrep}/bin/grep -q "Connected: yes"; then
            $BT disconnect "$MAC" >/dev/null 2>&1 && $NOTIFY "Bluetooth" "Disconnected"
          elif ${pkgs.coreutils}/bin/printf '%s' "$info" | ${pkgs.gnugrep}/bin/grep -q "Paired: yes"; then
            $BT connect "$MAC" >/dev/null 2>&1 && $NOTIFY "Bluetooth" "Connected" || $NOTIFY "Bluetooth" "Connection failed"
          else
            $NOTIFY "Bluetooth" "Pairing…"
            $BT pair "$MAC" >/dev/null 2>&1
            $BT trust "$MAC" >/dev/null 2>&1
            if $BT connect "$MAC" >/dev/null 2>&1; then $NOTIFY "Bluetooth" "Paired & connected"; else $NOTIFY "Bluetooth" "Pairing failed"; fi
          fi
        '')
        (pkgs.writeShellScriptBin "ironbar-swaync" ''
          COUNT=$(${pkgs.swaynotificationcenter}/bin/swaync-client -c 2>/dev/null || echo 0)
          DND=$(${pkgs.swaynotificationcenter}/bin/swaync-client -D 2>/dev/null || echo "false")
          if [ "$COUNT" = "" ]; then COUNT=0; fi

          if [ "$DND" = "true" ]; then
            echo "󰂛 $COUNT"
          elif [ "$COUNT" -gt 0 ]; then
            echo "󱅫 $COUNT"
          else
            echo "󰂚 "
          fi
        '')
        (pkgs.writeShellScriptBin "ironbar-swaync-icon" ''
          COUNT=$(${pkgs.swaynotificationcenter}/bin/swaync-client -c 2>/dev/null || echo 0)
          DND=$(${pkgs.swaynotificationcenter}/bin/swaync-client -D 2>/dev/null || echo "false")
          if [ "$COUNT" = "" ]; then COUNT=0; fi

          if [ "$DND" = "true" ]; then
            echo "󰂛"
          elif [ "$COUNT" -gt 0 ]; then
            echo "󱅫"
          else
            echo "󰂚"
          fi
        '')
        (pkgs.writeShellScriptBin "ironbar-swaync-count" ''
          COUNT=$(${pkgs.swaynotificationcenter}/bin/swaync-client -c 2>/dev/null || echo 0)
          if [ "$COUNT" = "" ]; then COUNT=0; fi
          if [ "$COUNT" -gt 0 ]; then
            echo "$COUNT"
          fi
        '')
      ];

      home.file.".cargo/config.toml".text = ''
        [build]
        rustc-wrapper = "${pkgs.sccache}/bin/sccache"

        [target.x86_64-unknown-linux-gnu]
        rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
      '';

      home.sessionVariables = {
        NPM_CONFIG_PREFIX = "$HOME/.npm-global";
        GTK_CSD = "0"; 
      };
      home.sessionPath = [ "$HOME/.npm-global/bin" ];

      xdg.configFile."khal/config".text = ''
        [calendars]
        [[default]]
        path = ~/.local/share/khal/calendars/
        color = cyan

        [sqlite]
        path = ~/.local/share/khal/khal.db

        [locale]
        timeformat = %H:%M
        dateformat = %d/%m/%Y
        datetimeformat = %d/%m/%Y %H:%M
        firstweekday = 0
      '';

      xdg.configFile."vdirsyncer/config".text = ''
        [general]
        status_path = "~/.local/share/vdirsyncer/status/"

        # Uncomment and fill in to add a remote calendar, then run:
        #   vdirsyncer discover && vdirsyncer sync

        # [pair personal_calendar]
        # a = "personal_local"
        # b = "personal_remote"
        # collections = ["from a", "from b"]

        # [storage personal_local]
        # type = "filesystem"
        # path = "~/.local/share/khal/calendars/"
        # fileext = ".ics"

        # [storage personal_remote]
        # type = "caldav"
        # url = "https://YOUR_CALDAV_SERVER/calendars/USERNAME/"
        # username = "USERNAME"
        # password = "PASSWORD"

        # Google Calendar (read-only iCal):
        # type = "http"
        # url = "https://calendar.google.com/calendar/ical/YOUR_ID/basic.ics"
      '';

      systemd.user.services.vdirsyncer = {
        Unit.Description = "vdirsyncer calendar sync";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
        };
      };

      systemd.user.timers.vdirsyncer = {
        Unit.Description = "vdirsyncer calendar sync timer";
        Timer = {
          OnBootSec = "2min";
          OnUnitActiveSec = "30min";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };

      home.stateVersion = cfg.stateVersion;
    };
  };

  programs.gamescope = {
      enable = true;
      capSysNice = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "/etc/sddm/themes/${cfg.sddmTheme}";
  };

  services.greetd = {
    enable = false;
    settings = {
      initial_session = {
        command = "niri-session";
        user = cfg.username;
      };
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
  };
  
  services.flatpak.enable = true;

  time.timeZone = cfg.timezone;
  i18n.defaultLocale = cfg.locale;

  services.xserver.videoDrivers = [ "nvidia" ];
  
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NIXOS_OZONE_WL = "1";
    __GL_SYNC_TO_VBLANK = "0";
    NVD_BACKEND = "direct";
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    nvidiaPersistenced = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    prime = { 
      offload.enable = true; 
      offload.enableOffloadCmd = true; 
      intelBusId = cfg.intelBusId; 
      nvidiaBusId = cfg.nvidiaBusId; 
    };
  };

  powerManagement.cpuFreqGovernor = "performance";
  hardware.cpu.intel.updateMicrocode = true;

  programs.gamemode.enable = true;
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 60;
    "vm.dirty_background_ratio" = 2;
    "kernel.nmi_watchdog" = 0;
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;
  
  boot.loader.limine.enable = true;
  boot.loader.limine.extraConfig = ''
    INTERFACE_SETTINGS=0
    TERM_BACKGROUND=2e3440
    TERM_FOREGROUND=d8dee9
    TERM_BACKDROP=2e3440
    TERM_FOREGROUND_BRIGHT=88c0d0
    TERM_BACKGROUND_BRIGHT=3b4252
    INTERFACE_BRANDING=NixOS | Nord
    INTERFACE_BRANDING_COLOUR=81a1c1
    INTERFACE_HELP_HIDDEN=yes
  '';
  boot.loader.limine.extraEntries = ''
    :Windows
        protocol: efi
        path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
  '';
  boot.loader.limine.style.wallpapers = [ ./nord.jpg ];
  boot.loader.limine.style.wallpaperStyle = "centered";
  
  boot.loader.efi.canTouchEfiVariables = true;

  system.activationScripts.secureBootSign = {
        text = ''
          echo "Signing boot files with sbctl..."
          ${pkgs.findutils}/bin/find /boot -type f \( -iname "*.efi" -o -iname "*bzImage*" -o -iname "*vmlinuz*" \) -print0 | \
            ${pkgs.findutils}/bin/xargs -0 -P $(${pkgs.coreutils}/bin/nproc) -I {} ${pkgs.sbctl}/bin/sbctl sign -s {} || true
    
          config_file="/boot/limine/limine.conf"
          if [ -f "$config_file" ]; then
            echo "Updating Limine hashes..."
            
            sed_script=$(${pkgs.coreutils}/bin/mktemp)
    
            ${pkgs.gnugrep}/bin/grep -oP '(?<=boot\(\):)/[^#\s]+#[0-9a-f]+' "$config_file" | \
            ${pkgs.findutils}/bin/xargs -P $(${pkgs.coreutils}/bin/nproc) -I {} ${pkgs.bash}/bin/bash -c '
              match="{}"
              path="''${match%#*}"
              old_hash="''${match#*#}"
              phys_path="/boot''${path}"
    
              if [ -f "$phys_path" ]; then
                new_hash=$(${pkgs.coreutils}/bin/b2sum "$phys_path" | ${pkgs.coreutils}/bin/cut -d" " -f1)
                
                if [ "$old_hash" != "$new_hash" ]; then
                  echo "Updating hash for $path" >&2
                  echo "s|''${path}#''${old_hash}|''${path}#''${new_hash}|g"
                fi
              fi
            ' > "$sed_script"
    
            if [ -s "$sed_script" ]; then
              ${pkgs.gnused}/bin/sed -f "$sed_script" "$config_file" > /tmp/limine_tmp.conf
              ${pkgs.coreutils}/bin/cat /tmp/limine_tmp.conf > "$config_file"
              ${pkgs.coreutils}/bin/rm /tmp/limine_tmp.conf
            fi
            ${pkgs.coreutils}/bin/rm -f "$sed_script"
          fi
        '';
      };

  networking.hostName = cfg.hostname;
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  networking.interfaces."${cfg.networkInterface}".useDHCP = true;
  networking.firewall.allowedTCPPorts = [ 5353 9757 ];
  networking.firewall.allowedUDPPorts = [ 5353 9757 ];
  nixpkgs.config.allowUnfree = true;

  programs.zsh = {
    enable = true;
    ohMyZsh = { enable = true; plugins = [ "git" ]; theme = "af-magic"; };
  };

  users.users."${cfg.username}" = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "storage" "lp" "scanner" ];
  };

  environment.systemPackages = with pkgs; [
    (prismlauncher.override {
      jdks = [ jdk8 jdk17 jdk21 jdk25 ];
    })
    quickshell catppuccin-sddm polkit_gnome
    wget neovim wl-clipboard fuzzel nautilus file-roller 
    loupe mpv pavucontrol playerctl pciutils usbutils lm_sensors libfido2
    git micro ntfs3g glib sbctl oreo-cursors-plus fastfetch xwayland-satellite
    mcontrolcenter blueman btrfs-assistant cliphist pinentry-gnome3
    mold sccache
    system-config-printer
    libappindicator-gtk3 appimage-run mangohud ffmpeg
    claude-code
    mcp-nixos

    gawk
    file
    xdg-utils
    libnotify

    (writeShellScriptBin "cliphist-fuzzel-img" ''
      #!/usr/bin/env bash
      export PATH="${lib.makeBinPath [ cliphist fuzzel wl-clipboard gawk file xdg-utils libnotify coreutils ]}:$PATH"
      
      # Paste the raw contents of cliphist-fuzzel-img from GitHub below:
    '')
  ];

  programs.ccache.enable = true;
  programs.nix-ld.enable = true;

  hardware.enableAllFirmware = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];
  
  programs.niri = {
    enable = true;
    package = niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.niri;
  };

  security.rtkit.enable = true;
  services.pipewire = { 
    enable = true; 
    pulse.enable = true; 
    alsa.enable = true; 
    alsa.support32Bit = true; 
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 2048;
      };
    };
    # Automatically make a newly connected device the default sink/source.
    # This is what flips audio to a bluetooth headset/speaker the moment it
    # connects (and back to built-in when it disconnects).
    extraConfig.pipewire-pulse."20-switch-on-connect" = {
      "pulse.cmd" = [
        { cmd = "load-module"; args = "module-switch-on-connect"; flags = [ ]; }
      ];
    };
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      gutenprintBin
      hplip
      cups-filters
      epson-escpr
      brlaser
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;    
    };
  };

  services.pcscd.enable = true;
  services.dbus.implementation = "broker";
  services.thermald.enable = true;
  services.irqbalance.enable = true;
  services.scx = {
    enable = true;
    scheduler = "scx_rustland";
  };
  
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses; 
  };

  programs.ssh.startAgent = false;

  services.journald.extraConfig = "SystemMaxUse=50M";

  services.undervolt = {
    enable = true;
    coreOffset = -125;
    uncoreOffset = -125;
    gpuOffset = -6; 
    temp = 90;
  };

  services.xserver.screenSection = ''
    Option "Coolbits" "28"
  ''; 
  
  system.stateVersion = cfg.stateVersion; 
}
