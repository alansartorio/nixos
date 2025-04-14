{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    clockin.url = "github:alansartorio/clockin";
    clockin.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      self,
      nixpkgs,
      clockin,
    }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem rec {
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
        system = "x86_64-linux";
        specialArgs = { inherit inputs system; };
        modules = [
          ./configuration.nix
          # This fixes nixpkgs (for e.g. "nix shell") to match the system nixpkgs
          (
            {
              config,
              pkgs,
              options,
              ...
            }:
            {
              nix.registry.nixpkgs.flake = nixpkgs;
            }
          )
        ];
      };
    };
}
