{ lib, ... }:

with lib;

{
  options = {
    myOptions = {
      username = mkOption {
        type = types.str;
        default = "remgr";
        description = "The primary username for the system";
      };

      hostname = mkOption {
        type = types.str;
        default = "nixos";
        description = "The hostname of the system";
      };

      fullName = mkOption {
        type = types.str;
        default = "Zsombor Simon";
        description = "The full name of the user";
      };

      email = mkOption {
        type = types.str;
        default = "zsombor@remgr.dev";
        description = "The email address of the user";
      };

      stateVersion = mkOption {
        type = types.str;
        default = "26.05";
        description = "The state version for NixOS and Home Manager";
      };

      timezone = mkOption {
        type = types.str;
        default = "Europe/Vienna";
        description = "The system timezone";
      };

      locale = mkOption {
        type = types.str;
        default = "en_US.UTF-8";
        description = "The system default locale";
      };

      gitSigningKey = mkOption {
        type = types.str;
        default = "8D941BF242DA31D4";
        description = "The GPG key ID for signing git commits";
      };

      monitor = mkOption {
        type = types.str;
        default = "HDMI-A-2";
        description = "The name of the primary monitor";
      };

      intelBusId = mkOption {
        type = types.str;
        default = "PCI:0:2:0";
        description = "The PCI bus ID for the Intel GPU";
      };

      nvidiaBusId = mkOption {
        type = types.str;
        default = "PCI:1:0:0";
        description = "The PCI bus ID for the NVIDIA GPU";
      };

      networkInterface = mkOption {
        type = types.str;
        default = "enp3s0";
        description = "The primary network interface name";
      };

      sddmTheme = mkOption {
        type = types.str;
        default = "catppuccin-frappe-sapphire";
        description = "The SDDM theme name";
      };
    };
  };
}
