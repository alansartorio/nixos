# sops-nix wiring.
#
# Secrets live encrypted in ./secrets/*.yaml and are committed to the public
# repo. Decryption uses the age identity in `sops.age.keyFile`, which is the
# same key.txt that chezmoi used to decrypt with -- copy it onto a new machine
# once and everything else works from a plain `git clone`, no auth required.
{ config, lib, ... }:
{
  sops = {
    defaultSopsFile = ../secrets/common.yaml;
    validateSopsFiles = true;

    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      # Don't invent a new identity: this repo is encrypted to the existing
      # age recipient recorded in .sops.yaml.
      generateKey = false;
    };

    secrets = {
      hass_token = {
        # Read by launch-hass-server, which runs as the desktop user.
        owner = config.users.users.alan.name;
        mode = "0400";
      };

      # ~/.ssh/config, previously dot_ssh/encrypted_config.age under chezmoi.
      #
      # Note this is not a regular file: a sops secret with a `path` outside
      # /run/secrets is placed as a *symlink* into /run/secrets.d, and
      # sops-install-secrets removes whatever is already at that path first --
      # no backup. It also means the file only exists after activation and is
      # recreated from tmpfs on every boot.
      ssh_config = {
        owner = config.users.users.alan.name;
        mode = "0600";
        path = "/home/alan/.ssh/config";
      };
    }
    # The Kimai API token, read by the bar's kimai-integration listener.
    # Declared only where the widget exists, which is what .chezmoiignore's
    # `if not .kimai_url` did for the old encrypted_private_kimai-token.age:
    # a machine without the widget has no reason to hold the token, and
    # sops-install-secrets would refuse to install a key the yaml has anyway.
    #
    # optionalAttrs rather than mkIf, so the attribute is simply absent rather
    # than present with a submodule's defaults.
    // lib.optionalAttrs (config.my.desktop.kimaiUrl != null) {
      # eww runs as alan, so kimai-integration reads this as alan.
      kimai_token = {
        owner = config.users.users.alan.name;
        mode = "0400";
      };
    };
  };
}
