# The tools behind the bar's pills, and the calendar the clock opens.
#
# One file where there were two, because the four of them now come from one
# flake. It imports that flake's aggregate home-manager module and translates
# `my.services.*` into its options — and no longer hands it any packages, since
# each module defaults its own from the flake it ships with. That handover was
# the only reason home/timers.nix existed.
#
# Home-manager rather than NixOS for all three of these, and for the same
# reason: they belong to a logged-in session. The timers unit owns a database, a
# socket and a notification bus that are all one user's; kimai reads a token
# that sops decrypts 0400 alan; the calendar is a window. NixOS has no per-user
# filter for `systemd.user.services`, so its flavour would start a timers daemon
# for every account that logs in graphically. Going through home-manager also
# puts the binaries on the PATH the bar inherits, which is where the yuck calls
# them from by bare name.
#
# claude-usage is the exception and stays in services/ — it is a system service
# with a user of its own, because it holds an API token the desktop session has
# no business being able to read.
{
  osConfig,
  lib,
  inputs,
  ...
}:
let
  timers = osConfig.my.services.timers;
  kimai = osConfig.my.services.kimai;
in
{
  imports = [ inputs.widgets.homeManagerModules.default ];

  config = {
    services.timers.enable = timers.enable;

    services.kimai = lib.mkIf kimai.enable {
      enable = true;
      url = kimai.url;

      # The path, not the token. sops decrypts it into /run/secrets at
      # activation and the CLI reads it there on every start, so nothing secret
      # lands in ~/.config or in the nix store. Reading osConfig here is safe
      # only because it sits inside mkIf: the option does not exist at all on a
      # host with kimai off, and home/eww.nix needed an explicit
      # `if hasKimai then … else ""` guard for exactly that reason.
      tokenFile = osConfig.sops.secrets.kimai_token.path;
    };

    # No `my.*` option behind this one, deliberately: configuration.nix imports
    # desktop.nix unconditionally, both hosts are graphical, and the eww window
    # it replaces was unconditional too. An option that reads true on every
    # machine is not a knob.
    programs.calendar-gui.enable = true;
  };
}
