# niri, the session actually in use (greetd's initial_session).
#
# The chezmoi template had exactly one conditional -- whether to spawn the Home
# Assistant bridge -- and that is now a systemd user unit bound to
# graphical-session.target, so this file has none: the config is copied verbatim.
{ ... }:
{
  xdg.configFile."niri/config.kdl".source = ./files/niri/config.kdl;
}
