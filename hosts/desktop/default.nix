{
  imports = [
    ./hardware-configuration.nix
    ./mounts.nix
  ];

  my = {
    hostname = "alan-desktop";
    stateVersion = "25.05";
    gpu = "amd";

    roles.mainPc = true;

    hardware = {
      battery = false;
      keyboardModel = "by-tech-usb-gaming-keyboard";
    };

    desktop = {
      monitors = {
        fixed = true;
        vertical = false;
        autoScaling = true;
      };
      kdeConnect.enable = false;
      vpnConnection = "chyps";
    };

    services = {
      hass.enable = true;

      claudeUsage = {
        enable = true;
        # Claude Code runs on vibevm, so the credentials to refresh from live
        # there. The key this reads and the known_hosts entry behind it are set
        # up out of band, under the daemon's state dir.
        tokenRefreshCommand = "ssh -o BatchMode=yes -i /var/lib/claude-usage/.ssh/id_ed25519 vibevm cat .claude/.credentials.json";
      };

      llm = {
        enable = true;
        llamaCppModel = "/huge-storage/llamacpp-models/gemma-4-12B-it-q6_k_m.gguf";
      };
    };
  };
}
