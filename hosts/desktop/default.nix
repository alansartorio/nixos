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

      llm = {
        enable = true;
        llamaCppModel = "/huge-storage/llamacpp-models/gemma-4-12B-it-q6_k_m.gguf";
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
          url = "https://docs.intra.chyps.com.ar/api";
        };

        taiga = {
          enable = true;
          url = "https://proj.intra.chyps.com.ar/api/v1";
        };

        elastic = {
          # Still off, and only for want of `tools`: Agent Builder exposes
          # whatever tools this Kibana defines, so the list has to be read off
          # the instance rather than guessed, and an empty allowlist would
          # forward nothing anyway. The url is recorded now so that is the
          # only thing left to fill in.
          enable = false;
          url = "https://kibana.metatron.intra.chyps.com.ar/api/agent_builder/mcp";
        };
      };
    };
  };
}
