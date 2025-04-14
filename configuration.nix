# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-97440c40-cde6-47b0-97ba-bb3ac82b6e3c".device =
    "/dev/disk/by-uuid/97440c40-cde6-47b0-97ba-bb3ac82b6e3c";
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Argentina/Buenos_Aires";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_AR.UTF-8";
    LC_IDENTIFICATION = "es_AR.UTF-8";
    LC_MEASUREMENT = "es_AR.UTF-8";
    LC_MONETARY = "es_AR.UTF-8";
    LC_NAME = "es_AR.UTF-8";
    LC_NUMERIC = "es_AR.UTF-8";
    LC_PAPER = "es_AR.UTF-8";
    LC_TELEPHONE = "es_AR.UTF-8";
    LC_TIME = "es_AR.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.alan = {
    isNormalUser = true;
    description = "Alan Sartorio";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [ ];
  };

  fonts.packages = with pkgs; [
    #nerd-fonts.symbols-only
    material-design-icons
    nerd-fonts.roboto-mono
  ];
  fonts.fontconfig.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Utils
    openssl
    age
    jq
    socat
    alsa-utils
    brightnessctl
    zip
    dig

    # Theming
    rose-pine-hyprcursor
    wl-clipboard
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
    swaybg
    dunst
    alacritty
    eww
    kdePackages.dolphin
    kdePackages.ark
    #firefox
    pavucontrol
    rofi-wayland
    thunderbird
    kdePackages.kdenlive

    gcc
    cmake
    pkg-config
    ntfs3g
    gnumake
    polkit_gnome
    pulseaudio
    networkmanagerapplet
    htop
    btop
    ripgrep
    ncdu
    mlocate
    firefoxpwa
    chromium
    xorg.libxcb
    wayland
    #kdePackages.kservice
    libsForQt5.kservice
    dive
    #podman-tui
    docker-compose
    #podman-compose
    erdtree
    gnuplot

    vmpk
    fluidsynth
    soundfont-fluid
    python3
    love

    qt6.qtwayland
    mpv
    oculante
    nodejs_23

    gimp
    inkscape

    vulkan-tools
    nmap
  ];

  services.flatpak.enable = true;

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    nativeMessagingHosts.packages = [ pkgs.firefoxpwa ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "alan";
      };
      default_session = initial_session;
    };
  };

  services.locate.package = pkgs.mlocate;
  services.udisks2.enable = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vaapiIntel
      intel-media-driver
    ];
  };
  virtualisation.docker.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };
  services.pulseaudio.enable = false;

  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;
  services.zerotierone = {
    enable = true;
  };
  networking.wireguard.enable = true;

  security.polkit.enable = true;
  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
