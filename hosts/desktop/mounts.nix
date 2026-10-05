# Extra filesystems beyond the hardware scan.
{ ... }:
{
  fileSystems."/huge-storage" = {
    device = "/dev/disk/by-label/Huge\\x20Storage";
    fsType = "ext4";
  };

  # Keep the bulky service state on the big disk instead of the root SSD.
  fileSystems."/var/lib/ollama" = {
    device = "/huge-storage/ollama/";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/var/lib/immich" = {
    device = "/huge-storage/Immich/";
    fsType = "none";
    options = [ "bind" ];
  };

  # The Steam library: an LVM volume (vg0/games) spanning the two 240G SSDs.
  # The VG/LV were made by hand and stay that way; LVM itself is on by default,
  # so the LV shows up as a device on every boot and all this has to do is
  # mount it. It used to be mounted on demand by udisks under
  # /run/media/alan/Games from the steam-gamescope session script, which left
  # it missing for Steam started any other way. A fixed path also means the
  # Steam library and every launcher config can point at it for good.
  #
  # nofail because the LV needs both disks: if either dies the volume can't
  # activate, and that should cost the games, not the boot. With nofail
  # nothing waits on it, so the default device timeout is left alone.
  # noatime because a game library is read constantly and nothing cares when.
  fileSystems."/games" = {
    device = "/dev/disk/by-uuid/812b6e5a-3193-4558-a18c-5052efb776aa";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
    ];
  };
}
