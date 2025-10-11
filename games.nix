{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.games;
  steam-gamescope = pkgs.writeShellApplication {
    name = "steam-gamescope";
    runtimeInputs = [
      pkgs.udisks2
      pkgs.flatpak
    ];
    text = ''
      udisksctl mount -b /dev/vg0/games || true
      udisksctl mount -b /dev/disk/by-partlabel/Data || true

      # assume gamescope is installed via security wrapper
      gamescope --force-grab-cursor --steam -O DP-2 -- flatpak run com.valvesoftware.Steam -pipewire-dmabuf -tenfoot
    '';
  };
in
{
  options.games = {
    enable = lib.mkEnableOption "games";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      prismlauncher
      openjdk17
      mangohud

      steam-gamescope
      #gamescope
    ];

    services.displayManager.sessionPackages = [
      (
        (pkgs.writeTextDir "share/wayland-sessions/steam.desktop" ''
          [Desktop Entry]
          Name=Steam
          Comment=A digital distribution platform
          Exec=${steam-gamescope}/bin/steam-gamescope
          Type=Application
        '').overrideAttrs
        (_: {
          passthru.providedSessions = [ "steam" ];
        })
      )
    ];

    security.wrappers = {
      gamescope = {
        owner = "root";
        group = "root";
        source = "${pkgs.gamescope}/bin/gamescope";
        capabilities = "cap_sys_nice+pie";
      };
    };

    programs.steam = {
      enable = true;
    };

    programs.gamemode = {
      enable = true;
    };

    programs.firejail = {
      enable = true;
      wrappedBinaries = {
        steam = {
          executable = "${pkgs.steam}/bin/steam";
          profile = "${pkgs.firejail}/etc/firejail/steam.profile";
          #extraArgs = [
          ## Required for U2F USB stick
          #"--ignore=private-dev"
          ## Enforce dark mode
          #"--env=GTK_THEME=Adwaita:dark"
          ## Enable system notifications
          #"--dbus-user.talk=org.freedesktop.Notifications"
          #];
        };
      };
    };

    environment.etc = {
      "firejail/steam.local".text = ''
        noblacklist /run/media/alan/Games
        ignore seccomp
      '';
    };
  };
}
