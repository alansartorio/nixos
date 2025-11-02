{ pkgs, system-config, ... }:
let
  lib = pkgs.lib;
in
{

  boot.initrd.kernelModules = lib.optionals (system-config.options.gpu == "amd") [ "amdgpu" ];
  systemd.tmpfiles.rules = lib.optionals (system-config.options.gpu == "amd") [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  hardware.graphics = {
    enable = true;
    extraPackages =
      with pkgs;
      lib.optionals (system-config.options.gpu == "intel") [
        intel-vaapi-driver
        intel-media-driver
      ];
  };
}
