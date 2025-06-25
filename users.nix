{
  pkgs,
  ...
}:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.alan = {
    isNormalUser = true;
    description = "Alan Sartorio";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "wireshark"
      "immich"
    ];
  };
  users.users.miri = {
    isNormalUser = true;
    createHome = false;
  };

  users.defaultUserShell = pkgs.zsh;
}
