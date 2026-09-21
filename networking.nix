{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The only things the libvirt guest may reach on this host. Everything else
  # it aims at the LAN -- including the rest of this host -- is dropped below,
  # so a port that is not listed here does not exist as far as VibeVM is
  # concerned. Keep the log tags short: nftables truncates long prefixes.
  guestAllowedHostPorts = [
    {
      ports = "11434-11435";
      tag = "llm";
    }
  ]
  ++ lib.optional config.my.services.claudeMcp.enable {
    # The read-only MCP proxy. Deliberately derived from the option rather
    # than repeated, so the hole and the listener cannot drift apart.
    ports = toString config.my.services.claudeMcp.port;
    tag = "mcp";
  };

  libvirtIsolationRules = (map
    (allowed: {
      "@family" = "ipv4";
      "@priority" = "100";
      destination = {
        "@address" = "192.168.100.1/32";
      };
      port = {
        "@port" = allowed.ports;
        "@protocol" = "tcp";
      };
      log = {
        "@prefix" = "GUEST -> HOST ${allowed.tag} ";
        "@level" = "info";
      };
      accept = "";
    })
    guestAllowedHostPorts
  )
  ++ (map
    (prefix: {
      "@family" = "ipv4";
      "@priority" = "1000";
      destination = {
        "@address" = prefix;
      };
      log = {
        "@prefix" = "GUEST -> LAN blocked ";
        "@level" = "warning";
      };
      drop = "";
    })
    [
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
    ]
  );
in
{
  environment.systemPackages = with pkgs; [
    dig
    bind
    iproute2
    curl
    socat
    nmap
    ethtool
    mitmproxy
    networkmanagerapplet
    wireguard-tools
    tcpdump
    traceroute
    #conntrack-tools
    firewalld
    firewalld-gui
  ];
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  networking.hostName = config.my.hostname; # Define your hostname.

  # Enable networking
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
      };
    };
  };

  #systemd.services."systemd-resolved".environment.SYSTEMD_LOG_LEVEL = "debug";

  networking.wireguard.enable = true;

  networking.firewall.enable = false;
  environment.etc."firewalld/policies/block-guest-to-lan.xml".source =
    let
      format = pkgs.formats.xml { };
    in
    format.generate "firewalld-policy-block-guest-to-lan.xml" {
      policy = {
        "@version" = "1.0";
        "@target" = "ACCEPT";

        ingress-zone = {
          "@name" = "lan-protected";
        };
        egress-zone = {
          "@name" = "ANY";
        };
        rule = libvirtIsolationRules;

      };
    };
  services.firewalld = {
    enable = true;
    zones.trusted.interfaces = [
      "zt-personal"
    ];

    zones.chyps = {
      target = "DROP";
      services = [ "samba" ];
      interfaces = [ "chyps" ];
    };
    zones.lan-protected = {
      target = "ACCEPT";
      services = [ ];
      rules = libvirtIsolationRules;
    };
    settings = {
      DefaultZone = "drop";
    };
  };

  networking.nftables.enable = true;
}
