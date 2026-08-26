# Bluetooth: pairing, audio, and above all receiving files pushed from a phone.
#
# Three separate pieces have to be in place before an incoming file lands on
# disk, and only the first is obvious:
#
#   - bluetoothd, from hardware.bluetooth: the adapter and the pairing.
#   - obexd, which owns the object-push profile. bluez ships it as a session
#     bus service and hardware.bluetooth already registers it, so there is
#     nothing to enable -- but note it lives in the *user* session, not in the
#     system one, which is why the agent below has to be a user service too.
#   - an OBEX agent, to answer the transfer obexd is offered. Without one
#     obexd has nobody to ask and the push is refused. blueman-applet is that
#     agent; it is also what pops the "receiving file" notification.
#
# blueman-manager is the GUI for the part that stays manual: pair the phone
# once and mark it trusted, which is what opp-accept below keys off.
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.hardware.bluetooth;
in
{
  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true;

    # blueman's own unit is Type=dbus with no [Install] section: upstream
    # expects it to be activated by whoever asks for org.blueman.Applet, and on
    # this session nothing ever asks. So bind it to the session by hand, the
    # same way desktop.nix does for the polkit agent -- the agent has to be
    # listening *before* the phone starts pushing, not after.
    #
    # It wants a tray to put its icon in and this bar gives it none. Harmless:
    # the agent and the notifications work without one, the icon is just never
    # drawn.
    systemd.user.services.blueman-applet = {
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
    };

    # blueman keeps its settings in GSettings, so without dconf they go to the
    # memory backend: anything changed in blueman-manager is forgotten when the
    # applet exits. With it, the values below are defaults the GUI can still
    # override -- the profile keeps user-db first.
    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings."org/blueman/transfer" = {
            # Take a push from a trusted device without asking. Not laziness:
            # blueman asks by hanging Accept/Reject *actions* off a
            # notification, and mako -- which is what niri spawns for these --
            # has no binding that invokes an action, so the prompt would be a
            # dead end. Trust is the gate instead: the phone is trusted once in
            # blueman-manager, and anything else that tries to push still gets
            # that unanswerable prompt, which is the same as a refusal.
            opp-accept = true;

            # Left empty blueman falls back to the XDG download directory, and
            # to bare $HOME when that is unset -- and nothing here writes
            # user-dirs.dirs, so it would be $HOME. Name the directory instead;
            # blueman warns and ignores it if it does not exist, hence the
            # tmpfiles rule.
            shared-path = "${config.users.users.alan.home}/Downloads";
          };
        }
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${config.users.users.alan.home}/Downloads 0755 alan users - -"
    ];
  };
}
