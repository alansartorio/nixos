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
modules/identity.nix   name/email/signing key, same on every machine
modules/nixpkgs.nix    allowUnfree, rocmSupport, own-packages + pkgs.stable overlays
modules/secrets.nix    sops-nix wiring
modules/hass.nix       launch-hass-server, reads its token from /run/secrets
hosts/<host>/          hardware-configuration.nix, mounts.nix, and my.* values
pkgs/desktop-scripts   four rust binaries (was rust-script under chezmoi)
pkgs/eww-scripts       shell helpers for the bar and session
*.nix                  shared system modules
home.nix               home-manager entry point
home/                  shell, apps, niri, hyprland, eww
home/files/            verbatim payloads (nvim, p10k, stylesheets, base configs)
secrets/common.yaml    sops-encrypted, safe to publish
```

Dotfiles used to live in a separate chezmoi repo. They are all here now; the
templated ones (`home/niri.nix`, `home/hyprland.nix`, `home/eww.nix`) splice
per-host values into a base file at `@MARKER@` sites via
`builtins.replaceStrings`. Note that plain `substituteAll`/`replaceVars` is not
usable on these files — they are full of unrelated `@…@` tokens such as
`@DEFAULT_SINK@`.

Per-host settings live in `hosts/<host>/default.nix` and are declared in
`modules/options.nix`. Adding a machine means adding a directory there and one
line in `flake.nix`.

## Install on a new machine

```sh
# 1. get a shell with git and flakes (the installer ISO already has both)
git clone https://github.com/alansartorio/nixos.git ~/nixos-config
cd ~/nixos-config

# 2. only for a machine that is not yet in hosts/ -- desktop and laptop
#    already have their real scans committed
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
