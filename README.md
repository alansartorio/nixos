# NixOS configuration

One flake, two machines:

| Host | `nixos-rebuild` target | Role |
| --- | --- | --- |
| desktop | `.#desktop` | main PC: immich, jellyfin, samba, printing, sshd |
| laptop | `.#laptop` | portable, no server services |

Everything in this repo is public. Secrets are committed too, but encrypted
with [sops-nix](https://github.com/Mic92/sops-nix) — see below.

## Layout

```
flake.nix              mkHost helper + nixosConfigurations
modules/options.nix    every per-host knob, declared as typed NixOS options (my.*)
modules/nixpkgs.nix    allowUnfree, rocmSupport, pkgs.stable overlay
modules/secrets.nix    sops-nix wiring
modules/hass.nix       launch-hass-server, reads its token from /run/secrets
hosts/<host>/          hardware-configuration.nix, mounts.nix, and my.* values
*.nix                  shared system modules
home.nix               home-manager config for alan
secrets/common.yaml    sops-encrypted, safe to publish
```

Per-host settings live in `hosts/<host>/default.nix` and are declared in
`modules/options.nix`. Adding a machine means adding a directory there and one
line in `flake.nix`.

## Install on a new machine

```sh
# 1. get a shell with git and flakes (the installer ISO already has both)
git clone https://github.com/alansartorio/nixos.git ~/nixos-config
cd ~/nixos-config

# 2. drop in this machine's hardware scan
nixos-generate-config --show-hardware-config > hosts/<host>/hardware-configuration.nix

# 3. install the age identity so sops can decrypt (same key.txt chezmoi used)
sudo mkdir -p /var/lib/sops-nix
sudo cp /path/to/key.txt /var/lib/sops-nix/key.txt
sudo chmod 600 /var/lib/sops-nix/key.txt

# 4. build
sudo nixos-rebuild switch --flake .#<host>
```

Step 3 is the only step that needs anything not in the repo. Everything else
works from an unauthenticated clone.

## Secrets

Edit with `sops secrets/common.yaml` — it decrypts in your editor and
re-encrypts on save. `.sops.yaml` holds the recipient list; to authorise a new
key add it there and run `sops updatekeys secrets/common.yaml`.

Declare each secret in `modules/secrets.nix`; sops-nix decrypts it to
`/run/secrets/<name>` at activation with the owner and mode you specify.
Never interpolate a secret into a config file — read it at runtime from its
`/run/secrets` path, the way `modules/hass.nix` does.
