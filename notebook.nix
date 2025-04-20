{ config, pkgs, ... }:
{
  boot.initrd.luks.devices."luks-97440c40-cde6-47b0-97ba-bb3ac82b6e3c".device =
    "/dev/disk/by-uuid/97440c40-cde6-47b0-97ba-bb3ac82b6e3c";
}
