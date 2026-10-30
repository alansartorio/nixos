# Backport of NixOS/nixpkgs@25e6c983186a (ratarmountcore 0.10.1 -> 0.11.1,
# both built with setuptools_80): nixos-unstable ships ratarmount 1.3.0, which
# requires ratarmountcore ~= 0.11. Drop the overrides once the channel has it.
{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyFinal: pyPrev: {
          ratarmountcore =
            if pyPrev.ratarmountcore.version != "0.10.1" then
              pyPrev.ratarmountcore
            else
              pyPrev.ratarmountcore.overridePythonAttrs (old: rec {
                version = "0.11.1";
                src = old.src.override {
                  tag = "core-v${version}";
                  hash = "sha256-ScGmLLQPKt80fzNZgwRlsnHKK1DdmlXjOgjxv6hUb0E=";
                };
                postPatch = ''
                  substituteInPlace tests/test_formats.py --replace-fail \
                    '"tests/single-file.tar"' \
                    '"single-file.tar"' \
                '';
                build-system = [ pyFinal.setuptools_80 ];
                optional-dependencies = old.optional-dependencies // {
                  pdf = [
                    pyFinal.pypdf
                    pyFinal.pillow
                  ];
                };
                nativeCheckInputs = old.nativeCheckInputs ++ [
                  pyFinal.pypdf
                  pyFinal.pillow
                ];
              });
          ratarmount = pyPrev.ratarmount.overridePythonAttrs (old: {
            build-system = [ pyFinal.setuptools_80 ];
            # nixpkgs leaves out upstream's `squashfs` extra, so .squashfs
            # files fail with "unrecognized format".
            dependencies = old.dependencies ++ [
              pyFinal.pysquashfsimage
              pyFinal.lz4
              pyFinal.python-lzo
              pyFinal.zstandard
            ];
          });
        })
      ];
    })
  ];

  environment.systemPackages = [ pkgs.ratarmount ];
}
