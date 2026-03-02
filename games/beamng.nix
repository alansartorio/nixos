{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.games;
  libraryPath = pkgs.lib.makeLibraryPath [
    pkgs.fontconfig
    pkgs.freetype
    pkgs.glib
    pkgs.nss
    pkgs.nspr
    pkgs.dbus
    pkgs.atk
    pkgs.cups
    pkgs.libdrm
    pkgs.libX11
    pkgs.libXcomposite
    pkgs.libXdamage
    pkgs.libXext
    pkgs.libXfixes
    pkgs.libXrandr
    pkgs.libxcb
    pkgs.libgbm
    pkgs.libxkbcommon
    pkgs.pango
    pkgs.cairo
    pkgs.alsa-lib

    pkgs.vulkan-loader
    pkgs.libglvnd
  ];
  launch-beamng = pkgs.writeShellApplication {
    name = "launch-beamng";
    text = ''
      set -x
      export LD_LIBRARY_PATH="${libraryPath}:$LD_LIBRARY_PATH"

      cmd=$(printf '%q ' "$@")
      cmd=$(sed -E 's#/[^ ]*/steam-launch-wrapper -- .* ([^ ]*/proton waitforexitandrun)##' <<< "$cmd")
      cmd=$(sed -E 's#BeamNG\.drive\.exe#BinLinux/BeamNG.drive.x64#' <<< "$cmd")

      eval "$cmd"
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      launch-beamng
    ];
  };
}
