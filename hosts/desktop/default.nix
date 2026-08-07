{
  imports = [
    ./hardware-configuration.nix
    ./mounts.nix
  ];

  my = {
    # TODO: replace with this machine's real hostname before the first switch.
    hostname = "alan-desktop-nixos";
    stateVersion = "25.05";
    gpu = "amd";

    roles.mainPc = true;

    identity = {
      fullName = "Alan Sartorio";
      email = "alan42ga@hotmail.com";
      # TODO: set to your GPG key id to turn commit signing back on.
      signingKey = null;
      work = {
        dir = "~/CHYPS/";
        email = "asartorio@chyps.com.ar";
      };
    };

    hardware.battery = false;

    desktop = {
      monitors = {
        fixed = true;
        vertical = true;
        autoScaling = true;
      };
      kdeConnect.enable = false;
    };

    services.hass.enable = true;

    # TODO: point at a .gguf and flip to true to bring back the local LLM stack.
    services.llm.enable = false;
  };
}
