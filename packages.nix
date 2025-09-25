{
  pkgs,
  system-config,
  inputs,
  ...
}:
let
  lib = pkgs.lib;
  browsers = with pkgs; [
    firefoxpwa
    chromium
  ];

  cli-utils = with pkgs; [
    openssl
    age
    alsa-utils
    brightnessctl
    zip
    unzip
    file
    htop
    btop
    ripgrep
    ncdu
    mlocate
    erdtree
    killall
    gnupg
    wlr-randr
    exiftool
    # for psql
    postgresql
    ffmpeg
    sshpass
    xxd
    #immich-go
    #smartmontools
    distrobox
    pandoc
    texlive.combined.scheme-medium
    #steam-run
    nix-index
    atftp
    tmux
    inputs.clockin.packages.${system}.default
    inputs.rubik.packages.${system}.default
  ];

  gui-utils = with pkgs; [
    songrec
    gparted
    thunderbird
    polkit_gnome
    camset
    qpwgraph
    qbittorrent
    piper
    imhex
  ];

  libs = with pkgs; [
    ntfs3g
    xorg.libxcb
    wayland
    qt6.qtwayland
    vulkan-tools
  ];

  creation = with pkgs; [
    gimp3
    inkscape
    obs-studio
    vmpk
    fluidsynth
    soundfont-fluid
    orca-slicer
    freecad
    (if (system-config.options.gpu == "amd") then blender-hip else blender)
    libreoffice
    #unityhub
    #lmms
  ];

  guitar = with pkgs; [
    guitarix
  ];

  players = with pkgs; [
    mpv
    oculante
    spotify
  ];

  games = with pkgs; [
    prismlauncher
    gamescope
    openjdk17
  ];
in
{
  environment.systemPackages =
    (with pkgs; [
      kdePackages.kdeconnect-kde
      kdePackages.ark
      #kdePackages.kservice
      libsForQt5.kservice

    ])
    ++ browsers
    ++ cli-utils
    ++ gui-utils
    ++ libs
    ++ creation
    ++ players
    ++ games
    ++ guitar;

  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run;
  };

  programs.chromium = {
    enable = true;
  };
  environment.etc."chromium/native-messaging-hosts/com.icedborn.pipewirescreenaudioconnector.json".text =
    builtins.toJSON {
      name = "com.icedborn.pipewirescreenaudioconnector";
      description = "Connector to communicate with the browser";
      path = "${inputs.pipewire-screenaudio.packages.${pkgs.system}.default}/bin/connector-rs";
      type = "stdio";
      allowed_origins = [
        "chrome-extension://gablikphdaflmahdnopphhpckhialbie/"
      ];
    };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    nativeMessagingHosts.packages = [
      pkgs.firefoxpwa
      inputs.pipewire-screenaudio.packages.${pkgs.system}.default
    ];
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
  };
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

  # to fix guitarix tuner
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "-";
      item = "memlock";
      value = "8192000";
    }
    {
      domain = "*";
      type = "-";
      item = "rtprio";
      value = "95";
    }
  ];
}
