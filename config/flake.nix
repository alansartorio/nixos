{
  description = "System configuration";
  inputs = {
  };
  outputs =
    {
      ...
    }:
    rec {
      options = import ./options.nix;
    };
}
