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
    settings = {
      user = {
        name = "Alan Sartorio";
        email = system-config.options.email;
      };
      init.defaultBranch = "main";
      core.excludesFile = "~/.gitignore";
      commit.gpgsign = true;
    };
  };
}
