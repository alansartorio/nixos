{
  pkgs,
  system-config,
  inputs,
  ...
}:
let
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
    inputs.clockin.packages.${system}.default
  ];

  gui-utils = with pkgs; [
    gparted
    thunderbird
    polkit_gnome
    camset
    qpwgraph
    qbittorrent
    piper
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
    lmms
  ];

  players = with pkgs; [
    mpv
    oculante
    spotify
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
    ++ players;

  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run;
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
}
