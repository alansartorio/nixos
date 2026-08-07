# sops-nix wiring.
#
# Secrets live encrypted in ./secrets/*.yaml and are committed to the public
# repo. Decryption uses the age identity in `sops.age.keyFile`, which is the
# same key.txt that chezmoi used to decrypt with -- copy it onto a new machine
# once and everything else works from a plain `git clone`, no auth required.
{ config, ... }:
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

    secrets.hass_token = {
      # Read by launch-hass-server, which runs as the desktop user.
      owner = config.users.users.alan.name;
      mode = "0400";
    };

    # ~/.ssh/config used to be dot_ssh/encrypted_config.age in the chezmoi
    # repo. Deliberately left commented out: enabling it before the real
    # content is in secrets/common.yaml would overwrite a working ssh config
    # with a placeholder. To turn it on:
    #
    #   sops secrets/common.yaml     # add an ssh_config: | block
    #   then uncomment the following
    #
    # secrets.ssh_config = {
    #   owner = config.users.users.alan.name;
    #   mode = "0600";
    #   path = "/home/alan/.ssh/config";
    # };
  };
}
