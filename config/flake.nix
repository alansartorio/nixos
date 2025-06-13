{
  description = "System configuration";
  inputs = {
    hardware-configuration.url = "path:/etc/nixos/hardware-configuration.nix";
    hardware-configuration.flake = false;
  };
  outputs =
    {
      hardware-configuration,
      ...
    }:
    rec {
      options = import ./options.nix;
      hardware = import hardware-configuration;
      mounts = import ./mounts.nix {
        system-config = {
          inherit options;
        };
      };
    };
}
