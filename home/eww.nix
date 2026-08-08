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
  batteryEnabled = osConfig.my.hardware.battery;

  clockinProject = desktop.clockinProject;
  vpnConnection = desktop.vpnConnection;
  kimaiUrl = desktop.kimaiUrl;

  hasClockin = clockinProject != null;
  hasVpn = vpnConnection != null;
  hasKimai = kimaiUrl != null;

  # Only read where the widget exists: sops leaves the option undefined on a
  # machine with no kimai, and `toString` of a missing attribute is an error
  # rather than an empty string.
  kimaiTokenFile = if hasKimai then osConfig.sops.secrets.kimai_token.path else "";

  # Fragments may refer to the project/connection names.
  part =
    name:
    builtins.replaceStrings
      [ "@CLOCKIN_PROJECT@" "@VPN_CONNECTION@" "@KIMAI_URL@" "@KIMAI_TOKEN_FILE@" ]
      [ (toString clockinProject) (toString vpnConnection) (toString kimaiUrl) kimaiTokenFile ]
      (builtins.readFile (./files/eww/parts + "/${name}.yuck"));

  optionalPart = cond: name: if cond then part name else "";

  yuck = builtins.replaceStrings
    [
      "@CLOCKIN_WIDGET@"
      "@CLOCKIN_ENTRY@"
      "@KIMAI_WIDGET@"
      "@KIMAI_ENTRY@"
      "@VPN_ENTRY@"
      "@VPN_LISTEN@"
      "@HASS_ENTRY@"
      "@HASS_LISTEN@"
      "@BATTERY_ENTRY@"
    ]
    [
      (optionalPart hasClockin "clockin-widget")
      (optionalPart hasClockin "clockin-entry")
      (optionalPart hasKimai "kimai-widget")
      (optionalPart hasKimai "kimai-entry")
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
