# Machine-independent declaration of every per-host knob.
#
# This replaces the old `system-config` flake input: values now go through the
# NixOS module system, so they are typed, have defaults, and can be consumed
# with lib.mkIf / lib.mkDefault like any other option.
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.my = {
    hostname = mkOption {
      type = types.str;
      description = "networking.hostName for this machine.";
    };

    stateVersion = mkOption {
      type = types.str;
      description = ''
        NixOS/home-manager state version. Set once when the machine is first
        installed and never bumped afterwards.
      '';
    };

    gpu = mkOption {
      type = types.enum [
        "amd"
        "intel"
        "nvidia"
      ];
      description = ''
        Primary GPU vendor. Selects the graphics driver stack and turns
        nixpkgs' rocmSupport on for "amd".
      '';
    };

    roles.mainPc = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether this machine acts as the household server: immich, jellyfin,
        samba, printing, sshd, peerflix, lact, performance governor.
      '';
    };

    identity = {
      fullName = mkOption {
        type = types.str;
        description = "Name used for git commits.";
      };

      email = mkOption {
        type = types.str;
        description = "Default git email.";
      };

      signingKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          GPG key id used to sign commits. When null, commit signing is off
          and no signingkey is written to the git config at all.
        '';
      };

      work = {
        dir = mkOption {
          type = types.str;
          description = ''
            Directory below which git uses the work identity, matched by git's
            `gitdir:` include condition.
          '';
        };

        email = mkOption {
          type = types.str;
          description = "Git email used inside identity.work.dir.";
        };
      };
    };

    ssh = {
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          Host vibevm popos
              ProxyJump desktop
        '';
        description = ''
          ssh_config spliced into ~/.ssh/config above the shared blocks, so it
          wins: ssh keeps the first value it obtains for a keyword and merges
          in what later blocks add. Use it for a host that is reached
          differently from this machine -- a ProxyJump only needed here, an
          address only routable from here -- and state only the difference;
          the rest still comes from the shared block.

          Public: this lands in the world-readable nix store, so it is for
          hosts whose names are in files/ssh/hosts.conf anyway. The encrypted
          list is not overridden per machine -- those hosts are reached the
          same way from everywhere.
        '';
      };

      privateHosts = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Include the shared encrypted host list -- work machines, VPSes --
          from the `ssh_hosts` key of secrets/common.yaml.

          Off by default because a declared sops secret whose key is missing
          fails activation, and a new machine has no business claiming those
          hosts before someone has decided it should have them.
        '';
      };
    };

    hardware = {
      battery = mkOption {
        type = types.bool;
        default = false;
        description = "Machine has a battery: show the eww battery widget, idle-friendly defaults.";
      };

      keyboardModel = mkOption {
        type = types.str;
        default = "at-translated-set-2-keyboard";
        description = "Device name hyprctl uses to switch the keyboard layout.";
      };
    };

    desktop = {
      monitors = {
        fixed = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Use the hardcoded multi-monitor layout instead of autodetecting a
            single display. Was `desktop_monitors` in .chezmoidata.toml.
          '';
        };

        vertical = mkOption {
          type = types.bool;
          default = false;
          description = "Rotate the secondary monitor. Only meaningful with monitors.fixed.";
        };

        autoScaling = mkOption {
          type = types.bool;
          default = true;
          description = "Let the compositor pick a fractional scale instead of forcing 1.";
        };
      };

      kdeConnect.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Start kdeconnectd with the session.";
      };

      vpnConnection = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          NetworkManager connection name shown as a toggle in the eww bar.
          Null hides the widget.
        '';
      };

      clockinProject = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "clockin project shown in the eww bar. Null hides the widget.";
      };
    };

    services = {
      hass = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Run hass-light-eww against a Home Assistant instance.";
        };

        host = mkOption {
          type = types.str;
          default = "http://192.168.0.151:8123";
          description = "Home Assistant base URL.";
        };
      };

      llm = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Run the local ollama + llama-cpp + open-webui stack.";
        };

        llamaCppModel = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Absolute path to the .gguf served by llama-cpp. A runtime path on
            the machine, not a store path -- hence str rather than path, which
            would try to copy the model into the nix store.
          '';
        };
      };

      # Read-only MCP servers for Claude Code on VibeVM, behind a filtering
      # proxy. See services/claude-mcp.nix for why the enforcement lives on
      # this machine rather than in Claude Code's own config.
      claudeMcp = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Run the read-only MCP stack and expose it to the libvirt guest.
            Only meaningful on a host that holds the CHYPS VPN, since every
            backend reaches the intranet through it.
          '';
        };

        listenAddress = mkOption {
          type = types.str;
          default = "192.168.100.1";
          description = ''
            Address the filtering proxy binds. Defaults to this host's address
            on the libvirt network -- the one interface the guest can reach,
            and deliberately not 0.0.0.0: the LAN has no business here.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 18100;
          description = ''
            Port for the filtering proxy. Must match the accept rule in
            networking.nix, which is the only hole punched for the guest.
          '';
        };

        gitea = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Expose Gitea, via upstream's own MCP server in --read-only mode.";
          };

          host = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "https://repo.intra.chyps.com.ar";
            description = ''
              Base URL of the Gitea instance. The token behind it wants only
              the read:* scopes -- that, not the --read-only flag, is what
              makes a write impossible.
            '';
          };
        };

        outline = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = ""
              + "Expose the Outline wiki through Outline's own MCP server at\n"
              + "<url>/mcp, which every workspace ships and an admin enables\n"
              + "under Settings -> AI. Nothing is packaged or run: the proxy\n"
              + "talks to Outline directly and attaches the API key.\n\n"
              + "Requires `tools`.";
          };

          url = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "https://docs.intra.chyps.com.ar";
            description = "Outline's base URL, with no path. /mcp is appended.";
          };

        };

        taiga = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Expose Taiga. The one route with no second layer: its MCP server
              has no read-only mode and authenticates as an ordinary user with
              full write rights, so the proxy's tools/call allowlist is the
              whole of the enforcement. Note that this puts a real Taiga
              password, not a scoped token, in sops.
            '';
          };

          url = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "https://proj.intra.chyps.com.ar";
            description =
              ""
              + "Taiga's base URL, WITHOUT /api/v1. pytaigaclient appends the\n"
              + "version itself (client.py: urljoin(host, \"api/v1/\")), so a\n"
              + "value ending in /api/v1 yields /api/api/v1/auth, which 404s.\n"
              + "The failure is quiet: auto-authentication logs the error at\n"
              + "startup, the unit stays running, and every tool then reports\n"
              + "\"no default session available\" as though the credentials were\n"
              + "missing rather than the URL being wrong.";
          };
        };

        elastic = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description =
              ""
              + "Expose Elasticsearch through Elastic's own MCP server.\n\n"
              + "Talks to Elasticsearch directly rather than to Kibana's Agent\n"
              + "Builder MCP endpoint that upstream now prefers: Agent Builder\n"
              + "needs an Enterprise subscription. Elasticsearch's own API keys\n"
              + "and role descriptors are Basic-tier and enforce read-only at\n"
              + "the source, which is the stronger layer anyway.";
          };

          url = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "https://elasticsearch.metatron.intra.chyps.com.ar";
            description =
              ""
              + "Elasticsearch REST endpoint -- not Kibana. No :9200 when a\n"
              + "reverse proxy fronts it on 443.\n\n"
              + "The API key behind it wants a role descriptor of:\n\n"
              + "  cluster: [ monitor ]\n"
              + "  indices: names [ <patterns> ],\n"
              + "           privileges [ read view_index_metadata monitor ]\n\n"
              + "monitor is needed in BOTH places. _cat/indices and _cat/shards\n"
              + "check the cluster privilege and then the index privilege for\n"
              + "every index they would return, and neither read nor\n"
              + "view_index_metadata satisfies the second check -- so with\n"
              + "cluster monitor alone, list_indices and get_shards 403 while\n"
              + "search and esql work, which reads like a cluster problem and\n"
              + "is not one. Everything here is read-only.\n\n"
              + "Reissue the key after any change: an Elasticsearch API key\n"
              + "freezes its privileges at creation, holding the intersection\n"
              + "of its role_descriptors and what its creator held at that\n"
              + "moment, so widening the role does nothing for an existing key.";
          };
        };
      };
    };
  };
}
