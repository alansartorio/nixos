# ratarmount, patched to build with setuptools 83 (nixpkgs master since
# 2026-07-20, NixOS/nixpkgs#541843). Three packages in the chain break:
#
# - rapidgzip 0.16.0: its nasm compiler class still passes `dry_run`, which
#   setuptools 83 dropped from Compiler.__init__.
# - ratarmountcore 0.10.1 / ratarmount 1.2.2: pyproject.toml caps setuptools
#   below 83 and uses the pre-PEP 639 license table plus a license classifier,
#   both rejected by setuptools 83.
#
# The --replace-fail patches stop matching once upstream fixes them, which is
# the cue to delete this file.
{ pkgs, ... }:
let
  fixPyproject = ''
    substituteInPlace pyproject.toml \
      --replace-quiet '"setuptools >= 61, <= 82"' '"setuptools >= 77"' \
      --replace-quiet '"setuptools >= 61, < 83"' '"setuptools >= 77"' \
      --replace-fail 'license = {text = "MIT"}' 'license = "MIT"' \
      --replace-fail '"License :: OSI Approved :: MIT License",' ""
  '';
in
{
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyFinal: pyPrev: {
          rapidgzip = pyPrev.rapidgzip.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              substituteInPlace nasm_extension/nasmcompiler.py \
                --replace-fail "UnixCCompiler.__init__(self, verbose, dry_run, force)" \
                               "UnixCCompiler.__init__(self, verbose=verbose, force=force)"
            '';
          });
          ratarmountcore = pyPrev.ratarmountcore.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + fixPyproject;
          });
          ratarmount = pyPrev.ratarmount.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + fixPyproject;
          });
        })
      ];
    })
  ];

  environment.systemPackages = [ pkgs.ratarmount ];
}
