{
  system-config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    chezmoi
    less
    age
  ];

  home.stateVersion = system-config.options.stateVersion;
  home.username = "alan";
  home.homeDirectory = "/home/alan";
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Alan Sartorio";
    userEmail = system-config.options.email;
    extraConfig = {
      init.defaultBranch = "main";
      core.excludesFile = "~/.gitignore";
    };
  };
}
