{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./services/llm.nix
    ./services/claude-mcp.nix
  ];

  services.immich = {
    enable = config.my.roles.mainPc;
    package = pkgs.immich;
    port = 2283;
    host = "0.0.0.0";
  };
  #systemd.services.immich-server = {
  #wantedBy = lib.mkForce [ ];
  #stopIfChanged = lib.mkForce true;
  #};

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
    };
  };

  systemd.services.sshd.wantedBy = lib.mkIf (!config.my.roles.mainPc) (lib.mkForce [ ]);

  services.samba = {
    enable = config.my.roles.mainPc;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = config.my.hostname;
        "netbios name" = config.my.hostname;
        "security" = "user";
        # note: localhost is the ipv6 localhost ::1
        "hosts allow" = "10.1.0. 192.168.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      "miri" = {
        "path" = "/huge-storage/miri-network-share";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "miri";
        "force group" = "users";
        "valid users" = "miri";
      };
      "metatron-alan" = {
        "path" = "/huge-storage/metatron-alan-network-share";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "alan";
        "force group" = "users";
        "valid users" = "chyps-alan";
      };
    };
  };

  services.peerflix.enable = config.my.roles.mainPc;

  services.samba-wsdd = {
    enable = config.my.roles.mainPc;
  };

  services.jellyfin = {
    enable = config.my.roles.mainPc;
    user = "alan";
  };

  services.ratbagd = {
    enable = config.my.roles.mainPc;
    package = pkgs.libratbag;
  };

  services.flatpak.enable = true;

  services.zerotierone = {
    enable = true;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };
  services.pulseaudio.enable = false;
  services.upower.enable = true;
  services.gvfs.enable = true;
  services.locate.package = pkgs.mlocate;
  services.udisks2.enable = true;

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.local && action.id == "org.freedesktop.udisks2.filesystem-mount-system") {
        return polkit.Result.YES;
      }
      if (subject.local && action.id == "org.freedesktop.udisks2.filesystem-mount-other-seat") {
        return polkit.Result.YES;
      }
    });
  '';

  services.lact = {
    enable = config.my.roles.mainPc;
    package = pkgs.lact;
  };

  services.printing = {
    enable = config.my.roles.mainPc;
    drivers = with pkgs; [ epson-escpr ];
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    extraConf = ''
      ServerAlias *
    '';
  };

  networking.hosts = lib.mkIf config.my.roles.mainPc {
    "127.0.0.2" = [
      "cups.home"
      "immich.home"
      "jellyfin.home"
    ];
  };

  powerManagement.cpuFreqGovernor = lib.mkIf config.my.roles.mainPc "performance";

  services.sunshine = {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
    settings = {
      sunshine_name = "alan-desktop-nixos";
    };
  };
  hardware.uinput.enable = true;

  services.udev.packages = [
  ];

  #services.avahi.enable = true;
}
