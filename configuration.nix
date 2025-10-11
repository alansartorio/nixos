{
  system-config,
  pkgs,
  ...
}:
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
    ./graphics.nix
    ./services.nix
    ./packages.nix
    ./development.nix
    ./networking.nix
    ./virtualization.nix
    ./desktop.nix
    ./audio.nix
    ./users.nix
    ./games.nix
  ];

  games.enable = system-config.options.mainPc;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.etc."libinput/local-overrides.quirks".text = ''
    [Logitech G502]
    MatchName=Logitech G502
    AttrEventCode=-REL_WHEEL_HI_RES;-REL_HWHEEL_HI_RES;
  '';

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

  security.rtkit.enable = true;

  system.stateVersion = system-config.options.stateVersion; # Did you read the comment?
}
