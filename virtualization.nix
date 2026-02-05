{ pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    extraPackages = with pkgs; [ nftables ];
    extraOptions = "--firewall-backend=nftables";
  };
  virtualisation.libvirtd = {
    enable = true;
  };
  virtualisation.spiceUSBRedirection.enable = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [ "alan" ];
}
