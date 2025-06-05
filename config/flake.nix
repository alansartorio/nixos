{
  description = "System configuration";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs =
    {
      nixpkgs,
      ...
    }:
    let
      inherit (nixpkgs.lib) fileContents;
    in
    {
        options = import ./options.nix;
        hardware = import ./hardware.nix;
    };
}
