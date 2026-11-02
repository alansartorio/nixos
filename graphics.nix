{
  config,
  lib,
  pkgs,
  ...
}:
let
  gpu = config.my.gpu;
in
{
  boot.initrd.kernelModules = lib.optionals (gpu == "amd") [ "amdgpu" ];
  systemd.tmpfiles.rules = lib.optionals (gpu == "amd") [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  hardware.graphics = {
    enable = true;
    extraPackages =
      with pkgs;
      lib.optionals (gpu == "intel") [
        intel-vaapi-driver
        intel-media-driver
      ];
  };
}
