{ config, pkgs, lib, inputs, ... }:

let
  home-manager-src = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };
  
  spicetify-nix = inputs.spicetify-nix;
  niri-flake    = inputs.niri-flake;
  ironbar-flake = inputs.ironbar-flake;
in
{
  imports = [ 
    ./hardware-configuration.nix 
   #<home-manager/nixos>  
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  boot.kernelParams = [ 
    "nvidia-drm.modeset=1" 
    "drm.edid_firmware=HDMI-A-2:edid/edid.bin"
    "video=HDMI-A-2:1920x1080@120"
    "quiet"
    "splash"
    "intel_idle.max_cstate=1"
    "pcie_aspm=off"
    "intel_pstate=passive"
  ];

  boot.initrd.extraFiles = {
    "lib/firmware/edid/edid.bin".source = ./edid.bin;
  };
  
  programs.steam.enable = true;
  
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "msi-ec" ];

  programs.coolercontrol.enable = true;

  hardware.graphics.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly"; 
    fileSystems = [ "/" ];
  };

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
    users.remgr = { pkgs, inputs, ... }: {
      imports = [ 
        spicetify-nix.homeManagerModules.default 
        ironbar-flake.homeManagerModules.default
        ./neovim.nix
        ./ironbar.nix
        ./niri.nix
        ./zsh.nix
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
          name = "Zsombor Simon"; 
          email = "zsombor@remgr.dev"; 
        };
        signing = {
            key = "8D941BF242DA31D4";
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
        rustup gcc gnumake ruby odin ols nodejs_20 wireplumber
        (python3.withPackages (ps: [ ps.pip ]))
        btop gemini-cli spicetify-cli protonplus
        zotero onlyoffice-desktopeditors vlc appflowy blanket
        stirling-pdf davinci-resolve networkmanagerapplet
        awww waypaper

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
            echo ""
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
      ];

      home.sessionVariables = {
        NPM_CONFIG_PREFIX = "$HOME/.npm-global";
        GTK_CSD = "0"; 
      };
      home.sessionPath = [ "$HOME/.npm-global/bin" ];

      home.stateVersion = "26.05";
    }; 
  };

  programs.gamescope = {
      enable = true;
      capSysNice = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "/etc/sddm/themes/catppuccin-frappe-sapphire";
  };

  services.greetd = {
    enable = false;
    settings = {
      initial_session = {
        command = "niri-session";
        user = "remgr";
      };
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
  };
  
  services.flatpak.enable = true;
  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.videoDrivers = [ "nvidia" ];
  
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NIXOS_OZONE_WL = "1";
    __GL_SYNC_TO_VBLANK = "0";
    NIRI_DISABLE_SYNCOBJ = "1";
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
      intelBusId = "PCI:0:2:0"; 
      nvidiaBusId = "PCI:1:0:0"; 
    };
  };

  powerManagement.cpuFreqGovernor = "performance";

  programs.gamemode.enable = true;

  boot.kernel.sysctl."kernel.sysrq" = 1;

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

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.interfaces.enp3s0.useDHCP = true;
  nixpkgs.config.allowUnfree = true;

  programs.zsh = {
    enable = true;
    ohMyZsh = { enable = true; plugins = [ "git" ]; theme = "af-magic"; };
  };

  users.users.remgr = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "storage" ];
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
    libappindicator-gtk3 appimage-run

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

  services.pipewire = { 
    enable = true; 
    pulse.enable = true; 
    alsa.enable = true; 
    alsa.support32Bit = true; 
  };

  services.pcscd.enable = true;
  
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses; 
  };

  programs.ssh.startAgent = false;

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
  
  system.stateVersion = "26.05"; 
}
