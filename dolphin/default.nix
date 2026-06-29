{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    kdePackages.dolphin

    # for video thumbnails in dolphin
    kdePackages.kio-extras
    kdePackages.ffmpegthumbs
  ];
  environment.etc."xdg/menus/applications.menu".source = ./dolphin.menu;
}
