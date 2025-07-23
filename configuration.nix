# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  inputs,
  system,
  system-config,
  pkgs,
  ...
}:
let
  lib = pkgs.lib;
in
{
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  environment.localBinInPath = true;
  imports = [
    # include nixos-avf modules
    <nixos-avf/avf>
  ];

  systemd.tmpfiles.rules = lib.optionals (system-config.options.gpu == "amd") [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  environment.etc."libinput/local-overrides.quirks".text = ''
    [Logitech G502]
    MatchName=Logitech G502
    AttrEventCode=-REL_WHEEL_HI_RES;-REL_HWHEEL_HI_RES;
  '';

  networking.hostName = system-config.options.hostname; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  # networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Argentina/Buenos_Aires";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.gvfs.enable = true;
 
  # Change default user
  avf.defaultUser = "alan";
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.alan = {
    isNormalUser = true;
    description = "Alan Sartorio";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "wireshark"
    ];
    packages = with pkgs; [ ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Utils
    openssl
    age
    jq
    alsa-utils
    brightnessctl
    zip
    dig
    bind
    iproute2
    curl

    # Theming
    git
    neovim

    # LSPs
    lua-language-server
    jdt-language-server
    roslyn-ls
    typescript-language-server
    nixd
    terraform-ls
    terraform

    # Developer tools
    rustup # install rustanalyzer after
    nixfmt-rfc-style
    luajit
    luarocks

    # Environment
    chezmoi

    # Required for my eww config
    pamixer
    socat
    rust-script

    kdePackages.kdeconnect-kde
    (dotnetCorePackages.combinePackages [
      dotnetCorePackages.dotnet_8.sdk
      dotnetCorePackages.dotnet_8.aspnetcore
      dotnetCorePackages.dotnet_9.sdk
    ])
    csharprepl
    gcc
    cmake
    pkg-config
    ntfs3g
    gnumake
    polkit_gnome
    pulseaudio
    htop
    btop
    ripgrep
    ncdu
    mlocate
    dive
    docker-compose
    erdtree
    killall

    gnupg

    python3
    pyright
    go
    gopls

    nodejs_latest
    ethtool

    nmap
    ffmpeg

    sshpass
    xxd
    postgresql
    immich-go
    exiftool
    smartmontools
  ];

  users.groups.libvirtd.members = [ "alan" ];

  services.locate.package = pkgs.mlocate;
  virtualisation.docker.enable = true;

  users.defaultUserShell = pkgs.zsh;
  programs.zsh = {
    enable = true;
    shellAliases = {
      clockin-sync = ''
        clockin exec '( git add . && git commit -m "sync" ) || git pull --rebase && git push'
      '';
      ftphere = ''
        docker run --rm -p 20-21:20-21 -p 65500-65515:65500-65515 -v $(pwd):/var/ftp:ro metabrainz/docker-anon-ftp
      '';
    };
  };
  services.zerotierone = {
    enable = true;
  };
  networking.wireguard.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = lib.mkForce false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = system-config.options.stateVersion; # Did you read the comment?

}
