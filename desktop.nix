{
  pkgs,
  config,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Theming
    rose-pine-hyprcursor

    wl-clipboard
    swaybg
    #dunst
    mako
    rofi
    pavucontrol
    alacritty

    kdePackages.dolphin

    # for video thumbnails in dolphin
    kdePackages.kio-extras
    kdePackages.ffmpegthumbs

    # Required for my eww config
    eww
    pamixer
    grim
    slurp
    socat
    xwayland-satellite
    libnotify
    rose-pine-cursor

    # needed for gnome file picker
    nautilus

    chezmoi
    inputs.hass-light-eww.packages.${system}.default
  ];

  fonts.packages = with pkgs; [
    #nerd-fonts.symbols-only
    material-design-icons
    nerd-fonts.roboto-mono
  ];
  fonts.fontconfig.enable = true;

  programs.hyprland = {
    package = pkgs.hyprland;
    enable = true;
  };

  programs.niri = {
    package = pkgs.niri;
    enable = true;
  };

  services.greetd = {
    enable = true;

    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --sessions ${config.services.displayManager.sessionData.desktops}/share/xsessions:${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --remember --remember-user-session";
        user = "greeter";
      };
      initial_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "alan";
      };
    };
  };

  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
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
}
