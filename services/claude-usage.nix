# The claude-usage tracker: a daemon that polls the usage endpoint and serves a
# control socket, plus the CLI the eww bar listens to and the GTK4 popup its
# click opens.
#
# The module itself lives in the widgets flake; everything this file does is
# translate my.services.claudeUsage into its options. It used to hand over the
# three binaries as well — that flake defaults them from itself now, which is
# what one flake for all four tools buys.
#
# The one thing in widgets that is *not* a home-manager module, and the reason
# is the token: the daemon holds an API credential, so it runs as its own system
# user with /var/lib to itself and the desktop session cannot read it even by
# accident. Its socket is 0660, and `socketGroupMembers` is what lets the bar
# reach it.
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.services.claudeUsage;
in
{
  imports = [ inputs.widgets.nixosModules.claude-usage ];

  config = lib.mkIf cfg.enable {
    services.claude-usage = {
      enable = true;
      socketGroupMembers = [ config.users.users.alan.name ];
      tokenRefreshCommand = cfg.tokenRefreshCommand;
    };
  };
}
