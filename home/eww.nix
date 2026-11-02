# The eww bar.
#
# eww.yuck was a chezmoi template with seven conditional regions. Those regions
# now live as fragments under files/eww/parts and are spliced into the base at
# @MARKER@ sites, which keeps the yuck readable and, more importantly, keeps
# yuck's own ${...} interpolation out of nix string escaping.
#
# builtins.replaceStrings rather than substituteAll/replaceVars on purpose:
# these files are full of unrelated @-delimited tokens (@DEFAULT_SINK@ and
# friends) that a blanket @var@ substitution would trip over.
{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  desktop = osConfig.my.desktop;
  hassEnabled = osConfig.my.services.hass.enable;
  claudeUsageEnabled = osConfig.my.services.claudeUsage.enable;
  kimaiEnabled = osConfig.my.services.kimai.enable;
  timersEnabled = osConfig.my.services.timers.enable;
  batteryEnabled = osConfig.my.hardware.battery;

  clockinProject = desktop.clockinProject;
  vpnConnection = desktop.vpnConnection;

  # Still spliced, but for the widget's middle click alone: the URL the CLI
  # talks to comes from the config file home/widgets.nix writes, not from here.
  # The token no longer appears in the yuck at all, which is what let the
  # `if hasKimai then … else ""` guard go — it existed only because a bare
  # `sops.secrets.kimai_token.path` is an eval error on a host without the
  # secret.
  kimaiUrl = osConfig.my.services.kimai.url;

  hasClockin = clockinProject != null;
  hasVpn = vpnConnection != null;

  # Fragments may refer to the project/connection names.
  part =
    name:
    builtins.replaceStrings
      [ "@CLOCKIN_PROJECT@" "@VPN_CONNECTION@" "@KIMAI_URL@" ]
      [ (toString clockinProject) (toString vpnConnection) (toString kimaiUrl) ]
      (builtins.readFile (./files/eww/parts + "/${name}.yuck"));

  optionalPart = cond: name: if cond then part name else "";

  yuck =
    builtins.replaceStrings
      [
        "@CLOCKIN_WIDGET@"
        "@CLOCKIN_ENTRY@"
        "@KIMAI_WIDGET@"
        "@KIMAI_ENTRY@"
        "@CLAUDE_WIDGET@"
        "@CLAUDE_ENTRY@"
        "@TIMERS_WIDGET@"
        "@TIMERS_ENTRY@"
        "@VPN_ENTRY@"
        "@VPN_LISTEN@"
        "@HASS_ENTRY@"
        "@HASS_LISTEN@"
        "@BATTERY_ENTRY@"
      ]
      [
        (optionalPart hasClockin "clockin-widget")
        (optionalPart hasClockin "clockin-entry")
        (optionalPart kimaiEnabled "kimai-widget")
        (optionalPart kimaiEnabled "kimai-entry")
        (optionalPart claudeUsageEnabled "claude-widget")
        (optionalPart claudeUsageEnabled "claude-entry")
        (optionalPart timersEnabled "timers-widget")
        (optionalPart timersEnabled "timers-entry")
        (optionalPart hasVpn "vpn-entry")
        (optionalPart hasVpn "vpn-listen")
        (optionalPart hassEnabled "hass-entry")
        (optionalPart hassEnabled "hass-listen")
        (optionalPart batteryEnabled "battery-entry")
      ]
      (builtins.readFile ./files/eww/eww.yuck);
in
{
  xdg.configFile = {
    "eww/bar/eww.yuck".text = yuck;
    "eww/bar/eww.scss".source = ./files/eww/eww.scss;
    "eww/bar/nord.scss".source = ./files/eww/nord.scss;
  };

  # The bar shells out to these by bare name; the old config called them
  # through a scripts/ subdirectory of the eww config dir.
  home.packages = [
    pkgs.eww-scripts
    pkgs.eww
  ];
}
