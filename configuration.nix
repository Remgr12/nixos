{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.myOptions;
  home-manager-src = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };
  
  spicetify-nix = inputs.spicetify-nix;
  niri-flake    = inputs.niri-flake;
  noctalia-shell = inputs.noctalia-shell;
  antigravity-nix = inputs.antigravity-nix;
  llm-agents      = inputs.llm-agents;
  sops-nix        = inputs.sops-nix;
in
{
  imports = [ 
    ./hardware-configuration.nix 
   #<home-manager/nixos>
    ./aeroshell.nix
    sops-nix.nixosModules.sops
  ];

  # --- Secret Management ---
  sops.defaultSopsFile = ./secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]; 

  sops.secrets."davfs2_password" = {
    path = "/etc/davfs2/secrets";
    mode = "0600";
    owner = "root";
  };

  # --- WebDAV Mount ---
  services.davfs2.enable = true;
  fileSystems."/mnt/mailbox" = {
    device = "https://dav.mailbox.org/servlet/webdav.infostore/";
    fsType = "davfs";
    options = [ 
      "rw" 
      "uid=1000"
      "noauto" 
      "x-systemd.automount" 
    ];
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
      # Faster fetches: avoid the "download buffer is full" stall, open more
      # parallel connections, fail fast on dead substituters.
      download-buffer-size = 268435456; # 256 MiB
      http-connections = 50;
      connect-timeout = 5;
      builders-use-substitutes = true;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        # "https://cache.garnix.io"
        "https://noctalia.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
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
    # keepEnv = false: don't carry the user's full environment into root (closes
    # the LD_PRELOAD/PATH privesc surface). nixos-rebuild --flake doesn't need it.
    # If an env-dependent `doas <cmd>` breaks, add it to setEnv rather than
    # re-enabling keepEnv wholesale.
    keepEnv = false;
    persist = true;
  }];

  nix.extraOptions = ''
    !include /etc/secret/github.conf
  '';

  boot.kernelParams = [ 
    "nvidia-drm.modeset=1" 
    "drm.edid_firmware=${cfg.monitor}:edid/edid.bin"
    "video=${cfg.monitor}:1920x1080@120"
    "quiet"
    "splash"
    "intel_pstate=passive"
  ];
  
  programs.aeroshell = {
    enable = true;
    fonts.segoe.enable = true;
    polkit.enable = true;
    aerothemeplasma = {
      enable = true;
      sddm.enable = false;     # Disabled to protect your custom SDDM theme
      plymouth.enable = false; # Disabled to protect your existing Plymouth setup
    };
  };

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
      lsfg-vk
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
  security.polkit.enable = true;
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
        noctalia-shell.homeModules.default
        ./neovim.nix
        ./copyq.nix
        ./niri.nix
        ./zsh.nix
        ./antigravity.nix
        ./aurora-mpris.nix
        ];

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

      programs.noctalia = {
        enable = true;
        systemd.enable = false;
        settings = {
          shell.font = "JetBrainsMono Nerd Font";
          theme = {
            mode = "dark";
            source = "builtin";
            builtin = "Nord";
          };
          wallpaper = {
            enabled = true;
            default.path = "/etc/nixos/nord.jpg";
          };
        };
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
        localsend libreoffice-fresh firefox
        rustup gcc gnumake ruby odin ols nodejs_26 wireplumber
        (python3.withPackages (ps: [ ps.pip ]))
        btop gemini-cli spicetify-cli protonplus
        zotero onlyoffice-desktopeditors vlc appflowy blanket
        telegram-desktop
        stirling-pdf davinci-resolve networkmanagerapplet
        gale fzf teams-for-linux
        i2p mullvad-browser avahi wayvr xdg-desktop-portal-gnome
    steam-tui steamcmd lutris blockbench aseprite
        gnome-calculator dbeaver-bin zed-editor
    cemu heroic
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

      home.stateVersion = cfg.stateVersion;
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    "googleearth-pro-7.3.7.1155"
  ];
  
  services.desktopManager.plasma6.enable = true;

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    oxygen
    kate
    elisa
    khelpcenter
  ];
  
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
    DOTNET_ROOT = "${pkgs.dotnetCorePackages.sdk_9_0}";
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

  powerManagement.cpuFreqGovernor = "schedutil";
  hardware.cpu.intel.updateMicrocode = true;

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;                 # bump game process priority
        desiredgov = "performance";  # pin CPU to performance governor while gaming
        igpu_desiredgov = "performance";
      };
      cpu = {
        park_cores = "no";           # 6c/12t non-hybrid: keep all cores live
        pin_cores = "yes";           # pin the game to physical cores
      };
    };
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    # zram is RAM-backed: swap into it aggressively instead of dropping hot
    # page cache, and disable swap read-ahead (zram is random-access).
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    # Lower dirty thresholds: with 16G RAM dirty_ratio=60 buffered ~9G before
    # forcing synchronous writeback (multi-second stalls). NVMe doesn't need it.
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "kernel.nmi_watchdog" = 0;
    # Moderate hardening (no gaming/debug impact): hide kernel pointers from
    # unprivileged users and restrict dmesg to root. `doas dmesg`/perf as root
    # still work.
    "kernel.kptr_restrict" = 1;
    "kernel.dmesg_restrict" = 1;
  };

  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  
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

  programs.java = {
    enable = true;
    package = pkgs.temurin-bin-26;
  };

  environment.shellAliases = {
  java8 = "${pkgs.temurin-bin-8}/bin/java";
  javac8 = "${pkgs.temurin-bin-8}/bin/javac";
  
  java17 = "${pkgs.temurin-bin-17}/bin/java";
  javac17 = "${pkgs.temurin-bin-17}/bin/javac";
  
  java21 = "${pkgs.temurin-bin-21}/bin/java";
  javac21 = "${pkgs.temurin-bin-21}/bin/javac";
  
  java25 = "${pkgs.temurin-bin-25}/bin/java";
  javac25 = "${pkgs.temurin-bin-25}/bin/javac";
  
  java26 = "${pkgs.temurin-bin-26}/bin/java";
  javac26 = "${pkgs.temurin-bin-26}/bin/javac";
};

  environment.systemPackages = with pkgs; [
    (prismlauncher.override {
      jdks = [ jdk8 jdk17 jdk21 jdk25 ];
    })
    quickshell catppuccin-sddm polkit_gnome
    wget neovim wl-clipboard fuzzel nautilus file-roller
    loupe mpv pavucontrol playerctl pciutils usbutils lm_sensors libfido2
    git micro ntfs3g glib sbctl oreo-cursors-plus fastfetch xwayland-satellite
    mcontrolcenter blueman btrfs-assistant cliphist pinentry-gnome3 simple-scan
    mold sccache
    system-config-printer
    libappindicator-gtk3 appimage-run mangohud ffmpeg
    claude-code
    mcp-nixos lsfg-vk-ui
    googleearth-pro freetube
    qbittorrent-enhanced
    docker simple-scan 
    nim nimble unzip
    godot-mono dotnetCorePackages.sdk_9_0 python3 nodejs go gcc gnumake ruby odin ols
        (python3.withPackages (ps: [ ps.pip ]))
    kotlin 
    temurin-bin-8 temurin-bin-17 temurin-bin-21 temurin-bin-25 temurin-bin-26 gradle
    

    gawk
    file
    xdg-utils
    libnotify
  ];

  programs.ccache.enable = true;
  programs.nix-ld.enable = true;
  programs.appimage.binfmt = true;

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
    # scx_lavd: Latency-criticality Aware Virtual Deadline scheduler. Purpose-built
    # for gaming/interactive desktop latency, runs in-kernel (BPF) rather than the
    # userspace round-trip of scx_rustland. Lower overhead, better frame pacing.
    scheduler = "scx_lavd";
  };
  
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
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
