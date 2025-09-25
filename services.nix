{
  system-config,
  pkgs,
  ...
}:
let
  lib = pkgs.lib;
in
{
  services.ollama = {
    enable = true;
    acceleration = if (system-config.options.gpu == "amd") then "rocm" else null;
  };
  systemd.services.ollama = {
    wantedBy = lib.mkForce [ ];
    stopIfChanged = lib.mkForce true;
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "alan";
    };
  };

  services.open-webui = {
    enable = true;
    package = pkgs.open-webui;
    port = 5000;
    environment = {
      HOME = "/var/lib/open-webui";
    };
  };
  systemd.services.open-webui = {
    wantedBy = lib.mkForce [ ];
    stopIfChanged = lib.mkForce true;
  };

  services.immich = {
    enable = true;
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
    settings = {
      UseDns = true;
      PasswordAuthentication = true;
    };
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = system-config.options.hostname;
        "netbios name" = system-config.options.hostname;
        "security" = "user";
        # note: localhost is the ipv6 localhost ::1
        "hosts allow" = "192.168.0. 127.0.0.1 localhost";
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
      };
    };
  };

  services.peerflix.enable = true;

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.ratbagd = {
    enable = true;
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

  services.lact = {
    enable = true;
    package = pkgs.lact;
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [ epson-escpr ];
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    extraConf = ''
      ServerAlias *
    '';
  };
}
