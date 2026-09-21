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
          # Off only for want of the Elasticsearch URL. Nothing else is
          # missing: the tool set is fixed and wholly read-only, so there is
          # no allowlist to enumerate.
          #
          # Not Kibana's Agent Builder endpoint, which is where this started:
          # that needs an Enterprise subscription, and customising per-feature
          # privileges to grant it needs Gold. Elasticsearch's own API keys
          # cost nothing beyond Basic and enforce read-only at the source.
          enable = false;
          # url = "https://<elasticsearch>:9200";
        };
      };
    };
  };
}
