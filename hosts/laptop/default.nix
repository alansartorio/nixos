{
  imports = [
    ./hardware-configuration.nix
    ./mounts.nix
  ];

  my = {
    # TODO: replace with the laptop's real hostname before the first switch.
    hostname = "alan-laptop-nixos";
    stateVersion = "25.05";
    # TODO: confirm -- assumed Intel integrated graphics.
    gpu = "intel";

    roles.mainPc = false;

    identity = {
      fullName = "Alan Sartorio";
      email = "alan42ga@hotmail.com";
      signingKey = null;
      work = {
        dir = "~/CHYPS/";
        email = "asartorio@chyps.com.ar";
      };
    };

    hardware.battery = true;

    desktop = {
      monitors.fixed = false;
      monitors.autoScaling = true;
      kdeConnect.enable = false;
    };

    services.hass.enable = false;
    services.llm.enable = false;
  };
}
