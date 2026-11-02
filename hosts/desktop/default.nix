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
        llamaCppModelsDir = "/huge-storage/llamacpp-models";
      };

      # Claude Code runs on VibeVM, which has no VPN of its own. This host
      # does, so it holds the intranet credentials and hands the guest one
      # unauthenticated port that speaks MCP and refuses to write.
      claudeMcp = {
        enable = true;

        gitea = {
          enable = true;
          host = "https://repo.intra.chyps.com.ar";
        };

        outline = {
          enable = true;
          url = "https://docs.intra.chyps.com.ar";
        };

        taiga = {
          enable = true;
          url = "https://proj.intra.chyps.com.ar";
        };

        elastic = {
          enable = true;
          url = "https://elasticsearch.metatron.intra.chyps.com.ar";
        };
      };
    };
  };
}
