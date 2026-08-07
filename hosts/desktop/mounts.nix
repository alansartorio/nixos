# Extra filesystems beyond the hardware scan.
#
# TODO: copy in the real entries from the old gitignored config/mounts.nix.
# services.nix expects /huge-storage to exist for the samba "miri" share.
{ ... }:
{
  # fileSystems."/huge-storage" = {
  #   device = "/dev/disk/by-label/HUGE";
  #   fsType = "ext4";
  # };
}
