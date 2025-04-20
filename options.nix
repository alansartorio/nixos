{
  lib,
  ...
}:
let
  inherit (lib) fileContents mkOption types;
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
    };
  };

  config = {
    alan = {
      intel = true;
    };
  };
}
