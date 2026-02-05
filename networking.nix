{
  pkgs,
  system-config,
  ...
}:
let
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

  networking.hostName = system-config.options.hostname; # Define your hostname.

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

  networking.wireguard.enable = true;

  networking.firewall.enable = false;
  services.firewalld = {
    enable = true;
    zones.trusted.interfaces = [
      "zt-personal"
    ];
    settings = {
      DefaultZone = "drop";
    };
  };

  networking.nftables.enable = true;
}
