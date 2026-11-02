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
  minecraft-notifier-script =
    pkgs.writers.writePython3Bin "minecraft-notifier"
      {
        libraries = pypkgs: [
          pypkgs.mcstatus
          pypkgs.notify2
        ];
        doCheck = false;
      }
      ''
        from mcstatus import JavaServer
        import notify2
        import sys
        from time import sleep

        host = sys.argv[1]
        server = JavaServer.lookup(host)


        def sendmessage(title, message):
            notify2.init("Test")
            notice = notify2.Notification(title, message)
            notice.show()


        last_count = None
        while True:
            try:
                status = server.status()
                count = status.players.online
                print(f"player count: {count}")
                if count != last_count:
                    sendmessage("server count changed", f"{last_count} -> {count}")
                last_count = count
            except Exception as e:
                print(e)
            sleep(20)
      '';
in
{
  imports = [
    ./games/beamng.nix
    ./games/shooterspool.nix
  ];

  options.games = {
    enable = lib.mkEnableOption "games";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      openjdk17
      mangohud

      steam-gamescope
      #gamescope
      minecraft-notifier-script

      depotdownloader
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
      enableRenice = true;
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
        prismlauncher = {
          executable = "${pkgs.prismlauncher}/bin/prismlauncher";
        };
      };
    };

    environment.etc = {
      "firejail/steam.local".text = ''
        ignore novideo

        whitelist ''${HOME}/.config/openxr
        noblacklist /run/media/alan/Games

        ignore seccomp
      '';
    };
  };
}
