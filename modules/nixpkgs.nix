# nixpkgs instantiation, as a module rather than a hand-rolled `import nixpkgs`
# in flake.nix. Doing it here means rocmSupport can depend on config.my.gpu,
# which is not knowable at flake-eval time.
{
  config,
  inputs,
  ...
}:
{
  nixpkgs.config = {
    allowUnfree = true;
    rocmSupport = config.my.gpu == "amd";
  };

  nixpkgs.overlays = [
    (import ../pkgs inputs)
  ];
}
