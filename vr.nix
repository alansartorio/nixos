{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.vr;
in
{
  options.vr = {
    enable = lib.mkEnableOption "vr";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      #bs-manager
      steam-run-free

      stardust-xr-server
      stardust-xr-flatland
      stardust-xr-protostar
      stardust-xr-gravity
      stardust-xr-magnetar
      stardust-xr-atmosphere
      stardust-xr-sphereland
    ];
    services.wivrn = {
      enable = true;
      package = pkgs.wivrn;
      defaultRuntime = true;
      config.enable = true;
      config.json = {
        scale = 0.5;
        bitrate = 100000000;
        #application = [ pkgs.wlx-overlay-s ];
      };
      autoStart = false;
    };
    hardware.uinput.enable = true;
    users.groups.input.members = [ "alan" ];
    programs.envision = {
      enable = true;
    };
  };
}
