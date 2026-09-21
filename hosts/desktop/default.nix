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
          enable = true;
          url = "https://elasticsearch.metatron.intra.chyps.com.ar";
          # Fronted by Caddy on 443, so no :9200 here.
          #
          # The API key needs monitor in BOTH places -- cluster AND the index
          # block -- or list_indices and get_shards 403 while search and esql
          # work fine. _cat/indices checks the cluster privilege and then the
          # index privilege for every index it would return; read and
          # view_index_metadata satisfy neither.
          #
          # Note also that an Elasticsearch API key freezes its privileges at
          # creation: it holds the intersection of its role_descriptors and
          # what the creator had at that moment. Widening the role afterwards
          # does nothing for an existing key -- it has to be reissued.
        };
      };
    };
  };
}
