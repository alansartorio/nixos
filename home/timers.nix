# Named countdown timers: a user daemon that owns the deadlines and fires the
# notifications, the CLI the eww bar listens to, and the GTK4 popup its clicks
# open.
#
# The module itself lives in the timers flake; everything this file does is hand
# it the three binaries and translate my.services.timers into its own options.
#
# A home-manager module rather than a NixOS one, unlike claude-usage's: the unit
# is per-session, since the database, the socket and the notification bus all
# belong to one logged-in user. NixOS has no per-user filter for
# systemd.user.services, so the NixOS flavour would start a timers daemon for
# every account that logs in graphically. Going through home-manager also puts
# `timers` and `timers-gui` on the PATH the bar inherits, which is where the
# yuck calls them from by bare name.
{
  osConfig,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = osConfig.my.services.timers;
  timers = inputs.timers.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.timers.homeManagerModules.default ];

  config = lib.mkIf cfg.enable {
    services.timers = {
      enable = true;

      # The upstream module takes the binaries rather than building them, so a
      # host is never left compiling the workspace three times over.
      packages = {
        cli = timers.timers;
        daemon = timers.timers-daemon;
        gui = timers.timers-gui;
      };
    };
  };
}
