{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
{
  home.stateVersion = "24.11";
  home.username = "alan";
  home.homeDirectory = "/home/alan";
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Alan Sartorio";
    userEmail = osConfig.alan.email;
    extraConfig = {
      init.defaultBranch = "main";
      core.excludesFile = "~/.gitignore";
    };
  };

  home.file = {
    ".gitignore" = {
      text = ''
        .clockin
      '';
    };
  };
}
