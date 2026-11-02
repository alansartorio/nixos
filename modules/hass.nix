# hass-light-eww launcher.
#
# The old chezmoi template baked the API token straight into hyprland.conf and
# niri/config.kdl, so the plaintext ended up in ~/.config on every machine.
# Here the token stays in /run/secrets and only this wrapper ever reads it; the
# compositor configs just spawn `launch-hass-server` with no arguments.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.my.services.hass;

  hass-light-eww = inputs.hass-light-eww.packages.${pkgs.stdenv.hostPlatform.system}.default;

  launch-hass-server = pkgs.writeShellApplication {
    name = "launch-hass-server";
    runtimeInputs = [
      pkgs.socat
      pkgs.psmisc
      hass-light-eww
    ];
    text = ''
      tokenFile="''${HASS_TOKEN_FILE:-${config.sops.secrets.hass_token.path}}"
      if [ ! -r "$tokenFile" ]; then
        echo "launch-hass-server: cannot read $tokenFile" >&2
        exit 1
      fi

      HASS_TOKEN="$(cat "$tokenFile")"
      export HASS_TOKEN
      export HASS_HOST="''${HASS_HOST:-${cfg.host}}"

      killall -q hass-light-eww || true
      rm -f /tmp/hass-light.sock
      socat -u UNIX-RECV:/tmp/hass-light.sock - | hass-light-eww &
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      launch-hass-server
      hass-light-eww
    ];
  };
}
