# Packages defined in this repo, exposed as an overlay so they are reachable as
# pkgs.<name> from any module.
inputs: final: prev: {
  desktop-scripts = final.callPackage ./desktop-scripts {
    clockin = inputs.clockin.packages.${final.stdenv.hostPlatform.system}.default;
  };
}
