# home-manager config for alan.
#
# Imported as a real home-manager module now, so `osConfig` gives access to the
# NixOS side (config.my.*) instead of the old hand-rolled `import ./home.nix`.
{
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  identity = osConfig.my.identity;
  signs = identity.signingKey != null;
in
{
  imports = [
    ./home
  ];
  home.packages = with pkgs; [
    less
    age
    # Was four `#!/usr/bin/env rust-script` files applied by chezmoi.
    desktop-scripts
  ];

  home.stateVersion = osConfig.my.stateVersion;
  home.username = "alan";
  home.homeDirectory = "/home/alan";
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = identity.fullName;
        email = identity.email;
      }
      // lib.optionalAttrs signs { signingkey = identity.signingKey; };
      init.defaultBranch = "main";
      core.excludesFile = "~/.gitignore";
      commit.gpgsign = signs;
    };
    includes = [
      {
        condition = "gitdir:${identity.work.dir}";
        contents = {
          user = {
            name = identity.fullName;
            email = identity.work.email;
          };
        };
      }
    ];
  };
}
