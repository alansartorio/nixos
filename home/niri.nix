# niri, the session actually in use (greetd's initial_session).
#
# The chezmoi template had exactly one conditional -- whether to spawn the
# Home Assistant bridge -- so the config is kept verbatim with a single marker.
{ osConfig, ... }:
let
  hassEnabled = osConfig.my.services.hass.enable;
in
{
  xdg.configFile."niri/config.kdl".text =
    builtins.replaceStrings
      [ "@HASS_SPAWN@" ]
      [ (if hassEnabled then ''spawn-at-startup "launch-hass-server"'' else "") ]
      (builtins.readFile ./files/niri/config.kdl);
}
