{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-25.05";
    clockin.url = "github:alansartorio/clockin";
    clockin.inputs.nixpkgs.follows = "nixpkgs";
    rubik.url = "github:alansartorio/rubik";
    #rubik.inputs.nixpkgs.follows = "nixpkgs";
    hass-light-eww.url = "github:alansartorio/hass-light-eww";
    hass-light-eww.inputs.nixpkgs.follows = "nixpkgs";
    croptool.url = "github:alansartorio/croptool";
    croptool.inputs.nixpkgs.follows = "nixpkgs";
    pipewire-screenaudio.url = "github:IceDBorn/pipewire-screenaudio";
    pipewire-screenaudio.inputs.nixpkgs.follows = "nixpkgs";
    clipper.url = "github:alansartorio/Clipper/all-merged";
    clipper.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    system-config.url = "/home/alan/nixos/config";
  };
  outputs =
    {
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      system-config,
      ...
    }@inputs:
    {
      nixosConfigurations."${system-config.options.hostname}" = nixpkgs.lib.nixosSystem rec {
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            rocmSupport = system-config.options.gpu == "amd";
          };
          overlays = [
            (
              let
                pkgs-stable = import nixpkgs-stable {
                  inherit system;
                  allowUnfree = true;
                  rocmSupport = system-config.options.gpu == "amd";
                };
                pkgs-no-gpu = import nixpkgs {
                  inherit system;
                  allowUnfree = true;
                  rocmSupport = false;
                };
              in
              final: prev: {
              }
            )
          ];
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
