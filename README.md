# Nord Minimal NixOS Flake

A modular and highly configurable NixOS configuration featuring a Nord theme aesthetic and modern Wayland components.

## Features
- **Niri Desktop Manager**: Using a custom fork with tearing support.
- **Ironbar**: A modern, highly customizable bar for Wayland.
- **Home Manager**: Integrated for managing user-specific configurations.
- **Spicetify**: Themed Spotify client.
- **Modular Options**: Centralized configuration via `options.nix`.

## Project Structure
- `flake.nix`: Entry point for the configuration and inputs.
- `options.nix`: **Start here** Contains all user-specific and hardware-specific options defined with `mkOption`.
- `configuration.nix`: Main system configuration, referencing values from `options.nix`.
- `ironbar.nix`: Configuration for the Ironbar Wayland bar.
- `niri.nix`: Configuration for the Niri compositor.
- `neovim.nix`: Nixvim-based Neovim configuration.
- `zsh.nix`: Zsh shell configuration and aliases.

## Customization
Most common settings can be changed in `options.nix` without touching the main configuration files:
- **User**: Username, full name, email, and GPG signing key.
- **System**: Hostname, timezone, and locale.
- **Hardware**: Primary monitor name, GPU PCI bus IDs (for NVIDIA Prime), and network interface name.
- **Theme**: SDDM theme selection.

## Installation & Rebuild
To apply changes to your system, use the following command:
```bash
sudo nixos-rebuild switch --flake .#nixos
```

Alternatively, use the provided alias if you are using the Zsh configuration:
```bash
rebuild
```
