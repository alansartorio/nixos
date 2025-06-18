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
  boot.kernelPackages = pkgs.linuxPackages_latest;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  environment.localBinInPath = true;
  imports = [
    # Include the results of the hardware scan.
    system-config.hardware
    system-config.mounts
  ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.kernelModules = lib.optionals (system-config.options.gpu == "amd") [ "amdgpu" ];
  systemd.tmpfiles.rules = lib.optionals (system-config.options.gpu == "amd") [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  networking.hostName = system-config.options.hostname; # Define your hostname.
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.alan = {
    isNormalUser = true;
    description = "Alan Sartorio";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "wireshark"
      "immich"
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
    alsa-utils
    brightnessctl
    zip
    dig
    bind
    iproute2
    curl

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
    gparted

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

    # Required for my eww config
    eww
    pamixer
    socat
    rust-script

    kdePackages.dolphin
    kdePackages.kdeconnect-kde
    kdePackages.ark
    #firefox
    pavucontrol
    rofi-wayland
    thunderbird
    kdePackages.kdenlive

    (dotnetCorePackages.combinePackages [
      dotnetCorePackages.dotnet_8.sdk
      dotnetCorePackages.dotnet_8.aspnetcore
      dotnetCorePackages.dotnet_9.sdk
    ])
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
    killall
    easyeffects

    gnupg
    wlr-randr

    vmpk
    fluidsynth
    soundfont-fluid
    python3
    pyright
    love
    go
    gopls

    qt6.qtwayland
    mpv
    oculante
    nodejs_latest
    qbittorrent
    ethtool

    vulkan-tools
    nmap
    ffmpeg

    orca-slicer
    freecad
    (if (system-config.options.gpu == "amd") then blender-hip else blender)

    gimp3
    inkscape
    obs-studio
    sshpass
    xxd
    postgresql
    immich-go

    inputs.clockin.packages.${system}.default
    inputs.hass-light-eww.packages.${system}.default
  ];

  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [ "alan" ];

  virtualisation.libvirtd = {
    enable = true;
  };
  virtualisation.spiceUSBRedirection.enable = true;

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  services.flatpak.enable = true;

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    nativeMessagingHosts.packages = [
      pkgs.firefoxpwa
      inputs.pipewire-screenaudio.packages.${pkgs.system}.default
    ];
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
        command = "${pkgs.uwsm}/bin/uwsm start -S -F ${pkgs.hyprland}/bin/Hyprland";
        user = "alan";
      };
      default_session = initial_session;
    };
  };

  services.locate.package = pkgs.mlocate;
  services.udisks2.enable = true;
  hardware.graphics = {
    enable = true;
    extraPackages =
      with pkgs;
      lib.optionals (system-config.options.gpu == "intel") [
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
  services.upower.enable = true;

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
  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      hyprland = {
        prettyName = "Hyprland";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/Hyprland";
      };
    };
  };

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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = system-config.options.stateVersion; # Did you read the comment?

}
