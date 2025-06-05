{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    clockin.url = "github:alansartorio/clockin";
    clockin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    system-config = {
      type = "path";
      path = "/home/alan/nixos/config";
    };
  };
  outputs =
    {
      nixpkgs,
      home-manager,
      system-config,
      ...
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
        specialArgs = {
          inherit inputs system system-config;
        };
        modules = [
          ./configuration.nix
          # This fixes nixpkgs (for e.g. "nix shell") to match the system nixpkgs
          (
            { ... }:
            {
              nix.registry.nixpkgs.flake = nixpkgs;
            }
          )

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.alan.imports = [
              (
                { ... }:
                import ./home.nix {
                  inherit pkgs system-config;
                  lib = nixpkgs.lib;
                }
              )
            ];
          }
        ];
      };
    };
}
