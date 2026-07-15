{
  system-config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./vmpk.nix
  ];
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
        name = system-config.options.fullName;
        email = system-config.options.email;
        signingkey = system-config.options.signingKey;
      };
      init.defaultBranch = "main";
      core.excludesFile = "~/.gitignore";
      commit.gpgsign = system-config.options.signingKey != null;
    };
    includes = [
      {
        condition = "gitdir:${system-config.options.work.dir}";
        contents = {
          user = {
            name = system-config.options.fullName;
            email = system-config.options.work.email;
          };
        };
      }
    ];
  };
}
