{ pkgs, inputs, ... }:

let
  auroraShell = inputs.aurora-shell;

  # Rust daemon that tracks the active MPRIS player and exposes it over DBus
  # as com.meismeric.aurora.MediaManager — required by the widget.
  auroramediad = pkgs.rustPlatform.buildRustPackage {
    pname = "auroramediad";
    version = "0.2.0";
    src = auroraShell + "/daemons/auroramediad";
    cargoLock.lockFile = auroraShell + "/daemons/auroramediad/Cargo.lock";
    nativeBuildInputs = [ pkgs.pkg-config ];
    meta.mainProgram = "auroramediad";
  };

  # Combine our standalone launcher with the mpris_player widget sources
  # from Aurora-Shell so they compile into a single executable.
  combinedSrc = pkgs.runCommand "aurora-mpris-src" {} ''
    mkdir -p $out/src
    cp ${./aurora-mpris}/standalone_main.c $out/
    cp ${./aurora-mpris}/meson.build $out/
    cp ${./aurora-mpris}/aurora-mpris-player.desktop $out/
    for f in main.c mpris.c lyrics.c utils.c mpris.h lyrics.h utils.h; do
      cp "${auroraShell}/widgets/mpris_player/src/$f" "$out/src/$f"
    done
  '';

  aurora-mpris-player = pkgs.stdenv.mkDerivation {
    pname = "aurora-mpris-player";
    version = "0.1.0";
    src = combinedSrc;
    nativeBuildInputs = with pkgs; [ meson ninja pkg-config wrapGAppsHook4 ];
    buildInputs = with pkgs; [ gtk4 libadwaita gtk4-layer-shell json-glib glib gsettings-desktop-schemas ];
  };
in
{
  home.packages = [ auroramediad aurora-mpris-player ];

  # Daemon that watches MPRIS players on the session bus and keeps track of
  # which one is active. The widget connects to it on startup.
  systemd.user.services.auroramediad = {
    Unit = {
      Description = "Aurora Media Daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${auroramediad}/bin/auroramediad";
      Restart = "on-failure";
      RestartSec = "2s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
