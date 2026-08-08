# The claude-usage tracker: a daemon that polls the usage endpoint and serves a
# control socket, plus the CLI the eww bar listens to and the GTK4 popup its
# click opens.
#
# The module itself lives in the claude-usage flake; everything this file does
# is hand it the three binaries and translate my.services.claudeUsage into its
# own options. Under the old layout that translation read
# `system-config.options.claudeUsage`, an untyped attrset from a separate local
# flake input; the values are host config like any other now.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.my.services.claudeUsage;
  claude-usage = inputs.claude-usage.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.claude-usage.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    services.claude-usage = {
      enable = true;

      # The upstream module takes the binaries rather than building them, so a
      # host is never left compiling the workspace three times over.
      packages = {
        cli = claude-usage.claude-usage;
        daemon = claude-usage.claude-usage-daemon;
        gui = claude-usage.claude-usage-gui;
      };

      tokenRefreshCommand = cfg.tokenRefreshCommand;
    };
  };
}
