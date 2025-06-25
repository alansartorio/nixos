{ ... }:
{
  virtualisation.docker.enable = true;
  virtualisation.libvirtd = {
    enable = true;
  };
  virtualisation.spiceUSBRedirection.enable = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [ "alan" ];
}
