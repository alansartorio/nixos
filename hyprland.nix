{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Theming
    rose-pine-hyprcursor

    wl-clipboard
    swaybg
    dunst
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
    enable = true;
    xwayland.enable = true;
  };

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
}
