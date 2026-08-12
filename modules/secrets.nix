# sops-nix wiring.
#
# Secrets live encrypted in ./secrets/*.yaml and are committed to the public
# repo. Decryption uses the age identity in `sops.age.keyFile`, which is the
# same key.txt that chezmoi used to decrypt with -- copy it onto a new machine
# once and everything else works from a plain `git clone`, no auth required.
{ config, lib, ... }:
let
  ssh = config.my.ssh;
in
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
    }
    # The Kimai API token. Declared only where the integration is enabled, which
    # is what .chezmoiignore's `if not .kimai_url` did for the old
    # encrypted_private_kimai-token.age: a machine without it has no reason to
    # hold the token, and sops-install-secrets would refuse to install a key the
    # yaml has anyway.
    #
    # optionalAttrs rather than mkIf, so the attribute is simply absent rather
    # than present with a submodule's defaults.
    // lib.optionalAttrs config.my.services.kimai.enable {
      # eww runs as alan and so does the `kimai` CLI it listens to. Note that
      # what home/widgets.nix writes into the config file is this *path*, never
      # the token -- the secret is read from /run/secrets at runtime.
      kimai_token = {
        owner = config.users.users.alan.name;
        mode = "0400";
      };
    }
    # The host list ssh reads through `Include`. Left at its default path under
    # /run/secrets rather than given one inside ~/.ssh: a sops secret with a
    # `path` elsewhere is placed as a *symlink*, and sops-install-secrets
    # deletes whatever is already there first, with no backup. ~/.ssh/config is
    # home-manager's now, and the two would be fighting over it.
    #
    # Read by ssh running as alan, hence the ownership. 0400 because a config
    # file ssh will read has to be unwritable by anyone else anyway.
    // lib.optionalAttrs ssh.privateHosts {
      ssh_hosts = {
        owner = config.users.users.alan.name;
        mode = "0400";
      };
    };
  };
}
