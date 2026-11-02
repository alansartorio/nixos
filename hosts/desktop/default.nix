{ pkgs, ... }:
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

    # No extraConfig: the libvirt guests hang off this machine's own bridges,
    # so the shared block already describes every host correctly from here.
    ssh.privateHosts = true;

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
      timers.enable = true;

      kimai = {
        enable = true;
        # Behind the same VPN as desktop.vpnConnection above, so the pill says
        # "unreachable" whenever that is down -- which is the point of it saying
        # anything at all.
        url = "https://kimai.intra.chyps.com.ar";
      };

      claudeUsage = {
        enable = true;
        # Claude Code runs on vibevm, so the credentials to refresh from live
        # there. The key this reads and the known_hosts entry behind it are set
        # up out of band, under the daemon's state dir.
        tokenRefreshCommand = "${pkgs.openssh}/bin/ssh -o BatchMode=yes alan@vibevm.local";
      };

      llm = {
        enable = true;
        llamaCppModel = "/huge-storage/llamacpp-models/gemma-4-12B-it-q6_k_m.gguf";
      };
    };
  };
}
