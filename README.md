# Install git

add git to /etc/nixos/configuration.nix and set experimental features:

```nix
    ...
    nix.settings.experimental-features = [
        "nix-command"
        "flakes"
    ];
    environment.systemPackages = with pkgs; [
        git
    ];
    ...
```


# Clone repo

git clone https://github.com/alansartorio/nixos.git

# Set options in config/options.nix module

# Setup symlinks

sudo ln -s ~/nixos/flake.nix /etc/nixos/flake.nix
sudo rm /etc/nixos/configuration.nix

# Rebuild

nix flake update
nixos-rebuild --verbose --sudo switch --show-trace

