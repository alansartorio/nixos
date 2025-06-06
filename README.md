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

ln -s /etc/nixos/hardware-configuration.nix config/hardware.nix
sudo ln -s ~/nixos/flake.nix /etc/nixos/flake.nix
sudo rm /etc/nixos/configuration.nix

# Update flake (not sure if necessary)

nix flake update

# Rebuild

nixos-rebuild --use-remote-sudo --upgrade

