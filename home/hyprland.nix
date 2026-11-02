# hyprland. Currently not the active session -- programs.hyprland.enable is
# false in desktop.nix over a build failure -- but the config is maintained so
# it can be switched back on without going digging.
#
# The chezmoi template branched on desktop_monitors, vertical_monitor,
# auto_scaling, nvidia, battery, kde_connect, hass and keyboard_model. All of
# those are my.* options now. The artix branch is gone with artix.
{
  lib,
  osConfig,
  ...
}:
let
  desktop = osConfig.my.desktop;
  monitors = desktop.monitors;
  nvidia = osConfig.my.gpu == "nvidia";
  battery = osConfig.my.hardware.battery;
  hassEnabled = osConfig.my.services.hass.enable;

  scale = if monitors.autoScaling then "auto" else "1";

  monitorLines =
    if !monitors.fixed then
      "monitor=,preferred,auto,${scale}"
    else if monitors.vertical then
      ''
        monitor=HDMI-A-1, preferred, 0x0, ${scale}, transform, 3
        monitor=DP-2, preferred, 1080x256, ${scale}, transform, 0''
    else
      ''
        monitor=HDMI-A-1, preferred, 0x0, ${scale}
        monitor=DP-2, preferred, 1920x0, ${scale}'';
in
{
  xdg.configFile."hypr/hyprland.conf".text =
    builtins.replaceStrings
      [
        "@MONITORS@"
        "@EXEC_KDECONNECT@"
        "@EXEC_HASS@"
        "@ENV_NVIDIA@"
        "@CURSOR_NVIDIA@"
        "@BLUR_ENABLED@"
        "@RENDER_NVIDIA@"
        "@KEYBOARD_MODEL@"
      ]
      [
        monitorLines
        (lib.optionalString desktop.kdeConnect.enable "exec-once = kdeconnectd")
        (lib.optionalString hassEnabled "exec = launch-hass-server")
        (lib.optionalString nvidia ''
          env = LIBVA_DRIVER_NAME,nvidia
          env = GBM_BACKEND,nvidia-drm
          env = __GLX_VENDOR_LIBRARY_NAME,nvidia'')
        (lib.optionalString nvidia ''
              no_hardware_cursors = true
              #no_break_fs_vrr = true
              min_refresh_rate = 48'')
        # Blur is the expensive effect; skip it on the machine running on a battery.
        (if battery then "false" else "true")
        (lib.optionalString nvidia ''
          render {
              explicit_sync = true
          }'')
        osConfig.my.hardware.keyboardModel
      ]
      (builtins.readFile ./files/hyprland.conf);
}
