{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    clockin.url = "github:alansartorio/clockin";
    clockin.inputs.nixpkgs.follows = "nixpkgs";
    rubik.url = "github:alansartorio/rubik";
    #rubik.inputs.nixpkgs.follows = "nixpkgs";
    hass-light-eww.url = "github:alansartorio/hass-light-eww";
    hass-light-eww.inputs.nixpkgs.follows = "nixpkgs";
    pipewire-screenaudio.url = "github:IceDBorn/pipewire-screenaudio";
    pipewire-screenaudio.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    system-config.url = "/home/alan/nixos/config";
  };
  outputs =
    {
      nixpkgs,
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
          };
          overlays = [
            (
              final: prev:
              let
                cmake3Nixpkgs = (
                  import (builtins.fetchGit {
                    name = "cmake3-nixpkgs";
                    url = "https://github.com/NixOS/nixpkgs/";
                    rev = "4b1164c3215f018c4442463a27689d973cffd750";
                  }) { inherit system; }
                );
              in
              {
                oculante = cmake3Nixpkgs.oculante;
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
