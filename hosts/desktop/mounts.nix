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

  fileSystems."/games" = {
    device = "/dev/disk/by-uuid/812b6e5a-3193-4558-a18c-5052efb776aa";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
    ];
  };
}
