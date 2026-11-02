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

    ssh = {
      privateHosts = true;
      extraConfig = ''
        # Both of these are guests on the desktop's libvirt networks, which are
        # only routable from the desktop itself. Their addresses, users and keys
        # still come from the shared block -- the way in is the only thing that
        # differs from here.
        #
        # `desktop` is its LAN address, so this works from the house. Away from
        # it, swap in desktop-zt.
        Host vibevm popos
            ProxyJump desktop
      '';
    };

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
      timers.enable = true;
      llm.enable = false;
      # Off for now rather than by accident: this machine still uses clockin
      # (desktop.clockinProject above), and two pills answering the same
      # question is one too many. Turning it on is `enable` plus the same `url`
      # the desktop uses; the sops secret follows the enable on its own.
      kimai.enable = false;
      # Deliberate, not just the default: the daemon is a second poller with a
      # state dir and a db of its own, and one machine already keeps that
      # history. No pill on this bar is the price, and it is worth paying.
      claudeUsage.enable = false;
    };
  };
}
