{
  description = "System configuration";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs =
    {
      nixpkgs,
      self,
    }:
    let
      inherit (nixpkgs.lib) fileContents mkOption types;
      mkBoolOption = mkOption { type = types.bool; };
      mkLinesOption = mkOption { type = types.lines; };
      mkNumberOption = mkOption { type = types.number; };
      mkStrListOption = mkOption { type = with types; listOf str; };
      mkStrOption = mkOption { type = types.str; };
    in
    {
      options = {
        alan = {
          intel = mkBoolOption;
          email = mkStrOption;
        };
      };

      alan = fromTOML (
        fileContents (
          builtins.path {
            path = ./config.toml;
            name = "config";
          }
        )
      );
    };
}
