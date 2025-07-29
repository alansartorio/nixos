{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Theming
    rose-pine-hyprcursor

    wl-clipboard
    swaybg
    #dunst
    mako
    rofi-wayland
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

    #gamescope

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
    settings = rec {
      initial_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "alan";
      };
      #initial_session = {
      #command = "${pkgs.uwsm}/bin/uwsm start -S niri.desktop";
      #user = "alan";
      #};
      hyprland = {
        command = "env MESA_LOADER_DRIVER_OVERRIDE=zink ${pkgs.uwsm}/bin/uwsm start -S -F ${pkgs.hyprland}/bin/Hyprland";
        user = "alan";
      };
      default_session = initial_session;
    };
  };

  #systemd.services.niri = {

  #};

  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      niri = {
        prettyName = "Niri";
        comment = "Niri compositor managed by UWSM";
        binPath = "${pkgs.niri}/bin/niri";
      };
      hyprland = {
        prettyName = "Hyprland";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "${pkgs.hyprland}/bin/Hyprland";
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
  #systemd.user.services.eww-launcher = {
    #enable = true;
    #path = [
      #pkgs.bash
      #pkgs.niri
      #pkgs.jq
      #pkgs.procps
      #pkgs.eww
      ##pkgs.socat
      ##pkgs.hyprland
    #];
    #serviceConfig = {
      #PartOf = "graphical-session.target";
      #After = "graphical-session.target";
      #Requisite = "graphical-session.target";
      #ExecStart = "/home/alan/.local/bin/eww-launcher";
      #Restart = "on-failure";
    #};
  #};
  #systemd.user.services.niri = {
    #wants = [
      ##"dunst.service"
      #"mako.service"
      ##"eww-launcher.service"
    #];
  #};
}
