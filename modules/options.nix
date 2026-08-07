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
          type = types.nullOr types.path;
          default = null;
          description = "Path to the .gguf served by llama-cpp.";
        };
      };
    };
  };
}
