{ pkgs, system-config, ... }:
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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
}
