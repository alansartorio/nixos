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

    (
      final: prev:
      let
        stable = (
          import inputs.nixpkgs-stable {
            inherit (final.stdenv.hostPlatform) system;
            config = config.nixpkgs.config;
          }
        );
      in
      {
        xwayland-satellite = prev.xwayland-satellite.overrideAttrs (oldAttrs: rec {
          src = final.fetchFromGitHub {
            owner = "Supreeeme";
            repo = "xwayland-satellite";
            rev = "add2795134593faafce60e404a0a75df68e9ee0c";
            hash = "sha256-0TxfMgqW0/BLD4M942c5DCKYrtPvzsPJwvdcco4LQUM=";
          };
          cargoDeps = final.rustPlatform.fetchCargoVendor {
            inherit src;
            hash = "sha256-s1gl9eR6Mt2QLrhfcowstPFjzwE/lz4PJhJzWYHoIHg=";
          };
        });
      }
    )
  ];
}
