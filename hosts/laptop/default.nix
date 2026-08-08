{
  imports = [
    ./hardware-configuration.nix
    ./mounts.nix
  ];

  my = {
    hostname = "alan-notebook";
    # Older than the desktop's on purpose: this machine was installed earlier
    # and stateVersion is never bumped after install.
    stateVersion = "24.11";
    gpu = "intel";

    roles.mainPc = false;

    hardware.battery = true;

    desktop = {
      monitors = {
        fixed = false;
        autoScaling = false;
      };
      kdeConnect.enable = false;
      vpnConnection = "chyps";
      clockinProject = "CHYPS";
    };

    services = {
      hass.enable = false;
      llm.enable = false;
      # Deliberate, not just the default: the daemon is a second poller with a
      # state dir and a db of its own, and one machine already keeps that
      # history. No pill on this bar is the price, and it is worth paying.
      claudeUsage.enable = false;
    };
  };
}
