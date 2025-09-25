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
  ];
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  networking.hostName = system-config.options.hostname; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];

  networking.wireguard.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
}
