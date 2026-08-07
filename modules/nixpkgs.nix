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

    (final: prev: {
      # `pkgs.stable.foo` for the occasional package that is broken on
      # unstable. The old flake imported nixpkgs-stable but never used it.
      stable = import inputs.nixpkgs-stable {
        inherit (final.stdenv.hostPlatform) system;
        config = config.nixpkgs.config;
      };
    })
  ];
}
